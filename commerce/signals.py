from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver

from .models import Notification, Order


@receiver(post_save, sender=Order)
def create_order_created_notification(sender, instance, created, **kwargs):
    if created:
        Notification.objects.create(
            client=instance.client,
            order=instance,
            title='Commande acceptee',
            message=f'Votre commande #{instance.id} est en attente de preparation.',
        )


@receiver(pre_save, sender=Order)
def notify_status_change(sender, instance, **kwargs):
    if not instance.pk:
        return
    previous = Order.objects.filter(pk=instance.pk).values('status').first()
    if not previous:
        return
    old_status = previous['status']
    if old_status == instance.status:
        return

    status_messages = {
        'preparing': 'Votre commande est en preparation.',
        'delivering': 'Votre commande est en route.',
        'delivered': 'Votre commande a ete livree.',
    }
    message = status_messages.get(instance.status)
    if message:
        Notification.objects.create(
            client=instance.client,
            order=instance,
            title='Mise a jour commande',
            message=f'Commande #{instance.id}: {message}',
        )
