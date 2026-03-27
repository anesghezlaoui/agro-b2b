from django.contrib.auth import get_user_model
import os
import django

# Indiquer le settings
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

User = get_user_model()

# Créer le superuser seulement s'il n'existe pas
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@agro-b2b.com', 'admin123')
    print("Superuser créé ✅")
else:
    print("Superuser existe déjà ⚡")
