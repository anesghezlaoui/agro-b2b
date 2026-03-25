from drf_spectacular.utils import OpenApiResponse, extend_schema, inline_serializer
from rest_framework import permissions, status
from rest_framework.generics import get_object_or_404
from django.shortcuts import render
from django.shortcuts import redirect
from rest_framework.response import Response
from rest_framework import serializers
from rest_framework.views import APIView

from django.contrib.auth import login
from django.contrib.auth.models import User

from .models import ClientProfile
from .serializers import LoginSerializer, RegisterSerializer

from commerce.models import Category, Order, Product


class RegisterView(APIView):
    permission_classes = [permissions.AllowAny]

    @extend_schema(
        request=RegisterSerializer,
        responses={
            201: inline_serializer(
                name="RegisterResponse",
                fields={
                    "token": serializers.CharField(),
                    "name": serializers.CharField(),
                    "phone": serializers.CharField(),
                    "is_validated": serializers.BooleanField(),
                },
            )
        },
    )
    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user, profile, token = serializer.save()
        return Response(
            {
                "token": token.key,
                "name": user.first_name,
                "phone": profile.phone,
                "is_validated": profile.is_validated,
            },
            status=status.HTTP_201_CREATED,
        )


class LoginView(APIView):
    permission_classes = [permissions.AllowAny]

    @extend_schema(
        request=LoginSerializer,
        responses={
            200: inline_serializer(
                name="LoginResponse",
                fields={
                    "token": serializers.CharField(),
                    "name": serializers.CharField(),
                    "phone": serializers.CharField(),
                    "is_validated": serializers.BooleanField(),
                },
            )
        },
    )
    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.validated_data["user"]
        profile = serializer.validated_data["profile"]
        token = serializer.validated_data["token"]
        return Response(
            {
                "token": token.key,
                "name": user.first_name or profile.business_name or "Client",
                "phone": profile.phone,
                "is_validated": profile.is_validated,
            }
        )


class ValidateClientView(APIView):
    permission_classes = [permissions.IsAdminUser]

    @extend_schema(
        request=None,
        responses={
            200: inline_serializer(
                name="ValidateClientResponse",
                fields={"id": serializers.IntegerField(), "is_validated": serializers.BooleanField()},
            ),
            404: OpenApiResponse(description="Client introuvable"),
        },
    )
    def post(self, request, profile_id):
        profile = get_object_or_404(ClientProfile, pk=profile_id)
        profile.is_validated = True
        profile.save(update_fields=["is_validated"])
        return Response(
            {"id": profile.id, "is_validated": profile.is_validated},
        )


def admin_home(request):
    # 1) S’il n’y a aucun utilisateur dans la DB, on propose l’ajout du premier superuser.
    user_count = User.objects.count()
    needs_superuser_setup = user_count == 0

    # 2) Si l’utilisateur est déjà connecté et staff => afficher la gestion.
    is_staff = bool(request.user and request.user.is_authenticated and request.user.is_staff)

    # POST: création du 1er superuser
    if request.method == "POST" and needs_superuser_setup:
        username = (request.POST.get("username") or "").strip()
        password1 = request.POST.get("password1") or ""
        password2 = request.POST.get("password2") or ""

        context = {"needs_superuser_setup": True, "is_staff": False, "error": None}

        if not username:
            context["error"] = "Le nom d’utilisateur est requis."
            return render(request, "core/admin_home.html", context)

        if not password1 or len(password1) < 8:
            context["error"] = "Le mot de passe doit contenir au moins 8 caractères."
            return render(request, "core/admin_home.html", context)

        if password1 != password2:
            context["error"] = "Les deux mots de passe ne correspondent pas."
            return render(request, "core/admin_home.html", context)

        # Création du premier superutilisateur
        created = User.objects.create_user(
            username=username,
            password=password1,
            is_staff=True,
            is_superuser=True,
        )
        login(request, created)
        return redirect("admin-home")

    # GET: si aucun utilisateur => afficher le formulaire de création
    if needs_superuser_setup:
        return render(
            request,
            "core/admin_home.html",
            {
                "needs_superuser_setup": True,
                "is_staff": False,
                "existing_user_count": 0,
            },
        )

    # Si des users existent mais tu n’es pas staff => ne rien afficher (rediriger login admin)
    if not is_staff:
        return redirect("/admin/login/?next=/")

    # Affichage dashboard admin
    total_products = Product.objects.count()
    total_categories = Category.objects.count()
    total_orders = Order.objects.count()
    total_clients = ClientProfile.objects.count()
    total_users = User.objects.count()

    return render(
        request,
        "core/admin_home.html",
        {
            "needs_superuser_setup": False,
            "is_staff": True,
            "existing_user_count": total_users,
            "total_products": total_products,
            "total_categories": total_categories,
            "total_clients": total_clients,
            "total_orders": total_orders,
        },
    )
