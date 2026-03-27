from django import forms
from django.contrib.auth.forms import AuthenticationForm, UserCreationForm
from django.contrib.auth.models import User
from django.forms import inlineformset_factory

from commerce.models import Category, Conditionnement, Order, Product, ProductVariant
from core.models import ClientProfile


class GestionAuthenticationForm(AuthenticationForm):
    username = forms.CharField(
        label="Identifiant",
        widget=forms.TextInput(attrs={"class": "gestion-input", "autocomplete": "username"}),
    )
    password = forms.CharField(
        label="Mot de passe",
        strip=False,
        widget=forms.PasswordInput(attrs={"class": "gestion-input", "autocomplete": "current-password"}),
    )


class CategoryForm(forms.ModelForm):
    class Meta:
        model = Category
        fields = ("name", "parent", "image", "icon", "show_image", "show_icon")
        widgets = {
            "name": forms.TextInput(attrs={"class": "gestion-input"}),
            "parent": forms.Select(attrs={"class": "gestion-select"}),
            "image": forms.ClearableFileInput(attrs={"class": "gestion-file"}),
            "icon": forms.ClearableFileInput(attrs={"class": "gestion-file"}),
            "show_image": forms.CheckboxInput(attrs={"class": "gestion-check"}),
            "show_icon": forms.CheckboxInput(attrs={"class": "gestion-check"}),
        }


class ProductForm(forms.ModelForm):
    class Meta:
        model = Product
        fields = (
            "name",
            "category",
            "price",
            "stock",
            "image",
            "image_url",
            "unit",
            "show_conditionnement",
            "is_promo",
            "is_top_seller",
            "is_new",
        )
        widgets = {
            "name": forms.TextInput(attrs={"class": "gestion-input"}),
            "category": forms.Select(attrs={"class": "gestion-select"}),
            "price": forms.NumberInput(attrs={"class": "gestion-input", "step": "0.01"}),
            "stock": forms.NumberInput(attrs={"class": "gestion-input"}),
            "image": forms.ClearableFileInput(attrs={"class": "gestion-file"}),
            "image_url": forms.URLInput(attrs={"class": "gestion-input"}),
            "unit": forms.Select(attrs={"class": "gestion-select"}),
            "show_conditionnement": forms.CheckboxInput(attrs={"class": "gestion-check"}),
            "is_promo": forms.CheckboxInput(attrs={"class": "gestion-check"}),
            "is_top_seller": forms.CheckboxInput(attrs={"class": "gestion-check"}),
            "is_new": forms.CheckboxInput(attrs={"class": "gestion-check"}),
        }


ProductVariantFormSet = inlineformset_factory(
    Product,
    ProductVariant,
    fields=("label", "image_url"),
    extra=1,
    can_delete=True,
    widgets={
        "label": forms.TextInput(attrs={"class": "gestion-input gestion-input--sm"}),
        "image_url": forms.URLInput(attrs={"class": "gestion-input gestion-input--sm"}),
    },
)


ConditionnementFormSet = inlineformset_factory(
    Product,
    Conditionnement,
    fields=(
        "type",
        "unite_par_conditionnement",
        "prix",
        "stock",
        "ordre",
        "is_default",
        "is_active",
        "emplacement",
    ),
    extra=1,
    can_delete=True,
    widgets={
        "type": forms.TextInput(attrs={"class": "gestion-input gestion-input--sm"}),
        "unite_par_conditionnement": forms.NumberInput(
            attrs={"class": "gestion-input gestion-input--sm", "min": "1"}
        ),
        "prix": forms.NumberInput(
            attrs={"class": "gestion-input gestion-input--sm", "step": "0.01"}
        ),
        "stock": forms.NumberInput(attrs={"class": "gestion-input gestion-input--sm", "min": "0"}),
        "ordre": forms.NumberInput(attrs={"class": "gestion-input gestion-input--sm", "min": "0"}),
        "is_default": forms.CheckboxInput(attrs={"class": "gestion-check"}),
        "is_active": forms.CheckboxInput(attrs={"class": "gestion-check"}),
        "emplacement": forms.TextInput(attrs={"class": "gestion-input gestion-input--sm"}),
    },
)


class OrderStatusForm(forms.ModelForm):
    class Meta:
        model = Order
        fields = ("status", "delivery_type")
        widgets = {
            "status": forms.Select(attrs={"class": "gestion-select"}),
            "delivery_type": forms.Select(attrs={"class": "gestion-select"}),
        }


class ClientProfileForm(forms.ModelForm):
    class Meta:
        model = ClientProfile
        fields = (
            "business_name",
            "is_validated",
            "credit_limit",
            "current_debt",
        )
        widgets = {
            "business_name": forms.TextInput(attrs={"class": "gestion-input"}),
            "is_validated": forms.CheckboxInput(attrs={"class": "gestion-check"}),
            "credit_limit": forms.NumberInput(attrs={"class": "gestion-input", "step": "0.01"}),
            "current_debt": forms.NumberInput(attrs={"class": "gestion-input", "step": "0.01"}),
        }


class StaffUserCreationForm(UserCreationForm):
    is_staff = forms.BooleanField(
        label="Accès console (staff)",
        required=False,
        initial=True,
        widget=forms.CheckboxInput(attrs={"class": "gestion-check"}),
    )

    class Meta(UserCreationForm.Meta):
        model = User

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        for name in ("username", "password1", "password2"):
            if name in self.fields:
                self.fields[name].widget.attrs["class"] = "gestion-input"

    def save(self, commit=True):
        user = super().save(commit=False)
        user.is_staff = self.cleaned_data.get("is_staff", False)
        if commit:
            user.save()
        return user
