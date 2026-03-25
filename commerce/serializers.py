from decimal import Decimal

from rest_framework import serializers

from .models import Notification, Order, OrderItem, Product, ProductVariant


class ProductVariantSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProductVariant
        fields = ["id", "label", "image_url"]


class ProductSerializer(serializers.ModelSerializer):
    category_path = serializers.SerializerMethodField()
    image = serializers.CharField(source="image_url")
    unite = serializers.CharField(source="unit")
    variante = serializers.SerializerMethodField()

    class Meta:
        model = Product
        fields = [
            "id",
            "name",
            "price",
            "stock",
            "image",
            "unite",
            "is_promo",
            "is_top_seller",
            "is_new",
            "category_path",
            "variante",
        ]

    def get_category_path(self, obj) -> list[str]:
        path = []
        category = obj.category
        while category:
            path.insert(0, category.name)
            category = category.parent
        return path

    def get_variante(self, obj) -> str | None:
        first = obj.variants.first()
        return first.label if first else None


class OrderItemReadSerializer(serializers.ModelSerializer):
    produit = ProductSerializer(source="product")
    quantite = serializers.IntegerField(source="quantity")

    class Meta:
        model = OrderItem
        fields = ["id", "produit", "quantite", "unit_price"]


class OrderSerializer(serializers.ModelSerializer):
    statut = serializers.CharField(source="status")
    items = OrderItemReadSerializer(many=True)

    class Meta:
        model = Order
        fields = ["id", "statut", "delivery_type", "total", "created_at", "items"]


class OrderCreateItemSerializer(serializers.Serializer):
    product_id = serializers.IntegerField()
    quantity = serializers.IntegerField(min_value=1)


class OrderCreateSerializer(serializers.Serializer):
    delivery_type = serializers.ChoiceField(choices=["livraison", "retrait"])
    items = OrderCreateItemSerializer(many=True)

    def validate_items(self, value):
        for item in value:
            if not Product.objects.filter(pk=item["product_id"]).exists():
                raise serializers.ValidationError(
                    f"Produit introuvable: {item['product_id']}"
                )
        return value

    def create(self, validated_data):
        profile = self.context["profile"]
        order = Order.objects.create(
            client=profile,
            delivery_type=validated_data["delivery_type"],
            status="pending",
            total=Decimal("0"),
        )

        total = Decimal("0")
        for item in validated_data["items"]:
            product = Product.objects.get(pk=item["product_id"])
            quantity = item["quantity"]
            OrderItem.objects.create(
                order=order,
                product=product,
                quantity=quantity,
                unit_price=product.price,
            )
            total += product.price * quantity

        order.total = total
        order.save(update_fields=["total"])
        return order


class PanierSerializer(serializers.Serializer):
    items = OrderCreateItemSerializer(many=True)

    def validate_items(self, value):
        for item in value:
            if not Product.objects.filter(pk=item["product_id"]).exists():
                raise serializers.ValidationError(
                    f"Produit introuvable: {item['product_id']}"
                )
        return value

    def validate(self, attrs):
        total = Decimal("0")
        computed_items = []

        for item in attrs["items"]:
            product = Product.objects.get(pk=item["product_id"])
            line_total = product.price * item["quantity"]
            total += line_total
            computed_items.append(
                {
                    "product_id": product.id,
                    "product_name": product.name,
                    "quantity": item["quantity"],
                    "unit_price": product.price,
                    "line_total": line_total,
                    "unit": product.unit,
                }
            )

        attrs["computed_items"] = computed_items
        attrs["total"] = total
        return attrs


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = ["id", "title", "message", "is_read", "created_at", "order_id"]

