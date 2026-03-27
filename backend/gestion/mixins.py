from django.contrib.auth.mixins import LoginRequiredMixin, UserPassesTestMixin


class StaffRequiredMixin(LoginRequiredMixin, UserPassesTestMixin):
    """Accès réservé aux comptes staff (équipe interne)."""

    login_url = "/gestion/login/"

    def test_func(self) -> bool:
        u = self.request.user
        return u.is_authenticated and u.is_staff
