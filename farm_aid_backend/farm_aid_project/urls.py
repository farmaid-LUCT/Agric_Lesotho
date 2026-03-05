from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    # Admin Panel (Jazzmin)
    path('admin/', admin.site.urls),
    
    # API Routes: All endpoints in api/urls.py will be prefixed with /api/
    # Example: http://farmaid-backend.onrender.com/api/login/
    path('api/', include('api.urls')), 
]

# Serve Media/Static files during development (Crucial for seeing vegetable images)
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
