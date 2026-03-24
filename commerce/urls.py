from django.urls import path

from .views import (
    NotificationListView,
    NotificationMarkReadView,
    OrderListCreateView,
    PanierView,
    ProductListView,
)

urlpatterns = [
    path('produits', ProductListView.as_view(), name='api-produits'),
    path('panier', PanierView.as_view(), name='api-panier'),
    path('commandes', OrderListCreateView.as_view(), name='api-commandes'),
    path('notifications', NotificationListView.as_view(), name='api-notifications'),
    path(
        'notifications/<int:notification_id>/read',
        NotificationMarkReadView.as_view(),
        name='api-notification-read',
    ),
]
