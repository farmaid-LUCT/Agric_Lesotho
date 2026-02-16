from django.contrib import admin
from django.urls import path, include # 1. Added include here

urlpatterns = [
    path('admin/', admin.site.urls),
    
    # 2. This links http://192.168.137.167:8000/api/ to your api folder
    path('api/', include('api.urls')), 
]