from django.contrib import admin

from .models import Category, Order, OrderItem, Product, ProductVariant


class ProductVariantInline(admin.TabularInline):
    model = ProductVariant
    extra = 1


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'parent')
    search_fields = ('name',)


@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'category', 'price', 'stock', 'unit', 'is_promo')
    list_filter = ('unit', 'is_promo', 'category')
    search_fields = ('name',)
    inlines = [ProductVariantInline]


class OrderItemInline(admin.TabularInline):
    model = OrderItem
    extra = 0
    readonly_fields = ('product', 'quantity', 'unit_price')


@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = ('id', 'client', 'status', 'delivery_type', 'total', 'created_at')
    list_filter = ('status', 'delivery_type')
    search_fields = ('client__phone', 'client__user__username')
    inlines = [OrderItemInline]
