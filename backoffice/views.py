from django.contrib import messages
from django.contrib.auth import authenticate, logout, views as auth_views
from django.contrib.auth.decorators import login_required, user_passes_test
from django.contrib.auth.models import User
from django.db.models import Q
from django.shortcuts import get_object_or_404, redirect, render
from django.urls import reverse_lazy
from django.utils import timezone

from commerce.models import Category, Order, Product, ProductVariant
from core.models import ClientProfile

from .forms import (
    CategoryForm,
    ClientProfileForm,
    FirstSuperuserForm,
    OrderStatusForm,
    ProductForm,
    ProductVariantForm,
    StaffAuthenticationForm,
)


def is_staff(user):
    return user.is_authenticated and user.is_staff


def needs_superuser_setup():
    return not User.objects.filter(is_superuser=True).exists()


def landing(request):
    return render(
        request,
        'backoffice/landing.html',
        {'needs_superuser': needs_superuser_setup()},
    )


def setup_superuser(request):
    """Premier lancement : créer un superutilisateur si aucun n'existe."""
    if not needs_superuser_setup():
        messages.info(request, 'Un superutilisateur existe déjà. Connectez-vous.')
        return redirect('backoffice:login')
    if request.method == 'POST':
        form = FirstSuperuserForm(request.POST)
        if form.is_valid() and needs_superuser_setup():
            User.objects.create_superuser(
                username=form.cleaned_data['username'],
                password=form.cleaned_data['password1'],
            )
            messages.success(
                request,
                'Superutilisateur créé. Connectez-vous avec ce compte pour accéder à la gestion.',
            )
            return redirect('backoffice:login')
    else:
        form = FirstSuperuserForm()
    return render(request, 'backoffice/setup_superuser.html', {'form': form})


@login_required
@user_passes_test(is_staff)
def dashboard(request):
    today = timezone.localdate()
    stats = {
        'clients_total': ClientProfile.objects.count(),
        'clients_pending': ClientProfile.objects.filter(is_validated=False).count(),
        'orders_today': Order.objects.filter(created_at__date=today).count(),
        'orders_pending': Order.objects.filter(status='pending').count(),
        'products_count': Product.objects.count(),
        'categories_count': Category.objects.count(),
    }
    recent_orders = Order.objects.select_related('client__user').order_by('-created_at')[:8]
    return render(
        request,
        'backoffice/dashboard.html',
        {'stats': stats, 'recent_orders': recent_orders},
    )


@login_required
@user_passes_test(is_staff)
def client_list(request):
    q = request.GET.get('q', '').strip()
    qs = ClientProfile.objects.select_related('user').order_by('-id')
    if q:
        qs = qs.filter(
            Q(phone__icontains=q)
            | Q(business_name__icontains=q)
            | Q(user__first_name__icontains=q)
        )
    return render(request, 'backoffice/client_list.html', {'clients': qs, 'q': q})


@login_required
@user_passes_test(is_staff)
def client_detail(request, pk):
    profile = get_object_or_404(ClientProfile.objects.select_related('user'), pk=pk)
    if request.method == 'POST':
        form = ClientProfileForm(request.POST, instance=profile)
        if form.is_valid():
            form.save()
            messages.success(request, 'Client mis à jour.')
            return redirect('backoffice:client_detail', pk=pk)
    else:
        form = ClientProfileForm(instance=profile)
    orders = profile.orders.select_related().prefetch_related('items__product')[:20]
    return render(
        request,
        'backoffice/client_detail.html',
        {'profile': profile, 'form': form, 'orders': orders},
    )


@login_required
@user_passes_test(is_staff)
def order_list(request):
    status = request.GET.get('status', '')
    qs = Order.objects.select_related('client__user').order_by('-created_at')
    if status in dict(Order.STATUS_CHOICES):
        qs = qs.filter(status=status)
    return render(
        request,
        'backoffice/order_list.html',
        {
            'orders': qs[:200],
            'status_filter': status,
            'status_choices': Order.STATUS_CHOICES,
        },
    )


