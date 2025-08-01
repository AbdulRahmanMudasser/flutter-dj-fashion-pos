# Generated by Django 5.2.4 on 2025-08-02 13:01

import django.db.models.deletion
import uuid
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        ('categories', '0001_initial'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='Product',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('name', models.CharField(help_text='Product name', max_length=200)),
                ('detail', models.TextField(help_text='Product description/details')),
                ('price', models.DecimalField(decimal_places=2, help_text='Product price in PKR', max_digits=12)),
                ('color', models.CharField(help_text='Product color', max_length=50)),
                ('fabric', models.CharField(help_text='Fabric type/material', max_length=100)),
                ('pieces', models.JSONField(default=list, help_text="Array of product pieces (e.g., ['Blouse', 'Lehenga', 'Dupatta'])")),
                ('quantity', models.PositiveIntegerField(default=0, help_text='Available quantity in stock')),
                ('is_active', models.BooleanField(default=True, help_text="Used for soft deletion. Inactive products won't appear in lists")),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('category', models.ForeignKey(help_text='Product category', on_delete=django.db.models.deletion.PROTECT, related_name='products', to='categories.category')),
                ('created_by', models.ForeignKey(blank=True, help_text='User who created this product', null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='created_products', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'verbose_name': 'Product',
                'verbose_name_plural': 'Products',
                'db_table': 'product',
                'ordering': ['-created_at', 'name'],
                'indexes': [models.Index(fields=['name'], name='product_name_c4c985_idx'), models.Index(fields=['category'], name='product_categor_26b384_idx'), models.Index(fields=['quantity'], name='product_quantit_e949e8_idx'), models.Index(fields=['price'], name='product_price_d2c05d_idx'), models.Index(fields=['is_active'], name='product_is_acti_916801_idx'), models.Index(fields=['created_at'], name='product_created_fe1f54_idx')],
            },
        ),
    ]
