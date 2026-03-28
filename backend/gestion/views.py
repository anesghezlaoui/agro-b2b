from django.contrib import messages
from django.contrib.auth import login
from django.contrib.auth.models import User
from django.contrib.auth.views import LoginView, LogoutView
from django.db import transaction
from django.db.models import Q
from django.http import HttpResponseRedirect
from django.shortcuts import redirect, render
from django.urls import reverse, reverse_lazy
from django.views.generic import DeleteView, DetailView, ListView, TemplateView
from django.views.generic.edit import CreateView, FormView, UpdateView

from commerce.models import Category, Order, Product
from core.models import ClientProfile

from .forms import (
    CategoryForm,
    ClientProfileForm,
    ConditionnementFormSet,
    GestionAuthenticationForm,
    OrderStatusForm,
    ProductForm,
    ProductVariantFormSet,
    StaffUserCreationForm,
)
from .mixins import StaffRequiredMixin


def needs_setup() -> bool:
    return User.objects.count() == 0


class SetupView(FormView):
    """Premier compte administrateur (aucun User en base)."""

    template_name = "gestion/setup.html"
    form_class = StaffUserCreationForm

    def dispatch(self, request, *args, **kwargs):
        if not needs_setup():
            return redirect("gestion:login")
        return super().dispatch(request, *args, **kwargs)

    def form_valid(self, form):
        user = form.save(commit=False)
        user.is_staff = True
        user.is_superuser = True
        user.save()
        login(self.request, user)
        messages.success(self.request, "Compte administrateur créé. Bienvenue.")
        return HttpResponseRedirect(reverse("gestion:dashboard"))


class GestionLoginView(LoginView):
    template_name = "gestion/login.html"
    authentication_form = GestionAuthenticationForm
    redirect_authenticated_user = True

    def dispatch(self, request, *args, **kwargs):
        if needs_setup() and request.method == "POST":
            return redirect("gestion:setup")
        return super().dispatch(request, *args, **kwargs)

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx["needs_first_user"] = needs_setup()
        return ctx

    def form_valid(self, form):
        user = form.get_user()
        if not user.is_staff:
            messages.error(
                self.request,
                "Ce compte n’a pas accès à la console. Utilisez un compte staff.",
            )
            return self.form_invalid(form)
        return super().form_valid(form)


class GestionLogoutView(LogoutView):
    next_page = reverse_lazy("gestion:login")


class DashboardView(StaffRequiredMixin, TemplateView):
    template_name = "gestion/dashboard.html"

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx.update(
            {
                "total_products": Product.objects.count(),
                "total_categories": Category.objects.count(),
                "total_orders": Order.objects.count(),
                "total_clients": ClientProfile.objects.count(),
                "total_users": User.objects.count(),
                "recent_orders": Order.objects.select_related("client__user")[:8],
            }
        )
        return ctx


class CategoryListView(StaffRequiredMixin, ListView):
    model = Category
    template_name = "gestion/category_list.html"
    context_object_name = "categories"
    paginate_by = 30

    def get_queryset(self):
        qs = Category.objects.select_related("parent").order_by("name")
        q = (self.request.GET.get("q") or "").strip()
        if q:
            qs = qs.filter(name__icontains=q)
        return qs

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx["search_q"] = self.request.GET.get("q", "")
        return ctx


class CategoryCreateView(StaffRequiredMixin, CreateView):
    model = Category
    form_class = CategoryForm
    template_name = "gestion/category_form.html"

    def get_success_url(self):
        return reverse("gestion:category_list")

    def form_valid(self, form):
        messages.success(self.request, "Catégorie créée.")
        return super().form_valid(form)


class CategoryUpdateView(StaffRequiredMixin, UpdateView):
    model = Category
    form_class = CategoryForm
    template_name = "gestion/category_form.html"

    def get_success_url(self):
        return reverse("gestion:category_list")

    def form_valid(self, form):
        messages.success(self.request, "Catégorie enregistrée.")
        return super().form_valid(form)


