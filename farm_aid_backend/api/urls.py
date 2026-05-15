# from django.urls import path
# from .views import (
#     # Auth
#     register_farmer,
#     login_farmer,
#     google_auth,
#     resend_activation_email,
#     activate_account,
#     # Password Reset
#     request_password_reset,
#     reset_password_confirm,
#     reset_password_verify,
#     # Profile & Security
#     ProfileView,
#     change_password,
#     # Core
#     SaveScanView,
#     FarmerHistoryView,
#     FarmerReportsView,
#     CropProfileView,
#     # Alerts
#     FarmerAlertsView,
#     AlertCountView,
#     # Data
#     LatestWeatherView,
#     MarketPricesView,
#     DiagnosisFeedbackView,
#     FarmerInsightView,
#     GrowthJournalView,
#     # Community
#     get_community_posts,
#     create_community_post,
#     like_community_post,
#     delete_community_post,
#     get_community_comments,
#     add_community_comment,
#     get_community_profile,
#     # Insights & Trends
#     FarmerInsightsTrendsView,
#     # Admin Dashboard
#     FarmerListView,
#     TreatmentListView,
#     KnowledgeBaseListView,
#     DiagnosisListView,
#     PlantListView,
# )

# urlpatterns = [

#     # ── 1. AUTHENTICATION ──────────────────────────────────────────────────
#     path('register/',                        register_farmer,         name='register'),
#     path('login/',                           login_farmer,            name='login'),
#     path('auth/google/',                     google_auth,             name='google-auth'),
#     path('resend-activation/',               resend_activation_email, name='resend-activation'),
#     path('activate/<uidb64>/<token>/',       activate_account,        name='activate'),

#     # ── 2. PASSWORD RESET ──────────────────────────────────────────────────
#     path('auth/request-password-reset/',     request_password_reset,   name='request-password-reset'),
#     path('reset-password/<uidb64>/<token>/', reset_password_confirm,    name='reset-password-confirm'),
#     path('reset-password/verify/<uidb64>/<token>/', reset_password_verify, name='reset-password-verify'),

#     # ── 3. PROFILE & SECURITY ──────────────────────────────────────────────
#     path('auth/profile/',                    ProfileView.as_view(),   name='profile-detail'),
#     path('auth/profile/update/',             ProfileView.as_view(),   name='profile-update'),
#     path('auth/profile/language/',           ProfileView.as_view(),   name='profile-language'),
#     path('auth/change-password/',            change_password,         name='change-password'),
#     path('auth/password/change/',            change_password,         name='change-password-legacy'),

#     # ── 4. WEATHER ─────────────────────────────────────────────────────────
#     path('weather/latest/',                  LatestWeatherView.as_view(), name='latest-weather'),

#     # ── 5. CROP PROFILES ───────────────────────────────────────────────────
#     path('crop-profiles/',                   CropProfileView.as_view(),   name='crop-profiles'),

#     # ── 6. ALERTS ──────────────────────────────────────────────────────────
#     path('alerts/',                          FarmerAlertsView.as_view(),  name='alerts'),
#     path('alerts/mark-read/',                FarmerAlertsView.as_view(),  name='mark-alerts-read'),
#     path('alerts/unread-count/',             AlertCountView.as_view(),    name='alerts-unread-count'),

#     # ── 7. AI SCAN ─────────────────────────────────────────────────────────
#     path('save-scan/',                       SaveScanView.as_view(),      name='save-scan'),

#     # ── 8. HISTORY & REPORTS ───────────────────────────────────────────────
#     path('farmer-history/',                  FarmerHistoryView.as_view(), name='farmer-history'),
#     path('farmer-reports/',                  FarmerReportsView.as_view(), name='farmer-reports'),

#     # ── 9. MARKET PRICES ───────────────────────────────────────────────────
#     path('market-prices/',                   MarketPricesView.as_view(),  name='market-prices'),

