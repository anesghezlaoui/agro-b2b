from django.contrib import admin

from .models import ClientProfile


@admin.register(ClientProfile)
class ClientProfileAdmin(admin.ModelAdmin):
    list_display = ("id", "user", "phone", "is_validated", "business_name")
    list_filter = ("is_validated",)
    search_fields = ("phone", "business_name", "user__username")
