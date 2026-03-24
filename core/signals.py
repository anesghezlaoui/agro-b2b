from django.contrib.auth.models import User
from django.db.models.signals import post_save
from django.dispatch import receiver
from rest_framework.authtoken.models import Token

@receiver(post_save, sender=User)
def create_token_for_user(sender, instance, created, **kwargs):
    if created:
        Token.objects.get_or_create(user=instance)