#     # ── 10. DIAGNOSIS FEEDBACK ─────────────────────────────────────────────
#     path('diagnosis/<int:diagnosis_id>/feedback/', DiagnosisFeedbackView.as_view(), name='diagnosis-feedback'),

#     # ── 11. FARMER INSIGHTS ────────────────────────────────────────────────
#     path('farmer-insight/',                  FarmerInsightView.as_view(), name='farmer-insight'),

#     # ── 12. GROWTH JOURNAL ─────────────────────────────────────────────────
#     path('journal/',                         GrowthJournalView.as_view(), name='journal'),
#     path('journal/<int:entry_id>/delete/',   GrowthJournalView.as_view(), name='journal-delete'),

#     # ── 13. COMMUNITY ──────────────────────────────────────────────────────
#     path('community/posts/',                 get_community_posts,        name='community_posts'),
#     path('community/posts/create/',          create_community_post,      name='create_community_post'),
#     path('community/posts/<int:post_id>/like/', like_community_post,     name='like_community_post'),
#     path('community/posts/<int:post_id>/delete/', delete_community_post, name='delete_community_post'),
#     path('community/posts/<int:post_id>/comments/', get_community_comments, name='get_community_comments'),
#     path('community/posts/<int:post_id>/comments/add/', add_community_comment, name='add_community_comment'),
#     path('community/profile/',               get_community_profile,      name='community_profile'),

#     # ── 14. INSIGHTS & TRENDS ───────────────────────────────────────────────
#     path('insights-trends/',                 FarmerInsightsTrendsView.as_view(), name='insights-trends'),

#     # ── 15. ADMIN DASHBOARD ─────────────────────────────────────────────────
#     path('admin/farmers/',                   FarmerListView.as_view(),       name='admin-farmers'),
#     path('admin/treatments/',                TreatmentListView.as_view(),    name='admin-treatments'),
#     path('admin/knowledgebase/',             KnowledgeBaseListView.as_view(), name='admin-knowledgebase'),
#     path('admin/diagnoses/',                 DiagnosisListView.as_view(),    name='admin-diagnoses'),
#     path('admin/plants/',                    PlantListView.as_view(),        name='admin-plants'),
# ]

from django.urls import path
from .views import (
    # Auth
    register_farmer,
    login_farmer,
    google_auth,
    resend_activation_email,
    activate_account,
    # Password Reset
    request_password_reset,
    reset_password_confirm,
    reset_password_verify,
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
    AlertCountView,
    # Data
    LatestWeatherView,
    MarketPricesView,
    DiagnosisFeedbackView,
    FarmerInsightView,
    GrowthJournalView,
    # Community
    get_community_posts,
    create_community_post,
    like_community_post,
    delete_community_post,
    get_community_comments,
    add_community_comment,
    get_community_profile,
    # Insights & Trends
    FarmerInsightsTrendsView,
    # Admin Dashboard
    FarmerListView,
    TreatmentListView,
    KnowledgeBaseListView,
    DiagnosisListView,
    PlantListView,
    AdminDashboardStatsView,  # NEW IMPORT
)

