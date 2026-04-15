# from django.contrib import admin
# from django.contrib.auth.admin import UserAdmin
# from django.utils.html import format_html
# from .models import (
#     Farmer, KnowledgeBase, AIModel, Diagnosis,
#     Treatment, TranslationCache,
#     CropProfile, Plant, AppAlert, WeatherData,
#     FarmerInsight, GrowthJournalEntry,
# )


# # ============================================================
# # --- 1. FARMER ---
# # ============================================================
# @admin.register(Farmer)
# class FarmerAdmin(UserAdmin):
#     list_display = (
#         'username', 'email', 'phone_number', 'district',
#         'experience_level', 'language_preferences',
#         'notification_diseases', 'notification_weather', 'notification_market',
#         'is_staff', 'is_superuser'
#     )
#     search_fields = ('username', 'email', 'district')
#     list_filter = ('is_staff', 'is_superuser', 'district', 'experience_level', 'language_preferences')

#     fieldsets = UserAdmin.fieldsets + (
#         ('FarmAid — Farmer Profile', {
#             'fields': (
#                 'phone_number', 'district', 'language_preferences',
#                 'profile_photo_url', 'farm_size_hectares', 'experience_level',
#             ),
#         }),
#         ('FarmAid — Notification Preferences', {
#             'fields': (
#                 'notification_diseases', 'notification_weather', 'notification_market',
#             ),
#         }),
#         ('FarmAid — App Status', {
#             'fields': ('onboarding_complete', 'last_active'),
#         }),
#     )

#     add_fieldsets = UserAdmin.add_fieldsets + (
#         ('FarmAid — Farmer Profile', {
#             'fields': (
#                 'email', 'phone_number', 'district',
#                 'language_preferences', 'experience_level',
#             ),
#         }),
#     )


# # ============================================================
# # --- 2. CROP PROFILE ---
# # ============================================================
# @admin.register(CropProfile)
# class CropProfileAdmin(admin.ModelAdmin):
#     list_display = (
#         'ProfileID', 'get_farmer', 'VegetableType', 'SoilEnvironment',
#         'irrigation_method', 'seed_variety', 'growth_stage', 'IsActive', 'PlantingDate'
#     )
#     list_filter = ('VegetableType', 'SoilEnvironment', 'irrigation_method', 'IsActive')
#     search_fields = ('VegetableType', 'seed_variety', 'FarmerID__username')

#     def get_farmer(self, obj):
#         return obj.FarmerID.username
#     get_farmer.short_description = 'Farmer'

#     def growth_stage(self, obj):
#         return obj.growth_stage_label
#     growth_stage.short_description = 'Growth Stage'


# # ============================================================
# # --- 3. PLANT ---
# # ============================================================
# @admin.register(Plant)
# class PlantAdmin(admin.ModelAdmin):
#     list_display = (
#         'PlantID', 'get_farmer', 'CropType', 'gps_district',
#         'latitude', 'longitude', 'altitude_meters', 'DateCaptured'
#     )
#     list_filter = ('CropType', 'gps_district')
#     search_fields = ('CropType', 'FarmerID__username', 'gps_district')

#     def get_farmer(self, obj):
#         return obj.FarmerID.username
#     get_farmer.short_description = 'Farmer'


# # ============================================================
# # --- 4. DIAGNOSIS ---
# # ============================================================
# @admin.register(Diagnosis)
# class DiagnosisAdmin(admin.ModelAdmin):
#     list_display = (
#         'DiagnosisID', 'get_farmer', 'DiseaseName', 'confidence_display',
#         'severity', 'farmer_feedback', 'treatment_applied',
#         'treatment_outcome', 'follow_up_date', 'DateDiagnosed'
#     )
#     list_filter = (
#         'DiseaseName', 'severity', 'farmer_feedback',
#         'treatment_applied', 'treatment_outcome', 'DateDiagnosed'
#     )
#     search_fields = ('DiseaseName', 'PlantID__FarmerID__username')

#     def get_farmer(self, obj):
#         return obj.PlantID.FarmerID.username
#     get_farmer.short_description = 'Farmer'

#     def confidence_display(self, obj):
#         pct = int(obj.ConfidenceLevel * 100)
#         color = 'green' if pct >= 75 else 'orange' if pct >= 50 else 'red'
#         return format_html('<b style="color:{}">{:.0f}%</b>', color, obj.ConfidenceLevel * 100)
#     confidence_display.short_description = 'Confidence'