class CategoryDeleteView(StaffRequiredMixin, DeleteView):
    model = Category
    template_name = "gestion/category_confirm_delete.html"
    success_url = reverse_lazy("gestion:category_list")

    def form_valid(self, form):
        messages.success(self.request, "Catégorie supprimée.")
        return super().form_valid(form)


class ProductListView(StaffRequiredMixin, ListView):
    model = Product
    template_name = "gestion/product_list.html"
    context_object_name = "products"
    paginate_by = 25

    def get_queryset(self):
        qs = Product.objects.select_related("category").order_by("name")
        q = (self.request.GET.get("q") or "").strip()
        cat = self.request.GET.get("category")
        if q:
            qs = qs.filter(Q(name__icontains=q) | Q(category__name__icontains=q))
        if cat:
            qs = qs.filter(category_id=cat)
        return qs

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx["search_q"] = self.request.GET.get("q", "")
        ctx["category_filter"] = self.request.GET.get("category", "")
        ctx["all_categories"] = Category.objects.order_by("name")
        return ctx


class ProductCreateView(StaffRequiredMixin, CreateView):
    model = Product
    form_class = ProductForm
    template_name = "gestion/product_form.html"

    def get_success_url(self):
        return reverse("gestion:product_list")

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        if "variant_formset" in kwargs:
            ctx["variant_formset"] = kwargs["variant_formset"]
        elif self.request.POST:
            ctx["variant_formset"] = ProductVariantFormSet(self.request.POST)
        else:
            ctx["variant_formset"] = ProductVariantFormSet()
        if "conditionnement_formset" in kwargs:
            ctx["conditionnement_formset"] = kwargs["conditionnement_formset"]
        elif self.request.POST:
            ctx["conditionnement_formset"] = ConditionnementFormSet(self.request.POST)
        else:
            ctx["conditionnement_formset"] = ConditionnementFormSet()
        return ctx

    def post(self, request, *args, **kwargs):
        # Requis par CreateView/SingleObjectMixin pour get_context_data().
        self.object = None
        form = self.get_form_class()(request.POST, request.FILES)
        if not form.is_valid():
            fs = ProductVariantFormSet(request.POST)
            cfs = ConditionnementFormSet(request.POST)
            return self.render_to_response(
                self.get_context_data(
                    form=form, variant_formset=fs, conditionnement_formset=cfs
                )
            )
        obj = form.save()
        formset = ProductVariantFormSet(request.POST, request.FILES, instance=obj)
        conditionnement_formset = ConditionnementFormSet(
            request.POST, request.FILES, instance=obj
        )
        if formset.is_valid() and conditionnement_formset.is_valid():
            formset.save()
            conditionnement_formset.save()
            messages.success(request, "Produit créé.")
            return HttpResponseRedirect(self.get_success_url())
        obj.delete()
        return self.render_to_response(
            self.get_context_data(
                form=form,
                variant_formset=formset,
                conditionnement_formset=conditionnement_formset,
            )
        )


class ProductUpdateView(StaffRequiredMixin, UpdateView):
    model = Product
    form_class = ProductForm
    template_name = "gestion/product_form.html"

    def get_success_url(self):
        return reverse("gestion:product_list")

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        if "conditionnement_formset" in kwargs:
            ctx["conditionnement_formset"] = kwargs["conditionnement_formset"]
        elif self.request.POST:
            ctx["conditionnement_formset"] = ConditionnementFormSet(
                self.request.POST,
                self.request.FILES,
                instance=self.object,
            )
        else:
            ctx["conditionnement_formset"] = ConditionnementFormSet(instance=self.object)
        if self.request.POST:
            ctx["variant_formset"] = ProductVariantFormSet(
                self.request.POST,
                self.request.FILES,
                instance=self.object,
            )
        else:
            ctx["variant_formset"] = ProductVariantFormSet(instance=self.object)
        return ctx

    def post(self, request, *args, **kwargs):
        self.object = self.get_object()
        form = self.get_form()
        formset = ProductVariantFormSet(
            request.POST, request.FILES, instance=self.object
        )
        conditionnement_formset = ConditionnementFormSet(
            request.POST, request.FILES, instance=self.object
        )
        if form.is_valid() and formset.is_valid() and conditionnement_formset.is_valid():
            with transaction.atomic():
                form.save()
                formset.save()
                conditionnement_formset.save()
            messages.success(request, "Produit enregistré.")
            return HttpResponseRedirect(self.get_success_url())
        return self.render_to_response(
            self.get_context_data(
                form=form,
                variant_formset=formset,
                conditionnement_formset=conditionnement_formset,
            )
        )


