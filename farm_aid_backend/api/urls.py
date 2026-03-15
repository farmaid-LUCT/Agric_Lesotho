# # farm_aid_backend/api/urls.py
# from django.urls import path
# from .views import (
#     register_farmer,
#     login_farmer,
#     resend_activation_email,
#     activate_account,
#     ProfileView,
#     change_password,
#     SaveScanView,
#     FarmerHistoryView,
#     FarmerReportsView,
#     CropProfileView,
#     FarmerAlertsView,
#     LatestWeatherView,
#     MarketPricesView,       # NEW
#     DiagnosisFeedbackView,  # NEW
#     FarmerInsightView,      # NEW
#     GrowthJournalView,      # NEW
# )

# urlpatterns = [

#     # --- 1. AUTHENTICATION ---
#     path('register/',           register_farmer,          name='register'),
#     path('login/',              login_farmer,             name='login'),
#     path('resend-activation/',  resend_activation_email,  name='resend-activation'),
#     path('activate/<uidb64>/<token>/', activate_account,  name='activate'),

#     # --- 2. PROFILE & SECURITY ---
#     path('auth/profile/',          ProfileView.as_view(), name='profile-detail'),
#     path('auth/profile/update/',   ProfileView.as_view(), name='profile-update'),
#     path('auth/profile/language/', ProfileView.as_view(), name='profile-language'),
#     path('auth/change-password/',  change_password,       name='change-password'),
#     # Legacy alias — keeps older app versions working
#     path('auth/password/change/',  change_password,       name='change-password-legacy'),

#     # --- 3. WEATHER ---
#     path('weather/latest/', LatestWeatherView.as_view(), name='latest-weather'),

#     # --- 4. CROP PROFILES ---
#     path('crop-profiles/', CropProfileView.as_view(), name='crop-profiles'),

#     # --- 5. ALERTS ---
#     path('alerts/',           FarmerAlertsView.as_view(), name='alerts'),
#     path('alerts/mark-read/', FarmerAlertsView.as_view(), name='mark-alerts-read'),

#     # --- 6. AI SCAN (8-Factor Engine) ---
#     path('save-scan/', SaveScanView.as_view(), name='save-scan'),

#     # --- 7. HISTORY & REPORTS ---
#     path('farmer-history/', FarmerHistoryView.as_view(), name='farmer-history'),
#     path('farmer-reports/', FarmerReportsView.as_view(), name='farmer-reports'),

#     # --- 8. MARKET PRICES ---
#     # GET /api/market-prices/                   -> all prices
#     # GET /api/market-prices/?district=Maseru   -> filtered by district
#     path('market-prices/', MarketPricesView.as_view(), name='market-prices'),

#     # --- 9. DIAGNOSIS FEEDBACK ---
#     path('diagnosis/<int:diagnosis_id>/feedback/', DiagnosisFeedbackView.as_view(), name='diagnosis-feedback'),

#     # --- 10. FARMER INSIGHTS ---
#     path('farmer-insight/', FarmerInsightView.as_view(), name='farmer-insight'),

#     # --- 11. GROWTH JOURNAL ---
#     path('journal/',                    GrowthJournalView.as_view(), name='journal'),
#     path('journal/<int:entry_id>/delete/', GrowthJournalView.as_view(), name='journal-delete'),
# ]

# api/urls.py  —  FarmAid Lesotho
# Changes: added google_auth + AlertCountView imports and paths

from django.urls import path
from .views import (
    # Auth
    register_farmer,
    login_farmer,
    google_auth,              # NEW — Google Sign-In
    resend_activation_email,
    activate_account,
    # Profile & Security
    ProfileView,
    change_password,
    # Core
    SaveScanView,
    FarmerHistoryView,
    FarmerReportsView,
    CropProfileView,
    # Alerts
    FarmerAlertsView,
    AlertCountView,           # NEW — bell icon badge endpoint
    # Data
    LatestWeatherView,
    MarketPricesView,
    DiagnosisFeedbackView,
    FarmerInsightView,
    GrowthJournalView,
)

urlpatterns = [

    # ── 1. AUTHENTICATION ──────────────────────────────────────────────────
    path('register/',                        register_farmer,         name='register'),
    path('login/',                           login_farmer,            name='login'),
    path('auth/google/',                     google_auth,             name='google-auth'),   # NEW
    path('resend-activation/',               resend_activation_email, name='resend-activation'),
    path('activate/<uidb64>/<token>/',       activate_account,        name='activate'),

    # ── 2. PROFILE & SECURITY ──────────────────────────────────────────────
    path('auth/profile/',                    ProfileView.as_view(),   name='profile-detail'),
    path('auth/profile/update/',             ProfileView.as_view(),   name='profile-update'),
    path('auth/profile/language/',           ProfileView.as_view(),   name='profile-language'),
    path('auth/change-password/',            change_password,         name='change-password'),
    path('auth/password/change/',            change_password,         name='change-password-legacy'),

    # ── 3. WEATHER ─────────────────────────────────────────────────────────
    path('weather/latest/',                  LatestWeatherView.as_view(), name='latest-weather'),

    # ── 4. CROP PROFILES ───────────────────────────────────────────────────
    path('crop-profiles/',                   CropProfileView.as_view(),   name='crop-profiles'),

    # ── 5. ALERTS ──────────────────────────────────────────────────────────
    path('alerts/',                          FarmerAlertsView.as_view(),  name='alerts'),
    path('alerts/mark-read/',                FarmerAlertsView.as_view(),  name='mark-alerts-read'),
    path('alerts/unread-count/',             AlertCountView.as_view(),    name='alerts-unread-count'),  # NEW

    # ── 6. AI SCAN ─────────────────────────────────────────────────────────
    path('save-scan/',                       SaveScanView.as_view(),      name='save-scan'),

    # ── 7. HISTORY & REPORTS ───────────────────────────────────────────────
    path('farmer-history/',                  FarmerHistoryView.as_view(), name='farmer-history'),
    path('farmer-reports/',                  FarmerReportsView.as_view(), name='farmer-reports'),

    # ── 8. MARKET PRICES ───────────────────────────────────────────────────
    path('market-prices/',                   MarketPricesView.as_view(),  name='market-prices'),

    # ── 9. DIAGNOSIS FEEDBACK ──────────────────────────────────────────────
    path('diagnosis/<int:diagnosis_id>/feedback/', DiagnosisFeedbackView.as_view(), name='diagnosis-feedback'),

    # ── 10. FARMER INSIGHTS ────────────────────────────────────────────────
    path('farmer-insight/',                  FarmerInsightView.as_view(), name='farmer-insight'),

    # ── 11. GROWTH JOURNAL ─────────────────────────────────────────────────
    path('journal/',                         GrowthJournalView.as_view(), name='journal'),
    path('journal/<int:entry_id>/delete/',   GrowthJournalView.as_view(), name='journal-delete'),
]
