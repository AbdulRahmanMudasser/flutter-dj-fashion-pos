from django.apps import AppConfig


class OrdersConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'orders'
    verbose_name = 'Order Management'
    
    def ready(self):
        """Import signals when the app is ready"""
        import orders.signals
        