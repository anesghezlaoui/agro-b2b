from django.contrib.auth.models import User
from django.db import models


class ClientProfile(models.Model):
    user = models.OneToOneField(
        User, on_delete=models.CASCADE, related_name="client_profile"
    )
    phone = models.CharField(max_length=10, unique=True)
    is_validated = models.BooleanField(default=False)
    credit_limit = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    current_debt = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    business_name = models.CharField(max_length=120, blank=True)

    def __str__(self) -> str:
        return f"{self.user.username} ({self.phone})"
