from drf_spectacular.utils import OpenApiResponse, extend_schema, inline_serializer
from rest_framework import permissions, status
from rest_framework.generics import get_object_or_404
from rest_framework.response import Response
from rest_framework import serializers
from rest_framework.views import APIView

from .models import ClientProfile
from .serializers import LoginSerializer, RegisterSerializer


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


class ClientSessionView(APIView):
    """État du compte connecté (token) — pour actualiser is_validated après validation admin."""

    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        responses={
            200: inline_serializer(
                name="ClientSessionResponse",
                fields={
                    "name": serializers.CharField(),
                    "phone": serializers.CharField(),
                    "is_validated": serializers.BooleanField(),
                },
            )
        }
    )
    def get(self, request):
        try:
            profile = request.user.client_profile
        except ClientProfile.DoesNotExist:
            return Response(
                {"detail": "Profil client introuvable."},
                status=status.HTTP_404_NOT_FOUND,
            )
        return Response(
            {
                "name": request.user.first_name
                or profile.business_name
                or "Client",
                "phone": profile.phone,
                "is_validated": profile.is_validated,
            }
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
