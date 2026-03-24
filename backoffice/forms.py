from django import forms
from django.contrib.auth.forms import AuthenticationForm
from django.contrib.auth.models import User
from django.core.exceptions import ValidationError

from commerce.models import Category, Order, Product, ProductVariant
from core.models import ClientProfile


class StaffAuthenticationForm(AuthenticationForm):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['username'].widget.attrs.update(
            {'class': 'bo-input', 'placeholder': 'admin ou identifiant', 'autocomplete': 'username'}
        )
        self.fields['password'].widget.attrs.update(
            {'class': 'bo-input', 'placeholder': 'Mot de passe', 'autocomplete': 'current-password'}
        )


class CategoryForm(forms.ModelForm):
    class Meta:
        model = Category
        fields = ['name', 'parent']
        labels = {
            'name': 'Nom',
            'parent': 'Catégorie parente',
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['parent'].required = False
        self.fields['parent'].empty_label = '— Aucune (racine) —'


class FirstSuperuserForm(forms.Form):
    """Création du premier compte superutilisateur (base vide)."""

    username = forms.CharField(
        max_length=150,
        label="Nom d'utilisateur",
        widget=forms.TextInput(attrs={'class': 'bo-input', 'autocomplete': 'username'}),
    )
    password1 = forms.CharField(
        label='Mot de passe',
        min_length=8,
        widget=forms.PasswordInput(attrs={'class': 'bo-input', 'autocomplete': 'new-password'}),
    )
    password2 = forms.CharField(
        label='Confirmer le mot de passe',
        widget=forms.PasswordInput(attrs={'class': 'bo-input', 'autocomplete': 'new-password'}),
    )

    def clean_username(self):
        username = self.cleaned_data['username'].strip()
        if User.objects.filter(username__iexact=username).exists():
            raise ValidationError('Ce nom est déjà utilisé.')
        return username

    def clean(self):
        data = super().clean()
        if User.objects.filter(is_superuser=True).exists():
            raise ValidationError('Un superutilisateur existe déjà.')
        p1, p2 = data.get('password1'), data.get('password2')
        if p1 and p2 and p1 != p2:
            self.add_error('password2', 'Les mots de passe ne correspondent pas.')
        return data


class ProductVariantForm(forms.ModelForm):
    class Meta:
        model = ProductVariant
        fields = ['label', 'image_url']
        labels = {
            'label': 'Libellé (ex. 70g, Tournesol)',
            'image_url': 'URL image (optionnel)',
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['image_url'].required = False


class ProductForm(forms.ModelForm):
    class Meta:
        model = Product
        fields = [
            'name',
            'category',
            'price',
            'stock',
            'image_url',
            'unit',
            'is_promo',
        ]
        labels = {
            'name': 'Nom',
            'category': 'Catégorie',
            'price': 'Prix (DA)',
            'stock': 'Stock',
            'image_url': 'URL image',
            'unit': 'Unité',
            'is_promo': 'En promotion',
        }


class ClientProfileForm(forms.ModelForm):
    class Meta:
        model = ClientProfile
        fields = [
            'business_name',
            'is_validated',
            'credit_limit',
            'current_debt',
        ]
        labels = {
            'business_name': 'Nom commerce',
            'is_validated': 'Compte validé',
            'credit_limit': 'Plafond crédit (DA)',
            'current_debt': 'Dette actuelle (DA)',
        }


class OrderStatusForm(forms.ModelForm):
    class Meta:
        model = Order
        fields = ['status', 'delivery_type']
        labels = {
            'status': 'Statut',
            'delivery_type': 'Mode de réception',
        }
