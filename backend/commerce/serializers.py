from decimal import Decimal

from rest_framework import serializers

from .models import (
    Category,
    Conditionnement,
    Notification,
    Order,
    OrderItem,
    Product,
    ProductVariant,
)


def _absolute_file_url(request, file_field) -> str:
    if not file_field:
        return ""
    path = file_field.url
    if request is not None:
        return request.build_absolute_uri(path)
    return path


class CategorySerializer(serializers.ModelSerializer):
    """Métadonnées rayon pour l’app (image bannière + pictogramme)."""

    image = serializers.SerializerMethodField()
    icon = serializers.SerializerMethodField()

    class Meta:
        model = Category
        fields = [
            "id",
            "name",
            "parent_id",
            "image",
            "icon",
            "show_icon",
            "show_image",
        ]

    def get_image(self, obj) -> str:
        return _absolute_file_url(self.context.get("request"), obj.image)

    def get_icon(self, obj) -> str:
        return _absolute_file_url(self.context.get("request"), obj.icon)


class ProductVariantSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProductVariant
        fields = ["id", "label", "image_url"]


class ConditionnementSerializer(serializers.ModelSerializer):
    unite = serializers.IntegerField(source="unite_par_conditionnement")
    prix_unitaire = serializers.SerializerMethodField()

    class Meta:
        model = Conditionnement
        fields = [
            "id",
            "type",
            "unite",
            "prix",
            "prix_unitaire",
            "stock",
            "emplacement",
            "ordre",
            "is_default",
        ]

    def get_prix_unitaire(self, obj):
        if obj.unite_par_conditionnement <= 0:
            return Decimal("0")
        return obj.prix / Decimal(obj.unite_par_conditionnement)


class ProductSerializer(serializers.ModelSerializer):
    category_path = serializers.SerializerMethodField()
    image = serializers.SerializerMethodField()
    unite = serializers.SerializerMethodField()
    price = serializers.SerializerMethodField()
    stock = serializers.SerializerMethodField()
    variante = serializers.SerializerMethodField()
    conditionnements = serializers.SerializerMethodField()
    show_conditionnement = serializers.BooleanField()

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
            "conditionnements",
            "show_conditionnement",
        ]

    def get_image(self, obj) -> str:
        if obj.image:
            return _absolute_file_url(self.context.get("request"), obj.image)
        return (obj.image_url or "").strip()

    def _default_conditionnement(self, obj):
        default = obj.conditionnements.filter(is_active=True, is_default=True).first()
        if default:
            return default
        return obj.conditionnements.filter(is_active=True).order_by("ordre", "id").first()

    def get_price(self, obj):
        default = self._default_conditionnement(obj)
        return default.prix if default else obj.price

    def get_stock(self, obj):
        default = self._default_conditionnement(obj)
        return default.stock if default else obj.stock

    def get_unite(self, obj):
        default = self._default_conditionnement(obj)
        return default.type if default else obj.unit

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

    def get_conditionnements(self, obj):
        qs = obj.conditionnements.filter(is_active=True).order_by("ordre", "id")
        return ConditionnementSerializer(qs, many=True).data


class OrderItemReadSerializer(serializers.ModelSerializer):
    produit = ProductSerializer(source="product")
    quantite = serializers.IntegerField(source="quantity")
    conditionnement_id = serializers.IntegerField(allow_null=True)

    class Meta:
        model = OrderItem
        fields = ["id", "produit", "quantite", "unit_price", "conditionnement_id"]


class OrderSerializer(serializers.ModelSerializer):
    statut = serializers.CharField(source="status")
    items = OrderItemReadSerializer(many=True)

    class Meta:
        model = Order
        fields = ["id", "statut", "delivery_type", "total", "created_at", "items"]


class OrderCreateItemSerializer(serializers.Serializer):
    product_id = serializers.IntegerField()
    conditionnement_id = serializers.IntegerField(required=False, allow_null=True)
    quantity = serializers.IntegerField(min_value=1)


class OrderCreateSerializer(serializers.Serializer):
    delivery_type = serializers.ChoiceField(choices=["livraison", "retrait"])
    items = OrderCreateItemSerializer(many=True)

    def validate_items(self, value):
        for item in value:
            product = Product.objects.filter(pk=item["product_id"]).first()
            if not product:
                raise serializers.ValidationError(
                    f"Produit introuvable: {item['product_id']}"
                )
            conditionnement_id = item.get("conditionnement_id")
            if conditionnement_id is None:
                continue
            exists = Conditionnement.objects.filter(
                pk=conditionnement_id,
                product=product,
                is_active=True,
            ).exists()
            if not exists:
                raise serializers.ValidationError(
                    f"Conditionnement invalide: {conditionnement_id}"
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
            conditionnement = None
            unit_price = product.price
            conditionnement_id = item.get("conditionnement_id")
            if conditionnement_id is not None:
                conditionnement = Conditionnement.objects.get(
                    pk=conditionnement_id, product=product, is_active=True
                )
                unit_price = conditionnement.prix
            quantity = item["quantity"]
            OrderItem.objects.create(
                order=order,
                product=product,
                conditionnement=conditionnement,
                quantity=quantity,
                unit_price=unit_price,
            )
            total += unit_price * quantity

        order.total = total
        order.save(update_fields=["total"])
        return order


class PanierSerializer(serializers.Serializer):
    items = OrderCreateItemSerializer(many=True)

    def validate_items(self, value):
        for item in value:
            product = Product.objects.filter(pk=item["product_id"]).first()
            if not product:
                raise serializers.ValidationError(
                    f"Produit introuvable: {item['product_id']}"
                )
            conditionnement_id = item.get("conditionnement_id")
            if conditionnement_id is None:
                continue
            exists = Conditionnement.objects.filter(
                pk=conditionnement_id,
                product=product,
                is_active=True,
            ).exists()
            if not exists:
                raise serializers.ValidationError(
                    f"Conditionnement invalide: {conditionnement_id}"
                )
        return value

    def validate(self, attrs):
        total = Decimal("0")
        computed_items = []

        for item in attrs["items"]:
            product = Product.objects.get(pk=item["product_id"])
            conditionnement = None
            unit_price = product.price
            conditionnement_id = item.get("conditionnement_id")
            if conditionnement_id is not None:
                conditionnement = Conditionnement.objects.get(
                    pk=conditionnement_id, product=product, is_active=True
                )
                unit_price = conditionnement.prix
            line_total = unit_price * item["quantity"]
            total += line_total
            computed_items.append(
                {
                    "product_id": product.id,
                    "conditionnement_id": conditionnement.id if conditionnement else None,
                    "product_name": product.name,
                    "quantity": item["quantity"],
                    "unit_price": unit_price,
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

