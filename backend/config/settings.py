import os
from pathlib import Path
import dj_database_url

# -------------------------
# BASE DIR
# -------------------------
BASE_DIR = Path(__file__).resolve().parent.parent.parent

# -------------------------
# SECURITY
# -------------------------
SECRET_KEY = os.environ.get(
    "SECRET_KEY",
    "^v@3qqm*fc4cyd^=2fr4dtjl==l)zhj*-4u1qli2$+6ov4l=l="
)

DEBUG = os.environ.get("DJANGO_DEBUG", "false").lower() == "true"

ALLOWED_HOSTS = ['*']

CSRF_TRUSTED_ORIGINS = [
    'https://agro-b2b.onrender.com'
]

SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
SESSION_COOKIE_SECURE = False
CSRF_COOKIE_SECURE = False

# -------------------------
# APPLICATIONS
# -------------------------
INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",

    # tes apps
    "core",
    "commerce",

    # utile API
    "rest_framework",
    "rest_framework.authtoken",
    "drf_spectacular",
    "corsheaders",
    "gestion",
]

# -------------------------
# MIDDLEWARE
# -------------------------
MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "whitenoise.middleware.WhiteNoiseMiddleware",  # static files prod
    "django.contrib.sessions.middleware.SessionMiddleware",
    "corsheaders.middleware.CorsMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

# -------------------------
# URLS / WSGI
# -------------------------
ROOT_URLCONF = "config.urls"
WSGI_APPLICATION = "config.wsgi.application"

# -------------------------
# DATABASE (RENDER)
# -------------------------
DATABASES = {
    "default": dj_database_url.config(
        env="DATABASE_URL",
        default="postgresql://admin:ripwB7ds02xfjsfUbMtk0Y2gwFq7VbeQ@dpg-d73e4khr0fns73fhuubg-a.oregon-postgres.render.com/agrob2b",
        conn_max_age=600

    )
}

# -------------------------
# PASSWORD VALIDATION
# -------------------------
AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator"},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]

# -------------------------
# LANGUAGE / TIME
# -------------------------
LANGUAGE_CODE = "fr-fr"
TIME_ZONE = "Africa/Algiers"
USE_I18N = True
USE_TZ = True

# -------------------------
# STATIC FILES
# -------------------------
STATIC_URL = "/static/"
STATIC_ROOT = os.path.join(BASE_DIR, "staticfiles")

# whitenoise config
STATICFILES_STORAGE = "whitenoise.storage.CompressedManifestStaticFilesStorage"

# -------------------------
# MEDIA FILES
# -------------------------
MEDIA_URL = "/media/"
MEDIA_ROOT = os.path.join(BASE_DIR, "media")

# -------------------------
# DEFAULT PK
# -------------------------
DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

# -------------------------
# REST FRAMEWORK
# -------------------------
REST_FRAMEWORK = {
    "DEFAULT_SCHEMA_CLASS": "drf_spectacular.openapi.AutoSchema",
    "DEFAULT_AUTHENTICATION_CLASSES": [
        "rest_framework.authentication.TokenAuthentication",
    ],
    "DEFAULT_PERMISSION_CLASSES": [
        "rest_framework.permissions.IsAuthenticated",
    ],
}

CORS_ALLOW_ALL_ORIGINS = True

SPECTACULAR_SETTINGS = {
    "TITLE": "AgroB2B API",
    "DESCRIPTION": "API B2B commande pour grossiste/superette",
    "VERSION": "1.0.0",
}

# -------------------------
# SECURITY (PRODUCTION)
# -------------------------
if not DEBUG:
    CSRF_COOKIE_SECURE = True
    SESSION_COOKIE_SECURE = True
    SECURE_SSL_REDIRECT = True
    SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")