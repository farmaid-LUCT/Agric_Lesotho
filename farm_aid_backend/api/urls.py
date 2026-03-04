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

    # NEW: Personalization features
    FarmerInsightView,
    GrowthJournalView,
    MarketPriceView,
)

urlpatterns = [

    # --------------------------------------------------------
    # AUTH
    # --------------------------------------------------------
    path('register/', register_farmer, name='register'),
    path('login/', login_farmer, name='login'),
    path('activate/<uidb64>/<token>/', activate_account, name='activate'),
    path('resend-activation/', resend_activation_email, name='resend-activation'),
    path('auth/password/change/', change_password, name='change-password'),

    # --------------------------------------------------------
    # PROFILE
    # GET  → fetch full profile (includes new personalization fields)
    # PATCH → update any allowed field (district, experience_level,
    #          notification prefs, onboarding_complete, etc.)
    # --------------------------------------------------------
    path('auth/profile/', ProfileView.as_view(), name='profile'),

    # --------------------------------------------------------
    # WEATHER
    # GET → returns weather for farmer's district (or latest overall)
    # --------------------------------------------------------
    path('weather/latest/', LatestWeatherView.as_view(), name='latest-weather'),

    # --------------------------------------------------------
    # CROP PROFILES
    # GET   → list active profiles with growth_stage_label attached
    # POST  → create new profile (soil, irrigation, variety, etc.)
    # PATCH → update existing profile
    # --------------------------------------------------------
    path('crop-profiles/', CropProfileView.as_view(), name='crop-profiles'),

    # --------------------------------------------------------
    # ALERTS
    # GET  → fetch alerts for farmer (respects district_target + expires_at)
    # POST → mark all as read
    # --------------------------------------------------------
    path('alerts/', FarmerAlertsView.as_view(), name='alerts'),

    # --------------------------------------------------------
    # AI SCAN (Core feature)
    # POST → saves Plant + GPS + Diagnosis, runs 8-factor rule
    #        engine, updates FarmerInsight, schedules follow-up
    # --------------------------------------------------------
    path('save-scan/', SaveScanView.as_view(), name='save-scan'),

    # --------------------------------------------------------
    # DIAGNOSIS FEEDBACK
    # PATCH → farmer confirms/disputes diagnosis, records
    #         treatment_applied and treatment_outcome
    # e.g. PATCH /api/diagnosis/42/feedback/
    # --------------------------------------------------------
    path('diagnosis/<int:diagnosis_id>/feedback/', DiagnosisFeedbackView.as_view(), name='diagnosis-feedback'),

    # --------------------------------------------------------
    # HISTORY & REPORTS
    # --------------------------------------------------------
    path('farmer-history/', FarmerHistoryView.as_view(), name='farmer-history'),
    path('farmer-reports/', FarmerReportsView.as_view(), name='farmer-reports'),

    # --------------------------------------------------------
    # FARMER INSIGHT (Personalized dashboard analytics)
    # GET → returns total_scans, most_common_disease,
    #       streak_healthy_days, health_rate, highest_risk_month, etc.
    # --------------------------------------------------------
    path('farmer-insight/', FarmerInsightView.as_view(), name='farmer-insight'),

    # --------------------------------------------------------
    # GROWTH JOURNAL
    # GET    → list entries (filter by ?profile_id=X)
    # POST   → create new entry with mood + optional photo
    # DELETE → /journal/<entry_id>/delete/
    # --------------------------------------------------------
    path('journal/', GrowthJournalView.as_view(), name='journal-list'),
    path('journal/<int:entry_id>/delete/', GrowthJournalView.as_view(), name='journal-delete'),

    # --------------------------------------------------------
    # MARKET PRICES
    # GET → returns prices pre-filtered to farmer's active crops
    #       and district. Optional ?district= override.
    # --------------------------------------------------------
    path('market-prices/', MarketPriceView.as_view(), name='market-prices'),
]
