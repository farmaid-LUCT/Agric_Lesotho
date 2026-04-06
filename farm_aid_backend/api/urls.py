from django.urls import path
from .views import (
    # Auth
    register_farmer,
    login_farmer,
    google_auth,
    resend_activation_email,
    activate_account,
    password_reset_request,
    # Profile & Security
    ProfileView,
    change_password,
    # Core
    SaveScanView,
    ScanImageView,            # ← NEW — server-side inference for Flutter web
    FarmerHistoryView,
    FarmerReportsView,
    CropProfileView,
    # Alerts
    FarmerAlertsView,
    AlertCountView,
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
    path('auth/google/',                     google_auth,             name='google-auth'),
    path('resend-activation/',               resend_activation_email, name='resend-activation'),
    path('activate/<uidb64>/<token>/',       activate_account,        name='activate'),
    path('auth/password-reset/',             password_reset_request,  name='password-reset'),

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
    path('alerts/unread-count/',             AlertCountView.as_view(),    name='alerts-unread-count'),

    # ── 6. AI SCAN ─────────────────────────────────────────────────────────
    path('save-scan/',                       SaveScanView.as_view(),      name='save-scan'),
    path('scan-image/',                      ScanImageView.as_view(),     name='scan-image'),   # ← NEW

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
