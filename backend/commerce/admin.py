from django.contrib import admin
from django.utils.html import format_html
from django.utils.safestring import mark_safe

from .models import (
    Category,
    Conditionnement,
    Order,
    OrderItem,
    Product,
    ProductVariant,
)


def _empty_preview_html(message: str):
    """format_html() exige au moins un argument depuis Django 6 — HTML statique via mark_safe."""
    return mark_safe(
        f'<div class="commerce-admin-preview-wrap"><p class="help">{message}</p></div>'
    )


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    change_form_template = "admin/commerce/category/change_form.html"
    list_display = (
        "id",
        "name",
        "parent",
        "show_image",
        "show_icon",
        "image_thumb",
        "icon_thumb",
    )
    list_select_related = ("parent",)
    search_fields = ("name",)
    readonly_fields = ("image_preview", "icon_preview")
    fieldsets = (
        (None, {"fields": ("name", "parent", "show_image", "show_icon")}),
        (
            "Visuels application mobile",
            {
                "classes": ("wide", "commerce-media-fieldset"),
                "description": "Image de carte / bannière et pictogramme affichés dans l’app Flutter "
                "(via l’API). Cochez « Effacer » sur le fichier pour le supprimer.",
                "fields": ("image_preview", "image", "icon_preview", "icon"),
            },
        ),
    )

    @admin.display(description="Bannière")
    def image_thumb(self, obj):
        if obj.image:
            return format_html(
                '<img src="{}" class="commerce-admin-preview" style="max-height:40px;width:auto;" alt="" />',
                obj.image.url,
            )
        return "—"

    @admin.display(description="Icône")
    def icon_thumb(self, obj):
        if obj.icon:
            return format_html(
                '<img src="{}" class="commerce-admin-preview" style="max-height:32px;width:auto;" alt="" />',
                obj.icon.url,
            )
        return "—"

    @admin.display(description="Aperçu bannière")
    def image_preview(self, obj):
        if obj and getattr(obj, "image", None) and obj.image.name:
            return format_html(
                '<div class="commerce-admin-preview-wrap">'
                '<img src="{}" class="commerce-admin-preview" alt="Bannière catégorie" />'
                "<p class='help'>Remplacez le fichier ci-dessous ou cochez « Effacer » pour retirer.</p>"
                "</div>",
                obj.image.url,
            )
        return _empty_preview_html(
            "Aucune image — téléversez un fichier (JPG, PNG, WebP)."
        )

    @admin.display(description="Aperçu icône")
    def icon_preview(self, obj):
        if obj and getattr(obj, "icon", None) and obj.icon.name:
            return format_html(
                '<div class="commerce-admin-preview-wrap">'
                '<img src="{}" class="commerce-admin-preview commerce-admin-preview--icon" alt="Icône" />'
                "<p class='help'>PNG avec fond transparent recommandé (environ 128×128 px).</p>"
                "</div>",
                obj.icon.url,
            )
        return _empty_preview_html(
            "Aucune icône — optionnel ; sinon l’app utilise une icône par défaut."
        )


class ProductVariantInline(admin.TabularInline):
    model = ProductVariant
    extra = 1


class ConditionnementInline(admin.TabularInline):
    model = Conditionnement
    extra = 1
    fields = (
        "type",
        "unite_par_conditionnement",
        "prix",
        "stock",
        "ordre",
        "is_default",
        "is_active",
        "emplacement",
    )


@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    change_form_template = "admin/commerce/product/change_form.html"
    list_display = (
        "id",
        "name",
        "thumb",
        "category",
        "price",
        "stock",
        "unit",
        "is_promo",
        "is_top_seller",
        "is_new",
        "show_conditionnement",
    )
    list_filter = (
        "unit",
        "show_conditionnement",
        "is_promo",
        "is_top_seller",
        "is_new",
        "category",
    )
    search_fields = ("name",)
    readonly_fields = ("image_preview",)
    inlines = [ConditionnementInline, ProductVariantInline]
    fieldsets = (
        (None, {"fields": ("name", "category", "price", "stock", "unit")}),
        (
            "Image produit",
            {
                "classes": ("wide", "commerce-media-fieldset"),
                "description": "Téléversez un fichier ou indiquez une URL externe. "
                "Le fichier téléversé est prioritaire pour l’API et l’app.",
                "fields": ("image_preview", "image", "image_url"),
            },
        ),
        (
            "Mise en avant",
            {"fields": ("is_promo", "is_top_seller", "is_new", "show_conditionnement")},
        ),
    )

    @admin.display(description="Vignette")
    def thumb(self, obj):
        if obj.image:
            return format_html(
                '<img src="{}" style="width:44px;height:44px;object-fit:cover;border-radius:8px;" alt="" />',
                obj.image.url,
            )
        if obj.image_url:
            return format_html(
                '<img src="{}" style="width:44px;height:44px;object-fit:cover;border-radius:8px;" alt="" />',
                obj.image_url,
            )
        return "—"

    @admin.display(description="Aperçu image")
    def image_preview(self, obj):
        if obj and getattr(obj, "image", None) and obj.image.name:
            return format_html(
                '<div class="commerce-admin-preview-wrap">'
                '<img src="{}" class="commerce-admin-preview" alt="Image produit" />'
                "<p class='help'>Remplacez ou effacez le fichier ; sinon complétez l’URL externe.</p>"
                "</div>",
                obj.image.url,
            )
        if obj and obj.image_url:
            return format_html(
                '<div class="commerce-admin-preview-wrap">'
                '<img src="{}" class="commerce-admin-preview" alt="Image (URL)" />'
                "<p class='help'>Image actuelle via URL externe. "
                "Un fichier téléversé remplacera cette source pour l’API.</p>"
                "</div>",
                obj.image_url,
            )
        return _empty_preview_html(
            "Téléversez une image ou saisissez une URL ci-dessous."
        )


class OrderItemInline(admin.TabularInline):
    model = OrderItem
    extra = 0
    readonly_fields = ("product", "quantity", "unit_price")


@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = ("id", "client", "status", "delivery_type", "total", "created_at")
    list_filter = ("status", "delivery_type")
    search_fields = ("client__phone", "client__user__username")
    inlines = [OrderItemInline]