urlpatterns = [

    # ── 1. AUTHENTICATION ──────────────────────────────────────────────────
    path('register/',                        register_farmer,         name='register'),
    path('login/',                           login_farmer,            name='login'),
    path('auth/google/',                     google_auth,             name='google-auth'),
    path('resend-activation/',               resend_activation_email, name='resend-activation'),
    path('activate/<uidb64>/<token>/',       activate_account,        name='activate'),

    # ── 2. PASSWORD RESET ──────────────────────────────────────────────────
    path('auth/request-password-reset/',     request_password_reset,   name='request-password-reset'),
    path('reset-password/<uidb64>/<token>/', reset_password_confirm,    name='reset-password-confirm'),
    path('reset-password/verify/<uidb64>/<token>/', reset_password_verify, name='reset-password-verify'),

    # ── 3. PROFILE & SECURITY ──────────────────────────────────────────────
    path('auth/profile/',                    ProfileView.as_view(),   name='profile-detail'),
    path('auth/profile/update/',             ProfileView.as_view(),   name='profile-update'),
    path('auth/profile/language/',           ProfileView.as_view(),   name='profile-language'),
    path('auth/change-password/',            change_password,         name='change-password'),
    path('auth/password/change/',            change_password,         name='change-password-legacy'),

    # ── 4. WEATHER ─────────────────────────────────────────────────────────
    path('weather/latest/',                  LatestWeatherView.as_view(), name='latest-weather'),

    # ── 5. CROP PROFILES ───────────────────────────────────────────────────
    path('crop-profiles/',                   CropProfileView.as_view(),   name='crop-profiles'),

    # ── 6. ALERTS ──────────────────────────────────────────────────────────
    path('alerts/',                          FarmerAlertsView.as_view(),  name='alerts'),
    path('alerts/mark-read/',                FarmerAlertsView.as_view(),  name='mark-alerts-read'),
    path('alerts/unread-count/',             AlertCountView.as_view(),    name='alerts-unread-count'),

    # ── 7. AI SCAN ─────────────────────────────────────────────────────────
    path('save-scan/',                       SaveScanView.as_view(),      name='save-scan'),

    # ── 8. HISTORY & REPORTS ───────────────────────────────────────────────
    path('farmer-history/',                  FarmerHistoryView.as_view(), name='farmer-history'),
    path('farmer-reports/',                  FarmerReportsView.as_view(), name='farmer-reports'),

    # ── 9. MARKET PRICES ───────────────────────────────────────────────────
    path('market-prices/',                   MarketPricesView.as_view(),  name='market-prices'),

    # ── 10. DIAGNOSIS FEEDBACK ─────────────────────────────────────────────
    path('diagnosis/<int:diagnosis_id>/feedback/', DiagnosisFeedbackView.as_view(), name='diagnosis-feedback'),

    # ── 11. FARMER INSIGHTS ────────────────────────────────────────────────
    path('farmer-insight/',                  FarmerInsightView.as_view(), name='farmer-insight'),

    # ── 12. GROWTH JOURNAL ─────────────────────────────────────────────────
    path('journal/',                         GrowthJournalView.as_view(), name='journal'),
    path('journal/<int:entry_id>/delete/',   GrowthJournalView.as_view(), name='journal-delete'),

    # ── 13. COMMUNITY ──────────────────────────────────────────────────────
    path('community/posts/',                 get_community_posts,        name='community_posts'),
    path('community/posts/create/',          create_community_post,      name='create_community_post'),
    path('community/posts/<int:post_id>/like/', like_community_post,     name='like_community_post'),
    path('community/posts/<int:post_id>/delete/', delete_community_post, name='delete_community_post'),
    path('community/posts/<int:post_id>/comments/', get_community_comments, name='get_community_comments'),
    path('community/posts/<int:post_id>/comments/add/', add_community_comment, name='add_community_comment'),
    path('community/profile/',               get_community_profile,      name='community_profile'),

    # ── 14. INSIGHTS & TRENDS ───────────────────────────────────────────────
    path('insights-trends/',                 FarmerInsightsTrendsView.as_view(), name='insights-trends'),

    # ── 15. ADMIN DASHBOARD ─────────────────────────────────────────────────
    path('admin/farmers/',                   FarmerListView.as_view(),       name='admin-farmers'),
    path('admin/treatments/',                TreatmentListView.as_view(),    name='admin-treatments'),
    path('admin/knowledgebase/',             KnowledgeBaseListView.as_view(), name='admin-knowledgebase'),
    path('admin/diagnoses/',                 DiagnosisListView.as_view(),    name='admin-diagnoses'),
    path('admin/plants/',                    PlantListView.as_view(),        name='admin-plants'),
    path('admin/dashboard-stats/',           AdminDashboardStatsView.as_view(), name='admin-dashboard-stats'),  # NEW ENDPOINT
]
