from django.urls import path

from .views import LoginView, RegisterView, ValidateClientView

urlpatterns = [
    path("login", LoginView.as_view(), name="api-login"),
    path("register", RegisterView.as_view(), name="api-register"),
    path("clients/<int:profile_id>/validate", ValidateClientView.as_view(), name="api-client-validate"),
]

