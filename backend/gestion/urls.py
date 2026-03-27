from django.urls import path

from . import views

app_name = "gestion"

urlpatterns = [
    path("login/", views.GestionLoginView.as_view(), name="login"),
    path("logout/", views.GestionLogoutView.as_view(), name="logout"),
    path("setup/", views.SetupView.as_view(), name="setup"),
    path("", views.DashboardView.as_view(), name="dashboard"),
    path("categories/", views.CategoryListView.as_view(), name="category_list"),
    path("categories/nouveau/", views.CategoryCreateView.as_view(), name="category_create"),
    path("categories/<int:pk>/modifier/", views.CategoryUpdateView.as_view(), name="category_update"),
    path("categories/<int:pk>/supprimer/", views.CategoryDeleteView.as_view(), name="category_delete"),
    path("produits/", views.ProductListView.as_view(), name="product_list"),
    path("produits/nouveau/", views.ProductCreateView.as_view(), name="product_create"),
    path("produits/<int:pk>/modifier/", views.ProductUpdateView.as_view(), name="product_update"),
    path("produits/<int:pk>/supprimer/", views.ProductDeleteView.as_view(), name="product_delete"),
    path("commandes/", views.OrderListView.as_view(), name="order_list"),
    path("commandes/<int:pk>/", views.OrderDetailView.as_view(), name="order_detail"),
    path("clients/", views.ClientListView.as_view(), name="client_list"),
    path("clients/<int:pk>/modifier/", views.ClientUpdateView.as_view(), name="client_update"),
    path("equipe/", views.StaffUserListView.as_view(), name="user_list"),
    path("equipe/nouveau/", views.StaffUserCreateView.as_view(), name="user_create"),
]
