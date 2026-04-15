# from django.contrib import admin
# from django.contrib.auth.admin import UserAdmin
# from django.utils.html import format_html
# from .models import (
#     Farmer, KnowledgeBase, AIModel, Diagnosis,
#     Treatment, PersonalizedRule, TranslationCache,
#     CropProfile, Plant, AppAlert, WeatherData,
#     FarmerInsight, GrowthJournalEntry, MarketPrice,
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
# # --- 11. PERSONALIZED RULE ENGINE ---
# # ============================================================
# @admin.register(PersonalizedRule)
# class PersonalizedRuleAdmin(admin.ModelAdmin):
#     list_display = (
#         'RuleID', 'DiseaseName', 'TriggerDistrict', 'TriggerSoilType',
#         'TriggerIrrigation', 'TriggerCropVariety', 'TriggerSeason',
#         'TriggerRainfallLevel', 'growth_stage_range',
#         'RecommendationCategory', 'priority_score', 'short_advice'
#     )
#     list_filter = (
#         'DiseaseName', 'TriggerDistrict', 'TriggerSoilType',
#         'TriggerIrrigation', 'TriggerSeason', 'TriggerRainfallLevel',
#         'RecommendationCategory',
#     )
#     search_fields = ('DiseaseName', 'ExpertAdvice', 'TriggerCropVariety')
#     ordering = ('-priority_score',)

#     fieldsets = (
#         ('🔍 Disease Trigger (Required)', {
#             'fields': ('DiseaseName',),
#         }),
#         ('📍 Context Triggers — leave blank to match ALL values', {
#             'fields': (
#                 'TriggerDistrict', 'TriggerSoilType', 'TriggerIrrigation',
#                 'TriggerCropVariety', 'TriggerSeason', 'TriggerRainfallLevel',
#             ),
#         }),
#         ('🌿 Growth Stage Window', {
#             'fields': ('MinDaysSincePlanting', 'MaxDaysSincePlanting'),
#             'description': 'Rule only fires when days since planting falls within this range.',
#         }),
#         ('💡 Expert Advice Output', {
#             'fields': (
#                 'ExpertAdvice', 'advice_beginner',
#                 'RecommendationCategory', 'priority_score',
#             ),
#         }),
#     )

#     def growth_stage_range(self, obj):
#         return f"Day {obj.MinDaysSincePlanting} – {obj.MaxDaysSincePlanting}"
#     growth_stage_range.short_description = 'Growth Stage (Days)'

#     def short_advice(self, obj):
#         return f"{obj.ExpertAdvice[:60]}..." if len(obj.ExpertAdvice) > 60 else obj.ExpertAdvice
#     short_advice.short_description = 'Advice Preview'


# # ============================================================
# # --- 12. FARMER INSIGHT ---
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
# # --- 13. GROWTH JOURNAL ---
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


# # ============================================================
# # --- 14. MARKET PRICE ---
# # ============================================================
# @admin.register(MarketPrice)
# class MarketPriceAdmin(admin.ModelAdmin):
#     list_display = (
#         'PriceID', 'vegetable_name', 'market_name', 'district',
#         'price_per_kg', 'currency', 'price_trend', 'date_recorded'
#     )
#     list_filter = ('vegetable_name', 'district', 'price_trend')
#     search_fields = ('vegetable_name', 'market_name', 'district')
#     ordering = ('-date_recorded',)



from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django.utils.html import format_html
from .models import (
    Farmer, KnowledgeBase, AIModel, Diagnosis,
    Treatment, TranslationCache,
    CropProfile, Plant, AppAlert, WeatherData,
    FarmerInsight, GrowthJournalEntry,
)


# ============================================================
# --- 1. FARMER ---
# ============================================================
@admin.register(Farmer)
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


# ============================================================
# --- 2. CROP PROFILE ---
# ============================================================
@admin.register(CropProfile)
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


# ============================================================
# --- 3. PLANT ---
# ============================================================
@admin.register(Plant)
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


# ============================================================
# --- 4. DIAGNOSIS ---
# ============================================================
@admin.register(Diagnosis)
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


# ============================================================
# --- 5. TREATMENT ---
# ============================================================
@admin.register(Treatment)
class TreatmentAdmin(admin.ModelAdmin):
    list_display = ('TreatmentID', 'DiseaseName', 'RecommendedPesticide', 'Dosage')
    search_fields = ('DiseaseName', 'RecommendedPesticide')


# ============================================================
# --- 6. APP ALERT ---
# ============================================================
@admin.register(AppAlert)
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


# ============================================================
# --- 7. WEATHER DATA ---
# ============================================================
@admin.register(WeatherData)
class WeatherDataAdmin(admin.ModelAdmin):
    list_display = (
        'WeatherID', 'district', 'Temperature', 'Humidity',
        'Rainfall', 'rainfall_last_7_days', 'AlertMessage', 'DateUpdated'
    )
    list_filter = ('district',)
    search_fields = ('district',)


# ============================================================
# --- 8. KNOWLEDGE BASE ---
# ============================================================
@admin.register(KnowledgeBase)
class KnowledgeBaseAdmin(admin.ModelAdmin):
    list_display = ('DiseaseName', 'LastUpdated')
    search_fields = ('DiseaseName',)


# ============================================================
# --- 9. AI MODEL ---
# ============================================================
@admin.register(AIModel)
class AIModelAdmin(admin.ModelAdmin):
    list_display = ('ModelID', 'Version', 'AccuracyRate', 'LastTrainedDate')


# ============================================================
# --- 10. TRANSLATION CACHE ---
# ============================================================
@admin.register(TranslationCache)
class TranslationCacheAdmin(admin.ModelAdmin):
    list_display = ('disease_name_en', 'pesticide_st', 'dosage_st', 'last_updated')
    search_fields = ('disease_name_en',)


# ============================================================
# --- 11. FARMER INSIGHT ---
# ============================================================
@admin.register(FarmerInsight)
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


# ============================================================
# --- 12. GROWTH JOURNAL ---
# ============================================================
@admin.register(GrowthJournalEntry)
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
