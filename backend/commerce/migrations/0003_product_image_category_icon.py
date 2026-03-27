from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("commerce", "0002_product_top_new_flags"),
    ]

    operations = [
        migrations.AddField(
            model_name="category",
            name="icon",
            field=models.ImageField(
                blank=True,
                help_text="Petit pictogramme (PNG recommandé, fond transparent).",
                null=True,
                upload_to="category_icons/",
            ),
        ),
        migrations.AddField(
            model_name="product",
            name="image",
            field=models.ImageField(
                blank=True,
                help_text="Image catalogue (prioritaire sur l’URL externe ci-dessous).",
                null=True,
                upload_to="product_images/",
            ),
        ),
    ]