class ProductDeleteView(StaffRequiredMixin, DeleteView):
    model = Product
    template_name = "gestion/product_confirm_delete.html"
    success_url = reverse_lazy("gestion:product_list")

    def form_valid(self, form):
        messages.success(self.request, "Produit supprimé.")
        return super().form_valid(form)


class OrderListView(StaffRequiredMixin, ListView):
    model = Order
    template_name = "gestion/order_list.html"
    context_object_name = "orders"
    paginate_by = 30

    def get_queryset(self):
        qs = Order.objects.select_related("client__user").order_by("-created_at")
        st = self.request.GET.get("status")
        if st:
            qs = qs.filter(status=st)
        return qs

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx["status_filter"] = self.request.GET.get("status", "")
        ctx["status_choices"] = Order.STATUS_CHOICES
        return ctx


class OrderDetailView(StaffRequiredMixin, DetailView):
    model = Order
    template_name = "gestion/order_detail.html"
    context_object_name = "order"

    def get_queryset(self):
        return Order.objects.select_related("client__user").prefetch_related(
            "items__product"
        )

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx["status_form"] = OrderStatusForm(instance=self.object)
        return ctx

    def post(self, request, *args, **kwargs):
        self.object = self.get_object()
        form = OrderStatusForm(request.POST, instance=self.object)
        if form.is_valid():
            form.save()
            messages.success(request, "Commande mise à jour.")
            return redirect("gestion:order_detail", pk=self.object.pk)
        ctx = self.get_context_data(object=self.object)
        ctx["status_form"] = form
        return self.render_to_response(ctx)


class ClientListView(StaffRequiredMixin, ListView):
    model = ClientProfile
    template_name = "gestion/client_list.html"
    context_object_name = "clients"
    paginate_by = 30

    def get_queryset(self):
        qs = ClientProfile.objects.select_related("user").order_by("-id")
        q = (self.request.GET.get("q") or "").strip()
        if q:
            qs = qs.filter(
                Q(phone__icontains=q)
                | Q(business_name__icontains=q)
                | Q(user__username__icontains=q)
            )
        return qs

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx["search_q"] = self.request.GET.get("q", "")
        return ctx


class ClientUpdateView(StaffRequiredMixin, UpdateView):
    model = ClientProfile
    form_class = ClientProfileForm
    template_name = "gestion/client_form.html"

    def get_success_url(self):
        return reverse("gestion:client_list")

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx["readonly_phone"] = self.object.phone
        ctx["readonly_user"] = self.object.user.username
        return ctx

    def form_valid(self, form):
        messages.success(self.request, "Client enregistré.")
        return super().form_valid(form)


class StaffUserListView(StaffRequiredMixin, ListView):
    model = User
    template_name = "gestion/user_list.html"
    context_object_name = "users"
    paginate_by = 40

    def get_queryset(self):
        return User.objects.order_by("-date_joined")


class StaffUserCreateView(StaffRequiredMixin, CreateView):
    model = User
    form_class = StaffUserCreationForm
    template_name = "gestion/user_form.html"
    success_url = reverse_lazy("gestion:user_list")

    def dispatch(self, request, *args, **kwargs):
        if not request.user.is_superuser:
            messages.error(request, "Seuls les superutilisateurs peuvent créer des comptes.")
            return redirect("gestion:user_list")
        return super().dispatch(request, *args, **kwargs)

    def form_valid(self, form):
        messages.success(self.request, "Utilisateur créé.")
        return super().form_valid(form)