# # ============================================================
# # --- 5. TREATMENT ---
# # ============================================================
# @admin.register(Treatment)
# class TreatmentAdmin(admin.ModelAdmin):
#     list_display = ('TreatmentID', 'DiseaseName', 'RecommendedPesticide', 'Dosage')
#     search_fields = ('DiseaseName', 'RecommendedPesticide')


# # ============================================================
# # --- 6. APP ALERT ---
# # ============================================================
# @admin.register(AppAlert)
# class AppAlertAdmin(admin.ModelAdmin):
#     list_display = (
#         'AlertID', 'get_farmer', 'alert_type', 'priority',
#         'Title', 'district_target', 'IsRead', 'expires_at', 'DateCreated'
#     )
#     list_filter = ('alert_type', 'priority', 'IsRead', 'district_target')
#     search_fields = ('Title', 'Message', 'FarmerID__username')

#     def get_farmer(self, obj):
#         return obj.FarmerID.username
#     get_farmer.short_description = 'Farmer'


# # ============================================================
# # --- 7. WEATHER DATA ---
# # ============================================================
# @admin.register(WeatherData)
# class WeatherDataAdmin(admin.ModelAdmin):
#     list_display = (
#         'WeatherID', 'district', 'Temperature', 'Humidity',
#         'Rainfall', 'rainfall_last_7_days', 'AlertMessage', 'DateUpdated'
#     )
#     list_filter = ('district',)
#     search_fields = ('district',)


# # ============================================================
# # --- 8. KNOWLEDGE BASE ---
# # ============================================================
# @admin.register(KnowledgeBase)
# class KnowledgeBaseAdmin(admin.ModelAdmin):
#     list_display = ('DiseaseName', 'LastUpdated')
#     search_fields = ('DiseaseName',)


# # ============================================================
# # --- 9. AI MODEL ---
# # ============================================================
# @admin.register(AIModel)
# class AIModelAdmin(admin.ModelAdmin):
#     list_display = ('ModelID', 'Version', 'AccuracyRate', 'LastTrainedDate')


# # ============================================================
# # --- 10. TRANSLATION CACHE ---
# # ============================================================
# @admin.register(TranslationCache)
# class TranslationCacheAdmin(admin.ModelAdmin):
#     list_display = ('disease_name_en', 'pesticide_st', 'dosage_st', 'last_updated')
#     search_fields = ('disease_name_en',)


# # ============================================================
# # --- 11. FARMER INSIGHT ---
# # ============================================================
# @admin.register(FarmerInsight)
# class FarmerInsightAdmin(admin.ModelAdmin):
#     list_display = (
#         'get_farmer', 'total_scans', 'total_diseases_detected',
#         'total_healthy_scans', 'most_scanned_crop', 'most_common_disease',
#         'streak_healthy_days', 'last_scan_date', 'last_updated'
#     )
#     search_fields = ('FarmerID__username',)
#     readonly_fields = (
#         'total_scans', 'total_diseases_detected', 'total_healthy_scans',
#         'most_scanned_crop', 'most_common_disease', 'highest_risk_month',
#         'last_scan_date', 'streak_healthy_days', 'last_updated'
#     )

#     def get_farmer(self, obj):
#         return obj.FarmerID.username
#     get_farmer.short_description = 'Farmer'


# # ============================================================
# # --- 12. GROWTH JOURNAL ---
# # ============================================================
# @admin.register(GrowthJournalEntry)
# class GrowthJournalEntryAdmin(admin.ModelAdmin):
#     list_display = (
#         'EntryID', 'get_farmer', 'get_crop', 'title',
#         'mood', 'entry_date', 'DateCreated'
#     )
#     list_filter = ('mood', 'entry_date')
#     search_fields = ('title', 'body', 'FarmerID__username')

#     def get_farmer(self, obj):
#         return obj.FarmerID.username
#     get_farmer.short_description = 'Farmer'

#     def get_crop(self, obj):
#         return obj.CropProfile.VegetableType
#     get_crop.short_description = 'Crop'




from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django.utils.html import format_html
from django.contrib.auth.models import Group

# Import auth models to unregister them
from allauth.account.models import EmailAddress
from allauth.socialaccount.models import SocialAccount, SocialToken, SocialApp

from .models import (
    Farmer, KnowledgeBase, AIModel, Diagnosis,
    Treatment, TranslationCache,
    CropProfile, Plant, AppAlert, WeatherData,
    FarmerInsight, GrowthJournalEntry,
)

