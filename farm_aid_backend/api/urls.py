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
    
#     # NEW: Specific endpoint for the "Switch Everything" language toggle
#     path('auth/profile/language/', ProfileView.as_view(), name='profile-language'),
    
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
    change_password,
    SaveScanView,
    FarmerHistoryView,
    FarmerReportsView,
    CropProfileView,
    FarmerAlertsView,
    LatestWeatherView,
    MarketPricesView,       # NEW
)

urlpatterns = [

    # --- 1. AUTHENTICATION ---
    path('register/',           register_farmer,          name='register'),
    path('login/',              login_farmer,             name='login'),
    path('resend-activation/',  resend_activation_email,  name='resend-activation'),
    path('activate/<uidb64>/<token>/', activate_account,  name='activate'),

    # --- 2. PROFILE & SECURITY ---
    path('auth/profile/',          ProfileView.as_view(), name='profile-detail'),
    path('auth/profile/update/',   ProfileView.as_view(), name='profile-update'),
    path('auth/profile/language/', ProfileView.as_view(), name='profile-language'),
    path('auth/change-password/',  change_password,       name='change-password'),
    # Legacy alias — keeps older app versions working
    path('auth/password/change/',  change_password,       name='change-password-legacy'),

    # --- 3. WEATHER ---
    path('weather/latest/', LatestWeatherView.as_view(), name='latest-weather'),

    # --- 4. CROP PROFILES ---
    path('crop-profiles/', CropProfileView.as_view(), name='crop-profiles'),

    # --- 5. ALERTS ---
    path('alerts/',           FarmerAlertsView.as_view(), name='alerts'),
    path('alerts/mark-read/', FarmerAlertsView.as_view(), name='mark-alerts-read'),

    # --- 6. AI SCAN (8-Factor Engine) ---
    path('save-scan/', SaveScanView.as_view(), name='save-scan'),

    # --- 7. HISTORY & REPORTS ---
    path('farmer-history/', FarmerHistoryView.as_view(), name='farmer-history'),
    path('farmer-reports/', FarmerReportsView.as_view(), name='farmer-reports'),

    # --- 8. MARKET PRICES ---
    # GET /api/market-prices/                   -> all prices
    # GET /api/market-prices/?district=Maseru   -> filtered by district
    path('market-prices/', MarketPricesView.as_view(), name='market-prices'),
]
