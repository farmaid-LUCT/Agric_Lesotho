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
    FarmerAlertsView,

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
    path('activate/<uidb64>/<token>/', activate_account, name='activate'),
    path('resend-activation/', resend_activation_email, name='resend-activation'),
    
    # Matches your AuthService: changePassword() 
    path('auth/change-password/', change_password, name='change-password'),

    # --------------------------------------------------------
    # PROFILE (Matches AuthService: getCurrentUser & updateProfile)
    # --------------------------------------------------------
    path('auth/profile/', ProfileView.as_view(), name='profile'),
    # Extra endpoint for the updateProfile patch call specifically
    path('auth/profile/update/', ProfileView.as_view(), name='profile-update'),

    # --------------------------------------------------------
    # WEATHER
    # --------------------------------------------------------
    path('weather/latest/', LatestWeatherView.as_view(), name='latest-weather'),

    # --------------------------------------------------------
    # CROP PROFILES (Matches your CropProfile model)
    # --------------------------------------------------------
    path('crop-profiles/', CropProfileView.as_view(), name='crop-profiles'),

    # --------------------------------------------------------
    # ALERTS
    # --------------------------------------------------------
    path('alerts/', FarmerAlertsView.as_view(), name='alerts'),

    # --------------------------------------------------------
    # AI SCAN (Core Logic: Plant + Diagnosis + Rule Engine)
    # --------------------------------------------------------
    path('save-scan/', SaveScanView.as_view(), name='save-scan'),

    # --------------------------------------------------------
    # DIAGNOSIS FEEDBACK
    # --------------------------------------------------------
    path('diagnosis/<int:diagnosis_id>/feedback/', DiagnosisFeedbackView.as_view(), name='diagnosis-feedback'),

    # --------------------------------------------------------
    # HISTORY & REPORTS
    # --------------------------------------------------------
    path('farmer-history/', FarmerHistoryView.as_view(), name='farmer-history'),
    path('farmer-reports/', FarmerReportsView.as_view(), name='farmer-reports'),

    # --------------------------------------------------------
    # FARMER INSIGHTS (Personalized Dashboard Analytics)
    # --------------------------------------------------------
    path('farmer-insight/', FarmerInsightView.as_view(), name='farmer-insight'),

    # --------------------------------------------------------
    # GROWTH JOURNAL
    # --------------------------------------------------------
    path('journal/', GrowthJournalView.as_view(), name='journal-list'),
    path('journal/<int:entry_id>/delete/', GrowthJournalView.as_view(), name='journal-delete'),

    # --------------------------------------------------------
    # MARKET PRICES
    # --------------------------------------------------------
    path('market-prices/', MarketPriceView.as_view(), name='market-prices'),
]

