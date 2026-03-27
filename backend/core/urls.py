from django.urls import path

from .views import ClientSessionView, LoginView, RegisterView, ValidateClientView

urlpatterns = [
    path("login", LoginView.as_view(), name="api-login"),
    path("register", RegisterView.as_view(), name="api-register"),
    path("me", ClientSessionView.as_view(), name="api-me"),
    path("clients/<int:profile_id>/validate", ValidateClientView.as_view(), name="api-client-validate"),
]

