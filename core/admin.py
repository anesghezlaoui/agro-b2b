from django.contrib import admin

from .models import ClientProfile


@admin.register(ClientProfile)
class ClientProfileAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'phone', 'is_validated', 'credit_limit', 'current_debt')
    list_filter = ('is_validated',)
    search_fields = ('phone', 'user__username', 'business_name')
