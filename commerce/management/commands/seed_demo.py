from django.contrib.auth.models import User
from django.core.management.base import BaseCommand

from commerce.models import Category, Product, ProductVariant
from core.models import ClientProfile


class Command(BaseCommand):
    help = 'Insere des donnees de demo AgroB2B'

    def handle(self, *args, **options):
        admin_user, created = User.objects.get_or_create(
            username='admin',
            defaults={'is_staff': True, 'is_superuser': True, 'first_name': 'Admin'},
        )
        if created:
            admin_user.set_password('admin123')
            admin_user.save()
            self.stdout.write(self.style.SUCCESS('Admin cree: admin / admin123'))
        else:
            self.stdout.write('Admin existe deja.')

        profile_user, created = User.objects.get_or_create(
            username='0550000000',
            defaults={'first_name': 'Superette Test'},
        )
        if created:
            profile_user.set_password('test1234')
            profile_user.save()
        profile, _ = ClientProfile.objects.get_or_create(
            user=profile_user,
            defaults={
                'phone': '0550000000',
                'is_validated': True,
                'business_name': 'Superette Test',
                'credit_limit': 150000,
            },
        )
        if not profile.is_validated:
            profile.is_validated = True
            profile.save(update_fields=['is_validated'])

        alimentaire, _ = Category.objects.get_or_create(name='Alimentaire', parent=None)
        huiles, _ = Category.objects.get_or_create(name='Huiles', parent=alimentaire)
        epicerie, _ = Category.objects.get_or_create(name='Epicerie', parent=alimentaire)
        conserve, _ = Category.objects.get_or_create(name='Conserve', parent=None)
        tomate, _ = Category.objects.get_or_create(name='Tomate', parent=conserve)

        huile, _ = Product.objects.get_or_create(
            name='Huile 5L',
            defaults={
                'category': huiles,
                'price': 2450,
                'stock': 120,
                'image_url': 'https://picsum.photos/seed/huile/400/300',
                'unit': 'carton',
                'is_promo': True,
            },
        )
        ProductVariant.objects.get_or_create(
            product=huile,
            label='Tournesol',
            defaults={'image_url': 'https://picsum.photos/seed/huilev/400/300'},
        )

        Product.objects.get_or_create(
            name='Sucre 1kg',
            defaults={
                'category': epicerie,
                'price': 130,
                'stock': 320,
                'image_url': 'https://picsum.photos/seed/sucre/400/300',
                'unit': 'piece',
                'is_promo': False,
            },
        )

        tomate_p, _ = Product.objects.get_or_create(
            name='Tomate concentree',
            defaults={
                'category': tomate,
                'price': 95,
                'stock': 560,
                'image_url': 'https://picsum.photos/seed/tomate/400/300',
                'unit': 'piece',
                'is_promo': False,
            },
        )
        ProductVariant.objects.get_or_create(
            product=tomate_p,
            label='70g',
            defaults={'image_url': 'https://picsum.photos/seed/tomatev/400/300'},
        )

        self.stdout.write(self.style.SUCCESS('Donnees de demo inserees.'))