# ============================================================
# --- 0. CUSTOM ADMIN SITE (THE "BLANK" DASHBOARD) ---
# ============================================================
class FarmAidAdminSite(admin.AdminSite):
    site_header = "FarmAid Lesotho Control Centre"
    site_title = "FarmAid Admin"
    index_title = "Welcome to the FarmAid Management System"

    def index(self, request, extra_context=None):
        """
        Overriding index to pass an empty app_list. 
        This prevents any category widgets (Api, Accounts, etc.) 
        from appearing on the dashboard landing page.
        """
        extra_context = extra_context or {}
        extra_context['app_list'] = []
        return super().index(request, extra_context=extra_context)

# Instantiate the custom site
admin_site = FarmAidAdminSite(name='farmaid_admin')

# Unregister default models from the standard admin (safety cleanup)
admin.site.unregister(Group)
admin.site.unregister(EmailAddress)
admin.site.unregister(SocialAccount)
admin.site.unregister(SocialToken)
admin.site.unregister(SocialApp)

# ============================================================
# --- 1. FARMER ---
# ============================================================
class FarmerAdmin(UserAdmin):
    list_display = (
        'username', 'email', 'phone_number', 'district',
        'experience_level', 'language_preferences',
        'notification_diseases', 'notification_weather', 'notification_market',
        'is_staff', 'is_superuser'
    )
    search_fields = ('username', 'email', 'district')
    list_filter = ('is_staff', 'is_superuser', 'district', 'experience_level', 'language_preferences')

    fieldsets = UserAdmin.fieldsets + (
        ('FarmAid — Farmer Profile', {
            'fields': (
                'phone_number', 'district', 'language_preferences',
                'profile_photo_url', 'farm_size_hectares', 'experience_level',
            ),
        }),
        ('FarmAid — Notification Preferences', {
            'fields': (
                'notification_diseases', 'notification_weather', 'notification_market',
            ),
        }),
        ('FarmAid — App Status', {
            'fields': ('onboarding_complete', 'last_active'),
        }),
    )

    add_fieldsets = UserAdmin.add_fieldsets + (
        ('FarmAid — Farmer Profile', {
            'fields': (
                'email', 'phone_number', 'district',
                'language_preferences', 'experience_level',
            ),
        }),
    )
admin_site.register(Farmer, FarmerAdmin)

# ============================================================
# --- 2. CROP PROFILE ---
# ============================================================
class CropProfileAdmin(admin.ModelAdmin):
    list_display = (
        'ProfileID', 'get_farmer', 'VegetableType', 'SoilEnvironment',
        'irrigation_method', 'seed_variety', 'growth_stage', 'IsActive', 'PlantingDate'
    )
    list_filter = ('VegetableType', 'SoilEnvironment', 'irrigation_method', 'IsActive')
    search_fields = ('VegetableType', 'seed_variety', 'FarmerID__username')

    def get_farmer(self, obj):
        return obj.FarmerID.username
    get_farmer.short_description = 'Farmer'

    def growth_stage(self, obj):
        return obj.growth_stage_label
    growth_stage.short_description = 'Growth Stage'
admin_site.register(CropProfile, CropProfileAdmin)

# ============================================================
# --- 3. PLANT ---
# ============================================================
class PlantAdmin(admin.ModelAdmin):
    list_display = (
        'PlantID', 'get_farmer', 'CropType', 'gps_district',
        'latitude', 'longitude', 'altitude_meters', 'DateCaptured'
    )
    list_filter = ('CropType', 'gps_district')
    search_fields = ('CropType', 'FarmerID__username', 'gps_district')

    def get_farmer(self, obj):
        return obj.FarmerID.username
    get_farmer.short_description = 'Farmer'
admin_site.register(Plant, PlantAdmin)

# ============================================================
# --- 4. DIAGNOSIS ---
# ============================================================
class DiagnosisAdmin(admin.ModelAdmin):
    list_display = (
        'DiagnosisID', 'get_farmer', 'DiseaseName', 'confidence_display',
        'severity', 'farmer_feedback', 'treatment_applied',
        'treatment_outcome', 'follow_up_date', 'DateDiagnosed'
    )
    list_filter = (
        'DiseaseName', 'severity', 'farmer_feedback',
        'treatment_applied', 'treatment_outcome', 'DateDiagnosed'
    )
    search_fields = ('DiseaseName', 'PlantID__FarmerID__username')

    def get_farmer(self, obj):
        return obj.PlantID.FarmerID.username
    get_farmer.short_description = 'Farmer'

    def confidence_display(self, obj):
        pct = int(obj.ConfidenceLevel * 100)
        color = 'green' if pct >= 75 else 'orange' if pct >= 50 else 'red'
        return format_html('<b style="color:{}">{:.0f}%</b>', color, obj.ConfidenceLevel * 100)
    confidence_display.short_description = 'Confidence'
