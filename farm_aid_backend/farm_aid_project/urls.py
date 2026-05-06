# from django.contrib import admin
# from django.urls import path, include
# from django.conf import settings
# from django.conf.urls.static import static

# urlpatterns = [
#     # Admin Panel (Jazzmin)
#     path('admin/', admin.site.urls),
    
#     # API Routes: All endpoints in api/urls.py will be prefixed with /api/
#     # Example: http://farmaid-backend.onrender.com/api/login/
#     path('api/', include('api.urls')), 
# ]

# # Serve Media/Static files during development (Crucial for seeing vegetable images)
# if settings.DEBUG:
#     urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
#     urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)

# farm_aid_project/urls.py
from django.contrib import admin  # Use default admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from api.dashboard_views import (
    dashboard_stats,
    recent_diagnoses,
    disease_breakdown,
    recent_activity,
)

urlpatterns = [
    # Dashboard API endpoints
    path('admin/dashboard-stats/',   dashboard_stats,   name='dashboard_stats'),
    path('admin/recent-diagnoses/',  recent_diagnoses,  name='recent_diagnoses'),
    path('admin/disease-breakdown/', disease_breakdown, name='disease_breakdown'),
    path('admin/recent-activity/',   recent_activity,   name='recent_activity'),

    # Admin Panel (using default admin)
    path('admin/', admin.site.urls),  # ← Use default admin

    # API Routes
    path('api/', include('api.urls')),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)

    # ── API Routes
    path('api/', include('api.urls')),
]

# Serve Media/Static files during development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