@login_required
@user_passes_test(is_staff)
def order_detail(request, pk):
    order = get_object_or_404(
        Order.objects.select_related('client__user').prefetch_related('items__product'),
        pk=pk,
    )
    if request.method == 'POST':
        form = OrderStatusForm(request.POST, instance=order)
        if form.is_valid():
            form.save()
            messages.success(request, 'Commande / livraison mise à jour.')
            return redirect('backoffice:order_detail', pk=pk)
    else:
        form = OrderStatusForm(instance=order)
    return render(
        request,
        'backoffice/order_detail.html',
        {'order': order, 'form': form},
    )


@login_required
@user_passes_test(is_staff)
def product_list(request):
    q = request.GET.get('q', '').strip()
    qs = Product.objects.select_related('category').order_by('name')
    if q:
        qs = qs.filter(name__icontains=q)
    return render(request, 'backoffice/product_list.html', {'products': qs, 'q': q})


@login_required
@user_passes_test(is_staff)
def product_create(request):
    if request.method == 'POST':
        form = ProductForm(request.POST)
        if form.is_valid():
            form.save()
            messages.success(request, 'Produit créé.')
            return redirect('backoffice:product_list')
    else:
        form = ProductForm()
    return render(request, 'backoffice/product_form.html', {'form': form, 'title': 'Nouveau produit'})


@login_required
@user_passes_test(is_staff)
def product_edit(request, pk):
    product = get_object_or_404(Product, pk=pk)
    if request.method == 'POST':
        form = ProductForm(request.POST, instance=product)
        if form.is_valid():
            form.save()
            messages.success(request, 'Produit enregistré.')
            return redirect('backoffice:product_list')
    else:
        form = ProductForm(instance=product)
    return render(
        request,
        'backoffice/product_form.html',
        {'form': form, 'title': f'Modifier : {product.name}', 'product': product},
    )


@login_required
@user_passes_test(is_staff)
def product_delete(request, pk):
    product = get_object_or_404(Product, pk=pk)
    if request.method == 'POST':
        product.delete()
        messages.success(request, 'Produit supprimé.')
        return redirect('backoffice:product_list')
    return render(
        request,
        'backoffice/product_confirm_delete.html',
        {'product': product},
    )


@login_required
@user_passes_test(is_staff)
def variant_list(request):
    q = request.GET.get('q', '').strip()
    product_id = request.GET.get('product', '').strip()
    product_filter_id = int(product_id) if product_id.isdigit() else None
    qs = ProductVariant.objects.select_related('product').order_by(
        'product__name', 'label'
    )
    if product_filter_id is not None:
        qs = qs.filter(product_id=product_filter_id)
    if q:
        qs = qs.filter(
            Q(label__icontains=q) | Q(product__name__icontains=q)
        )
    products = Product.objects.order_by('name')
    return render(
        request,
        'backoffice/variant_list.html',
        {
            'variants': qs[:500],
            'q': q,
            'product_filter_id': product_filter_id,
            'products': products,
        },
    )


@login_required
@user_passes_test(is_staff)
def product_variant_list(request, product_pk):
    product = get_object_or_404(Product, pk=product_pk)
    variants = product.variants.order_by('label')
    return render(
        request,
        'backoffice/product_variant_list.html',
        {'product': product, 'variants': variants},
    )


@login_required
@user_passes_test(is_staff)
def variant_create(request, product_pk):
    product = get_object_or_404(Product, pk=product_pk)
    if request.method == 'POST':
        form = ProductVariantForm(request.POST)
        if form.is_valid():
            v = form.save(commit=False)
            v.product = product
            v.save()
            messages.success(request, 'Variante créée.')
            return redirect('backoffice:product_variant_list', product_pk=product_pk)
    else:
        form = ProductVariantForm()
    return render(
        request,
        'backoffice/variant_form.html',
        {
            'form': form,
            'title': f'Nouvelle variante — {product.name}',
            'product': product,
        },
    )


