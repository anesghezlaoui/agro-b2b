from rest_framework import permissions


class IsValidatedClient(permissions.BasePermission):
    message = 'Compte non valide par le grossiste.'

    def has_permission(self, request, view):
        user = request.user
        if not user or not user.is_authenticated:
            return False
        if user.is_staff or user.is_superuser:
            return True
        profile = getattr(user, 'client_profile', None)
        return bool(profile and profile.is_validated)