admin_site.register(Diagnosis, DiagnosisAdmin)

# ============================================================
# --- 5. TREATMENT ---
# ============================================================
class TreatmentAdmin(admin.ModelAdmin):
    list_display = ('TreatmentID', 'DiseaseName', 'RecommendedPesticide', 'Dosage')
    search_fields = ('DiseaseName', 'RecommendedPesticide')
admin_site.register(Treatment, TreatmentAdmin)

# ============================================================
# --- 6. APP ALERT ---
# ============================================================
class AppAlertAdmin(admin.ModelAdmin):
    list_display = (
        'AlertID', 'get_farmer', 'alert_type', 'priority',
        'Title', 'district_target', 'IsRead', 'expires_at', 'DateCreated'
    )
    list_filter = ('alert_type', 'priority', 'IsRead', 'district_target')
    search_fields = ('Title', 'Message', 'FarmerID__username')

    def get_farmer(self, obj):
        return obj.FarmerID.username
    get_farmer.short_description = 'Farmer'
admin_site.register(AppAlert, AppAlertAdmin)

# ============================================================
# --- 7. WEATHER DATA ---
# ============================================================
class WeatherDataAdmin(admin.ModelAdmin):
    list_display = (
        'WeatherID', 'district', 'Temperature', 'Humidity',
        'Rainfall', 'rainfall_last_7_days', 'AlertMessage', 'DateUpdated'
    )
    list_filter = ('district',)
    search_fields = ('district',)
admin_site.register(WeatherData, WeatherDataAdmin)

# ============================================================
# --- 8. KNOWLEDGE BASE ---
# ============================================================
class KnowledgeBaseAdmin(admin.ModelAdmin):
    list_display = ('DiseaseName', 'LastUpdated')
    search_fields = ('DiseaseName',)
admin_site.register(KnowledgeBase, KnowledgeBaseAdmin)

# ============================================================
# --- 9. AI MODEL ---
# ============================================================
class AIModelAdmin(admin.ModelAdmin):
    list_display = ('ModelID', 'Version', 'AccuracyRate', 'LastTrainedDate')
admin_site.register(AIModel, AIModelAdmin)

# ============================================================
# --- 10. TRANSLATION CACHE ---
# ============================================================
class TranslationCacheAdmin(admin.ModelAdmin):
    list_display = ('disease_name_en', 'pesticide_st', 'dosage_st', 'last_updated')
    search_fields = ('disease_name_en',)
admin_site.register(TranslationCache, TranslationCacheAdmin)

# ============================================================
# --- 11. FARMER INSIGHT ---
# ============================================================
class FarmerInsightAdmin(admin.ModelAdmin):
    list_display = (
        'get_farmer', 'total_scans', 'total_diseases_detected',
        'total_healthy_scans', 'most_scanned_crop', 'most_common_disease',
        'streak_healthy_days', 'last_scan_date', 'last_updated'
    )
    search_fields = ('FarmerID__username',)
    readonly_fields = (
        'total_scans', 'total_diseases_detected', 'total_healthy_scans',
        'most_scanned_crop', 'most_common_disease', 'highest_risk_month',
        'last_scan_date', 'streak_healthy_days', 'last_updated'
    )

    def get_farmer(self, obj):
        return obj.FarmerID.username
    get_farmer.short_description = 'Farmer'
admin_site.register(FarmerInsight, FarmerInsightAdmin)

# ============================================================
# --- 12. GROWTH JOURNAL ---
# ============================================================
class GrowthJournalEntryAdmin(admin.ModelAdmin):
    list_display = (
        'EntryID', 'get_farmer', 'get_crop', 'title',
        'mood', 'entry_date', 'DateCreated'
    )
    list_filter = ('mood', 'entry_date')
    search_fields = ('title', 'body', 'FarmerID__username')

    def get_farmer(self, obj):
        return obj.FarmerID.username
    get_farmer.short_description = 'Farmer'

    def get_crop(self, obj):
        return obj.CropProfile.VegetableType
    get_crop.short_description = 'Crop'
admin_site.register(GrowthJournalEntry, GrowthJournalEntryAdmin)
