from django.db import models


class Category(models.Model):
    name = models.CharField(max_length=120)
    parent = models.ForeignKey(
        "self",
        null=True,
        blank=True,
        on_delete=models.CASCADE,
        related_name="children",
    )
    image = models.ImageField(
        upload_to="category_images/",
        blank=True,
        null=True,
    )

    class Meta:
        verbose_name_plural = "categories"

    def __str__(self) -> str:
        return self.name


class Product(models.Model):
    UNIT_CHOICES = (
        ("piece", "Piece"),
        ("carton", "Carton"),
    )

    name = models.CharField(max_length=160)
    category = models.ForeignKey(
        Category,
        on_delete=models.SET_NULL,
        null=True,
        related_name="products",
    )
    price = models.DecimalField(max_digits=12, decimal_places=2)
    stock = models.PositiveIntegerField(default=0)
    image_url = models.URLField(blank=True)
    unit = models.CharField(max_length=12, choices=UNIT_CHOICES, default="piece")
    is_promo = models.BooleanField(default=False)
    is_top_seller = models.BooleanField(default=False)
    is_new = models.BooleanField(default=False)

    def __str__(self) -> str:
        return self.name


class ProductVariant(models.Model):
    product = models.ForeignKey(
        Product, on_delete=models.CASCADE, related_name="variants"
    )
    label = models.CharField(max_length=120)
    image_url = models.URLField(blank=True)

    def __str__(self) -> str:
        return f"{self.product.name} - {self.label}"


class Order(models.Model):
    STATUS_CHOICES = (
        ("pending", "En attente"),
        ("preparing", "En preparation"),
        ("delivering", "En livraison"),
        ("delivered", "Livree"),
    )
    DELIVERY_CHOICES = (
        ("livraison", "Livraison"),
        ("retrait", "Retrait"),
    )

    client = models.ForeignKey(
        "core.ClientProfile",
        on_delete=models.CASCADE,
        related_name="orders",
    )
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default="pending")
    delivery_type = models.CharField(
        max_length=20, choices=DELIVERY_CHOICES, default="livraison"
    )
    total = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self) -> str:
        return f"Commande #{self.pk}"


class OrderItem(models.Model):
    order = models.ForeignKey(
        Order, on_delete=models.CASCADE, related_name="items"
    )
    product = models.ForeignKey(
        Product, on_delete=models.PROTECT, related_name="order_items"
    )
    quantity = models.PositiveIntegerField(default=1)
    unit_price = models.DecimalField(max_digits=12, decimal_places=2, default=0)

    def __str__(self) -> str:
        return f"{self.product.name} x {self.quantity}"


class Notification(models.Model):
    client = models.ForeignKey(
        "core.ClientProfile",
        on_delete=models.CASCADE,
        related_name="notifications",
    )
    order = models.ForeignKey(
        Order,
        on_delete=models.CASCADE,
        related_name="notifications",
        null=True,
        blank=True,
    )
    title = models.CharField(max_length=120)
    message = models.TextField()
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self) -> str:
        return f"{self.client.phone} - {self.title}"
