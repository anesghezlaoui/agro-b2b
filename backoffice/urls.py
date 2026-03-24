from django.urls import path

from . import views

app_name = 'backoffice'

urlpatterns = [
    path(
        'creer-superutilisateur/',
        views.setup_superuser,
        name='setup_superuser',
    ),
    path('', views.dashboard, name='dashboard'),
    path('login/', views.StaffLoginView.as_view(), name='login'),
    path('logout/', views.staff_logout, name='logout'),
    path('variantes/', views.variant_list, name='variant_list'),
    path('clients/', views.client_list, name='client_list'),
    path('clients/<int:pk>/', views.client_detail, name='client_detail'),
    path('commandes/', views.order_list, name='order_list'),
    path('commandes/<int:pk>/', views.order_detail, name='order_detail'),
    path('produits/', views.product_list, name='product_list'),
    path('produits/nouveau/', views.product_create, name='product_create'),
    path('produits/<int:pk>/modifier/', views.product_edit, name='product_edit'),
    path('produits/<int:pk>/supprimer/', views.product_delete, name='product_delete'),
    path(
        'produits/<int:product_pk>/variantes/',
        views.product_variant_list,
        name='product_variant_list',
    ),
    path(
        'produits/<int:product_pk>/variantes/nouvelle/',
        views.variant_create,
        name='variant_create',
    ),
    path(
        'produits/<int:product_pk>/variantes/<int:pk>/modifier/',
        views.variant_edit,
        name='variant_edit',
    ),
    path(
        'produits/<int:product_pk>/variantes/<int:pk>/supprimer/',
        views.variant_delete,
        name='variant_delete',
    ),
    path('categories/', views.category_list, name='category_list'),
    path('categories/nouvelle/', views.category_create, name='category_create'),
    path('categories/<int:pk>/modifier/', views.category_edit, name='category_edit'),
    path('categories/<int:pk>/supprimer/', views.category_delete, name='category_delete'),
]