@login_required
@user_passes_test(is_staff)
def variant_edit(request, product_pk, pk):
    product = get_object_or_404(Product, pk=product_pk)
    variant = get_object_or_404(ProductVariant, pk=pk, product=product)
    if request.method == 'POST':
        form = ProductVariantForm(request.POST, instance=variant)
        if form.is_valid():
            form.save()
            messages.success(request, 'Variante enregistrée.')
            return redirect('backoffice:product_variant_list', product_pk=product_pk)
    else:
        form = ProductVariantForm(instance=variant)
    return render(
        request,
        'backoffice/variant_form.html',
        {
            'form': form,
            'title': f'Modifier variante — {product.name}',
            'product': product,
            'variant': variant,
        },
    )


@login_required
@user_passes_test(is_staff)
def variant_delete(request, product_pk, pk):
    product = get_object_or_404(Product, pk=product_pk)
    variant = get_object_or_404(ProductVariant, pk=pk, product=product)
    if request.method == 'POST':
        variant.delete()
        messages.success(request, 'Variante supprimée.')
        return redirect('backoffice:product_variant_list', product_pk=product_pk)
    return render(
        request,
        'backoffice/variant_confirm_delete.html',
        {'product': product, 'variant': variant},
    )


@login_required
@user_passes_test(is_staff)
def category_list(request):
    categories = Category.objects.select_related('parent').order_by('name')
    return render(request, 'backoffice/category_list.html', {'categories': categories})


@login_required
@user_passes_test(is_staff)
def category_create(request):
    if request.method == 'POST':
        form = CategoryForm(request.POST)
        if form.is_valid():
            form.save()
            messages.success(request, 'Catégorie créée.')
            return redirect('backoffice:category_list')
    else:
        form = CategoryForm()
    return render(request, 'backoffice/category_form.html', {'form': form, 'title': 'Nouvelle catégorie'})


@login_required
@user_passes_test(is_staff)
def category_edit(request, pk):
    category = get_object_or_404(Category, pk=pk)
    if request.method == 'POST':
        form = CategoryForm(request.POST, instance=category)
        if form.is_valid():
            inst = form.save(commit=False)
            if inst.parent_id == inst.pk:
                messages.error(request, 'Une catégorie ne peut pas être son propre parent.')
            else:
                inst.save()
                messages.success(request, 'Catégorie enregistrée.')
                return redirect('backoffice:category_list')
    else:
        form = CategoryForm(instance=category)
    return render(
        request,
        'backoffice/category_form.html',
        {'form': form, 'title': f'Modifier : {category.name}', 'category': category},
    )


@login_required
@user_passes_test(is_staff)
def category_delete(request, pk):
    category = get_object_or_404(Category, pk=pk)
    if request.method == 'POST':
        category.delete()
        messages.success(request, 'Catégorie supprimée.')
        return redirect('backoffice:category_list')
    return render(
        request,
        'backoffice/category_confirm_delete.html',
        {'category': category},
    )


class StaffLoginView(auth_views.LoginView):
    template_name = 'backoffice/login.html'
    authentication_form = StaffAuthenticationForm
    redirect_authenticated_user = True

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx['needs_superuser'] = needs_superuser_setup()
        return ctx

    def form_valid(self, form):
        user = authenticate(
            self.request,
            username=form.cleaned_data.get('username'),
            password=form.cleaned_data.get('password'),
        )
        if user is not None and not user.is_staff:
            messages.error(
                self.request,
                'Accès réservé au personnel grossiste (compte administrateur / staff).',
            )
            return redirect('backoffice:login')
        return super().form_valid(form)

    def get_success_url(self):
        return reverse_lazy('backoffice:dashboard')


def staff_logout(request):
    """Déconnexion via lien GET (pratique dans la barre latérale)."""
    logout(request)
    return redirect('backoffice:login')
