import dj_database_url

# -------------------------
# SECURITY
# -------------------------
SECRET_KEY = os.environ.get(
    "DJANGO_SECRET_KEY",
    "^v@3qqm*fc4cyd^=2fr4dtjl==l)zhj*-4u1qli2$+6ov4l=l="
)

DEBUG = os.environ.get("DJANGO_DEBUG", "false").lower() == "true"

ALLOWED_HOSTS = os.environ.get(
    "ALLOWED_HOSTS",
    "agro-b2b.onrender.com,localhost,127.0.0.1"
).split(",")

# -------------------------
# DATABASE (RENDER READY)
# -------------------------
DATABASES = {
    "default": dj_database_url.config(
        default=os.environ.get("DATABASE_URL")
    )
}