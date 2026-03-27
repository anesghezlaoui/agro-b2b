from drf_spectacular.utils import OpenApiResponse, extend_schema, inline_serializer
from rest_framework import permissions, serializers, status
from rest_framework.generics import get_object_or_404
from rest_framework.response import Response
from rest_framework.views import APIView

from core.permissions import IsValidatedClient

from .models import Category, Notification, Order, Product
from .serializers import (
    CategorySerializer,
    NotificationSerializer,
    OrderCreateSerializer,
    OrderSerializer,
    PanierSerializer,
    ProductSerializer,
)


class CategoryListView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsValidatedClient]

    @extend_schema(
        responses={
            200: inline_serializer(
                name="CategoriesResponse",
                fields={"results": CategorySerializer(many=True)},
            )
        }
    )
    def get(self, request):
        queryset = Category.objects.all().select_related("parent")
        serializer = CategorySerializer(
            queryset, many=True, context={"request": request}
        )
        return Response({"results": serializer.data})


class ProductListView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsValidatedClient]

    @extend_schema(
        responses={
            200: inline_serializer(
                name="ProductsResponse",
                fields={"results": ProductSerializer(many=True)},
            )
        }
    )
    def get(self, request):
        queryset = (
            Product.objects.all()
            .select_related("category")
            .prefetch_related("variants", "conditionnements")
        )
        serializer = ProductSerializer(
            queryset, many=True, context={"request": request}
        )
        return Response({"results": serializer.data})


class PanierView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsValidatedClient]

    @extend_schema(
        request=PanierSerializer,
        responses={
            200: inline_serializer(
                name="PanierResponse",
                fields={
                    "items": serializers.ListField(child=serializers.DictField()),
                    "total": serializers.DecimalField(max_digits=12, decimal_places=2),
                },
            )
        },
    )
    def post(self, request):
        serializer = PanierSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        return Response(
            {
                "items": serializer.validated_data["computed_items"],
                "total": serializer.validated_data["total"],
            }
        )


class OrderListCreateView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsValidatedClient]

    @extend_schema(
        responses={
            200: inline_serializer(
                name="OrdersResponse",
                fields={"results": OrderSerializer(many=True)},
            )
        }
    )
    def get(self, request):
        profile = request.user.client_profile
        orders = (
            Order.objects.filter(client=profile)
            .prefetch_related("items__product__variants", "items__product__category")
            .all()
        )
        serializer = OrderSerializer(
            orders, many=True, context={"request": request}
        )
        return Response({"results": serializer.data})

    @extend_schema(
        request=OrderCreateSerializer,
        responses={
            201: inline_serializer(
                name="CreateOrderResponse",
                fields={"order": OrderSerializer()},
            ),
            400: OpenApiResponse(description="Payload invalide"),
        },
    )
    def post(self, request):
        profile = request.user.client_profile
        serializer = OrderCreateSerializer(data=request.data, context={"profile": profile})
        serializer.is_valid(raise_exception=True)
        order = serializer.save()
        output = OrderSerializer(order, context={"request": request})
        return Response({"order": output.data}, status=status.HTTP_201_CREATED)


class NotificationListView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsValidatedClient]

    @extend_schema(
        responses={
            200: inline_serializer(
                name="NotificationsResponse",
                fields={
                    "results": NotificationSerializer(many=True),
                    "unread_count": serializers.IntegerField(),
                },
            )
        }
    )
    def get(self, request):
        profile = request.user.client_profile
        notifications = Notification.objects.filter(client=profile)[:50]
        serializer = NotificationSerializer(notifications, many=True)
        unread = Notification.objects.filter(client=profile, is_read=False).count()
        return Response({"results": serializer.data, "unread_count": unread})


class NotificationMarkReadView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsValidatedClient]

    @extend_schema(
        request=None,
        responses={
            200: inline_serializer(
                name="NotificationReadResponse",
                fields={"id": serializers.IntegerField(), "is_read": serializers.BooleanField()},
            ),
            404: OpenApiResponse(description="Notification introuvable"),
        },
    )
    def post(self, request, notification_id):
        profile = request.user.client_profile
        notification = get_object_or_404(Notification, pk=notification_id, client=profile)
        notification.is_read = True
        notification.save(update_fields=["is_read"])
        return Response({"id": notification.id, "is_read": notification.is_read})
