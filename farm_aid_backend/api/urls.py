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


from django.urls import path
from .views import (
    # Auth
    register_farmer,
    login_farmer,
    resend_activation_email,
    activate_account,
    change_password,

    # Profile & Weather
    ProfileView,
    LatestWeatherView,

    # Crop Profiles & Alerts
    CropProfileView,
    FarmerAlerts_View, # Note: Ensure naming matches views.py exactly

    # AI Scan & Feedback
    SaveScanView,
    DiagnosisFeedbackView,

    # History & Reports
    FarmerHistoryView,
    FarmerReportsView,

    # Personalization features
    FarmerInsightView,
    GrowthJournalView,
    MarketPriceView,
)

urlpatterns = [
    # --------------------------------------------------------
    # AUTHENTICATION
    # --------------------------------------------------------
    path('register/', register_farmer, name='register'),
    path('login/', login_farmer, name='login'),
    # Fixed to ensure strict string patterns for security tokens
    path('activate/<str:uidb64>/<str:token>/', activate_account, name='activate'),
    path('resend-activation/', resend_activation_email, name='resend-activation'),
    path('auth/change-password/', change_password, name='change-password'),

    # --------------------------------------------------------
    # PROFILE (Matches Flutter AuthService)
    # --------------------------------------------------------
    path('auth/profile/', ProfileView.as_view(), name='profile'),
    path('auth/profile/update/', ProfileView.as_view(), name='profile-update'),

    # --------------------------------------------------------
    # WEATHER & ALERTS
    # --------------------------------------------------------
    path('weather/latest/', LatestWeatherView.as_view(), name='latest-weather'),
    path('alerts/', FarmerAlertsView.as_view(), name='alerts'),

    # --------------------------------------------------------
    # SCANNER & TREATMENT (The 8-Factor Engine)
    # --------------------------------------------------------
    # This is where Flutter sends the vegetable image result
    path('save-scan/', SaveScanView.as_view(), name='save-scan'),
    path('diagnosis/<int:diagnosis_id>/feedback/', DiagnosisFeedbackView.as_view(), name='diagnosis-feedback'),

    # --------------------------------------------------------
    # HISTORY & REPORTS (Used by Flutter HistoryScreen)
    # --------------------------------------------------------
    path('farmer-history/', FarmerHistoryView.as_view(), name='farmer-history'),
    path('farmer-reports/', FarmerReportsView.as_view(), name='farmer-reports'),

    # --------------------------------------------------------
    # PERSONALIZATION & GROWTH
    # --------------------------------------------------------
    path('farmer-insight/', FarmerInsightView.as_view(), name='farmer-insight'),
    path('journal/', GrowthJournalView.as_view(), name='journal-list'),
    path('journal/<int:entry_id>/delete/', GrowthJournalView.as_view(), name='journal-delete'),
    path('market-prices/', MarketPriceView.as_view(), name='market-prices'),
    path('crop-profiles/', CropProfileView.as_view(), name='crop-profiles'),
]
