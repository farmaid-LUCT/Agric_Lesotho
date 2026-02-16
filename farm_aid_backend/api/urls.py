
# # farm_aid_backend/api/urls.py
# from django.urls import path
# from .views import (
#     register_farmer, 
#     login_farmer,
#     resend_activation_email,
#     activate_account,
#     ProfileView,
#     change_password,          # ADDED: New view for secure password updates
#     SaveScanView,
#     FarmerHistoryView,
#     FarmerReportsView,
#     CropProfileView, 
#     FarmerAlertsView, 
#     LatestWeatherView 
# )

# urlpatterns = [
#     # --- Auth Endpoints ---
#     path('register/', register_farmer, name='register'),
#     path('login/', login_farmer, name='login'), 
    
#     # --- Profile & Security (Neon DB) ---
#     path('auth/profile/', ProfileView.as_view(), name='profile-detail'),
#     path('auth/profile/update/', ProfileView.as_view(), name='profile-update'),
#     path('auth/password/change/', change_password, name='change-password'), # NEW: Maps to Flutter _showPasswordDialog
    
#     # --- Email Verification & Resend ---
#     path('activate/<uidb64>/<token>/', activate_account, name='activate'),
#     path('resend-activation/', resend_activation_email, name='resend-activation'),

#     # --- Live Weather ---
#     path('weather/latest/', LatestWeatherView.as_view(), name='latest-weather'),

#     # --- Alerts ---
#     path('crop-profiles/', CropProfileView.as_view(), name='crop-profiles'),
#     path('alerts/', FarmerAlertsView.as_view(), name='alerts'),
#     path('alerts/mark-read/', FarmerAlertsView.as_view(), name='mark-alerts-read'),

#     # --- AI & Knowledgebase Endpoints ---
#     path('save-scan/', SaveScanView.as_view(), name='save-scan'),
    
#     # --- History & Reports ---
#     path('farmer-history/', FarmerHistoryView.as_view(), name='farmer-history'),
#     path('farmer-reports/', FarmerReportsView.as_view(), name='farmer-reports'),
# ]




# farm_aid_backend/api/urls.py
from django.urls import path
from .views import (
    register_farmer, 
    login_farmer,
    resend_activation_email,
    activate_account,
    ProfileView,
    change_password,          # ADDED: New view for secure password updates
    SaveScanView,
    FarmerHistoryView,
    FarmerReportsView,
    CropProfileView, 
    FarmerAlertsView, 
    LatestWeatherView 
)

urlpatterns = [
    # --- Auth Endpoints ---
    path('register/', register_farmer, name='register'),
    path('login/', login_farmer, name='login'), 
    
    # --- Profile & Security (Neon DB) ---
    path('auth/profile/', ProfileView.as_view(), name='profile-detail'),
    path('auth/profile/update/', ProfileView.as_view(), name='profile-update'),
    
    # NEW: Specific endpoint for the "Switch Everything" language toggle
    path('auth/profile/language/', ProfileView.as_view(), name='profile-language'),
    
    path('auth/password/change/', change_password, name='change-password'), # NEW: Maps to Flutter _showPasswordDialog
    
    # --- Email Verification & Resend ---
    path('activate/<uidb64>/<token>/', activate_account, name='activate'),
    path('resend-activation/', resend_activation_email, name='resend-activation'),

    # --- Live Weather ---
    path('weather/latest/', LatestWeatherView.as_view(), name='latest-weather'),

    # --- Alerts ---
    path('crop-profiles/', CropProfileView.as_view(), name='crop-profiles'),
    path('alerts/', FarmerAlertsView.as_view(), name='alerts'),
    path('alerts/mark-read/', FarmerAlertsView.as_view(), name='mark-alerts-read'),

    # --- AI & Knowledgebase Endpoints ---
    path('save-scan/', SaveScanView.as_view(), name='save-scan'),
    
    # --- History & Reports ---
    path('farmer-history/', FarmerHistoryView.as_view(), name='farmer-history'),
    path('farmer-reports/', FarmerReportsView.as_view(), name='farmer-reports'),
]