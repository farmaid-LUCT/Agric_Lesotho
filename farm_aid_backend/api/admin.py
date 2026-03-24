# import hashlib
# from django.db import models
# from django import forms
# from django.contrib import admin
# from django.contrib.auth.admin import UserAdmin
# from django.utils.html import format_html
# from django.contrib.admin.models import LogEntry, ADDITION, CHANGE, DELETION
# from .models import (
#     Farmer, KnowledgeBase, AIModel, Diagnosis, 
#     Treatment, PersonalizedRule, TranslationCache,
#     CropProfile, Plant, AppAlert, WeatherData
# )

# # --- HELPER: MONITOR ONLY MIXIN ---
# class MonitorOnlyAdmin(admin.ModelAdmin):
#     """Prevents Admin from adding, changing, or deleting records for automated tables."""
#     def has_add_permission(self, request): return False
#     def has_change_permission(self, request, obj=None): return False
#     def has_delete_permission(self, request, obj=None): return False

# # --- CUSTOM FORM: TRANSLATION CACHE (REFACTORED) ---
# class TranslationCacheForm(forms.ModelForm):
#     """
#     Refactored form to allow Admin to select a Disease and 
#     provide specific Sesotho treatment details.
#     """
#     disease_name_en = forms.ChoiceField(
#         choices=[], 
#         label="SELECT DISEASE NAME (English Key)",
#         help_text="Choose the disease that needs Sesotho translation."
#     )

#     class Meta:
#         model = TranslationCache
#         fields = ['disease_name_en', 'pesticide_st', 'dosage_st', 'steps_st']
#         widgets = {
#             'pesticide_st': forms.TextInput(attrs={'placeholder': 'Lebitso la moriana ka Sesotho...'}),
#             'dosage_st': forms.TextInput(attrs={'placeholder': 'Tekanyetso ka Sesotho...'}),
#             'steps_st': forms.Textarea(attrs={'rows': 4, 'placeholder': 'Mehato ea tšebeliso ka Sesotho...'}),
#         }

#     def __init__(self, *args, **kwargs):
#         super().__init__(*args, **kwargs)
#         # Pulling disease names from KnowledgeBase for the dropdown key
#         diseases = [('', '--- Select Disease ---')] + list(
#             KnowledgeBase.objects.values_list('DiseaseName', 'DiseaseName').distinct()
#         )
#         self.fields['disease_name_en'].choices = diseases

# # --- 1. ADMIN ACTIVITY LOG ---
# @admin.register(LogEntry)
# class LogEntryAdmin(admin.ModelAdmin):
#     list_display = ('action_time', 'user', 'content_type', 'object_repr', 'action_flag_tag')
#     list_filter = ('action_flag', 'user', 'content_type')
#     search_fields = ('object_repr', 'change_message')
#     def has_add_permission(self, request): return False
#     def has_delete_permission(self, request, obj=None): return True

#     def action_flag_tag(self, obj):
#         colors = {ADDITION: "#28a745", CHANGE: "#ffc107", DELETION: "#dc3545"}
#         labels = {ADDITION: "ADDED", CHANGE: "CHANGED", DELETION: "DELETED"}
#         return format_html(
#             '<span style="background-color: {}; color: white; padding: 2px 8px; border-radius: 5px; font-weight: bold; font-size: 11px;">{}</span>',
#             colors.get(obj.action_flag, "#6c757d"), labels.get(obj.action_flag, "UNKNOWN")
#         )

# # --- 2. FULL CRUD TABLES (Admin Managed) ---

# @admin.register(TranslationCache)
# class TranslationCacheAdmin(admin.ModelAdmin):
#     form = TranslationCacheForm
#     list_display = ('disease_name_en', 'pesticide_st', 'dosage_st', 'last_updated', 'status_tag')
#     search_fields = ('disease_name_en', 'pesticide_st')
#     readonly_fields = ('last_updated',)

#     def status_tag(self, obj):
#         if not obj.pesticide_st or not obj.steps_st:
#             return format_html('<b style="color: #dc3545;">Incomplete</b>')
#         return format_html('<b style="color: #28a745;">Translated</b>')
#     status_tag.short_description = "Status"

# @admin.register(AIModel)
# class AIModelAdmin(admin.ModelAdmin):
#     list_display = ('Version', 'accuracy_rate_bar', 'LastTrainedDate')
#     def accuracy_rate_bar(self, obj):
#         return format_html(
#             '<div style="width:100px;background:#f1f1f1;border-radius:5px;display:inline-block;vertical-align:middle;">'
#             '<div style="width:{}%;background:#2e7d32;height:10px;border-radius:5px;"></div></div>'
#             '<span style="margin-left:5px;">{}%</span>', obj.AccuracyRate, obj.AccuracyRate)
#     accuracy_rate_bar.short_description = 'Accuracy'

# @admin.register(Treatment)
# class TreatmentAdmin(admin.ModelAdmin):
#     list_display = ('DiseaseName', 'pesticide_tag', 'Dosage')
#     search_fields = ('DiseaseName', 'RecommendedPesticide')
#     def pesticide_tag(self, obj):
#         return format_html('<code style="color: #c7254e; background: #f9f2f4; padding: 2px 4px;">{}</code>', obj.RecommendedPesticide)

# @admin.register(KnowledgeBase)
# class KnowledgeBaseAdmin(admin.ModelAdmin):
#     list_display = ('DiseaseName', 'LastUpdated')

# @admin.register(Farmer)
# class FarmerAdmin(UserAdmin):
#     list_display = ('username', 'email', 'phone_number', 'location', 'lang_badge', 'account_status')
#     fieldsets = UserAdmin.fieldsets + (('FarmAid Custom', {'fields': ('phone_number', 'location', 'language_preferences')}),)
#     def lang_badge(self, obj):
#         color = "#007bff" if obj.language_preferences == 'en' else "#6f42c1"
#         return format_html('<span style="color: white; background: {}; padding: 2px 6px; border-radius: 4px;">{}</span>', color, obj.language_preferences.upper())
#     def account_status(self, obj):
#         color = "green" if obj.is_active else "red"
#         return format_html('<b style="color: {};">{}</b>', color, "ACTIVE" if obj.is_active else "LOCKED")

# # --- 3. MONITOR ONLY TABLES ---

# @admin.register(Plant)
# class PlantAdmin(MonitorOnlyAdmin):
#     list_display = ('PlantID', 'FarmerID', 'CropType', 'DateCaptured', 'view_image_link')
#     def view_image_link(self, obj):
#         return format_html('<a href="{}" target="_blank">View Photo</a>', obj.ImageFile) if obj.ImageFile else "No Image"

# @admin.register(AppAlert)
# class AppAlertAdmin(MonitorOnlyAdmin):
#     list_display = ('Title', 'FarmerID', 'alert_type', 'IsRead', 'DateCreated')

# @admin.register(Diagnosis)
# class DiagnosisAdmin(MonitorOnlyAdmin):
#     list_display = ('DiagnosisID', 'DiseaseName', 'ConfidenceLevel', 'DateDiagnosed')

# @admin.register(WeatherData)
# class WeatherDataAdmin(MonitorOnlyAdmin):
#     list_display = ('DateUpdated', 'Temperature', 'Humidity', 'Rainfall')

# @admin.register(CropProfile)
# class CropProfileAdmin(MonitorOnlyAdmin):
#     list_display = ('VegetableType', 'FarmerID', 'FarmLocation', 'IsActive')

# @admin.register(PersonalizedRule)
# class PersonalizedRuleAdmin(admin.ModelAdmin):
#     list_display = ('DiseaseName', 'RecommendationCategory', 'ExpertAdvice')

from django.contrib        import admin
from django.contrib.auth.admin import UserAdmin
from django.utils.html     import format_html
from .models import (
    Farmer, KnowledgeBase, AIModel, Diagnosis,
    Treatment, PersonalizedRule, TranslationCache,
    CropProfile, Plant, AppAlert, WeatherData,
    FarmerInsight, GrowthJournalEntry, MarketPrice,
)

# ── Shared badge helpers ───────────────────────────────────────────────────
def _badge(text, bg, fg='#fff'):
    return format_html(
        '<span style="background:{};color:{};padding:2px 10px;'
        'border-radius:10px;font-size:11px;font-weight:600">{}</span>',
        bg, fg, text)

def any_label():
    return format_html('<span style="color:#bbb;font-size:11px">Any</span>')

def conf_bar(level):
    pct   = int((level or 0) * 100)
    color = '#1B5E20' if pct >= 75 else '#F57F17' if pct >= 50 else '#B71C1C'
    return format_html(
        '<div style="width:80px;background:#eee;border-radius:4px;height:14px">'
        '<div style="width:{}%;background:{};border-radius:4px;height:14px;'
        'text-align:center;color:#fff;font-size:10px;line-height:14px">'
        '{}%</div></div>', pct, color, pct)


# ============================================================
# 1. FARMER
# ============================================================
@admin.register(Farmer)
class FarmerAdmin(UserAdmin):
    list_display = (
        'username', 'email', 'phone_number', 'district',
        'experience_badge', 'language_preferences',
        'notification_diseases', 'notification_weather', 'notification_market',
        'is_active_badge', 'is_staff', 'is_superuser',
    )
    search_fields = ('username', 'email', 'district')
    list_filter   = ('is_staff', 'is_superuser', 'is_active',
                     'district', 'experience_level', 'language_preferences')
    ordering      = ('-date_joined',)
    list_per_page = 25
    date_hierarchy = 'date_joined'

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

    def experience_badge(self, obj):
        colours = {'beginner': '#388E3C', 'intermediate': '#F57F17', 'expert': '#1565C0'}
        c = colours.get(obj.experience_level, '#555')
        return _badge(obj.experience_level or '—', c)
    experience_badge.short_description = 'Level'

    def is_active_badge(self, obj):
        return _badge('Active', '#1B5E20') if obj.is_active else _badge('Inactive', '#B71C1C')
    is_active_badge.short_description = 'Status'


# ============================================================
# 2. CROP PROFILE
# ============================================================
@admin.register(CropProfile)
class CropProfileAdmin(admin.ModelAdmin):
    list_display  = (
        'ProfileID', 'get_farmer', 'VegetableType', 'SoilEnvironment',
        'irrigation_method', 'seed_variety', 'growth_stage', 'is_active_badge', 'PlantingDate',
    )
    list_filter   = ('VegetableType', 'SoilEnvironment', 'irrigation_method', 'IsActive')
    search_fields = ('VegetableType', 'seed_variety', 'FarmerID__username')
    ordering      = ('-PlantingDate',)
    list_per_page = 30

    def get_farmer(self, obj):
        return obj.FarmerID.username
    get_farmer.short_description = 'Farmer'

    def growth_stage(self, obj):
        return obj.growth_stage_label
    growth_stage.short_description = 'Growth Stage'

    def is_active_badge(self, obj):
        return _badge('Active', '#1B5E20') if obj.IsActive else _badge('Inactive', '#555')
    is_active_badge.short_description = 'Active'


# ============================================================
# 3. PLANT
# ============================================================
@admin.register(Plant)
class PlantAdmin(admin.ModelAdmin):
    list_display  = (
        'PlantID', 'get_farmer', 'CropType', 'gps_district',
        'latitude', 'longitude', 'altitude_meters', 'image_link', 'DateCaptured',
    )
    list_filter   = ('CropType', 'gps_district')
    search_fields = ('CropType', 'FarmerID__username', 'gps_district')
    ordering      = ('-DateCaptured',)
    list_per_page = 30
    date_hierarchy = 'DateCaptured'

    def get_farmer(self, obj):
        return obj.FarmerID.username
    get_farmer.short_description = 'Farmer'

    def image_link(self, obj):
        if obj.ImageURL:
            return format_html(
                '<a href="{}" target="_blank" style="color:#1B5E20;font-weight:600">View ↗</a>',
                obj.ImageURL)
        return '—'
    image_link.short_description = 'Image'


# ============================================================
# 4. DIAGNOSIS
# ============================================================
@admin.register(Diagnosis)
class DiagnosisAdmin(admin.ModelAdmin):
    list_display = (
        'DiagnosisID', 'get_farmer', 'disease_badge',
        'confidence_display', 'severity', 'farmer_feedback',
        'treatment_applied', 'treatment_outcome',
        'follow_up_date', 'DateDiagnosed',
    )
    list_filter  = (
        'DiseaseName', 'severity', 'farmer_feedback',
        'treatment_applied', 'treatment_outcome', 'DateDiagnosed',
    )
    search_fields = ('DiseaseName', 'PlantID__FarmerID__username')
    ordering      = ('-DateDiagnosed',)
    list_per_page = 30
    date_hierarchy = 'DateDiagnosed'

    def get_farmer(self, obj):
        return obj.PlantID.FarmerID.username
    get_farmer.short_description = 'Farmer'

    def disease_badge(self, obj):
        name = obj.DiseaseName.replace('_', ' ')
        return _badge(name, '#1B5E20') if 'healthy' in name.lower() else _badge(name, '#B71C1C')
    disease_badge.short_description = 'Disease'

    def confidence_display(self, obj):
        return conf_bar(obj.ConfidenceLevel)
    confidence_display.short_description = 'Confidence'


# ============================================================
# 5. TREATMENT
# ============================================================
@admin.register(Treatment)
class TreatmentAdmin(admin.ModelAdmin):
    list_display  = ('TreatmentID', 'DiseaseName', 'RecommendedPesticide', 'Dosage')
    search_fields = ('DiseaseName', 'RecommendedPesticide')
    list_filter   = ('DiseaseName',)
    ordering      = ('DiseaseName',)
    list_per_page = 30


# ============================================================
# 6. APP ALERT
# ============================================================
@admin.register(AppAlert)
class AppAlertAdmin(admin.ModelAdmin):
    list_display  = (
        'AlertID', 'get_farmer', 'alert_type', 'priority',
        'Title', 'district_target', 'is_read_badge', 'expires_at', 'DateCreated',
    )
    list_filter   = ('alert_type', 'priority', 'IsRead', 'district_target')
    search_fields = ('Title', 'Message', 'FarmerID__username')
    ordering      = ('-DateCreated',)
    list_per_page = 30
    date_hierarchy = 'DateCreated'
    actions       = ['mark_read']

    def get_farmer(self, obj):
        return obj.FarmerID.username if obj.FarmerID else '(broadcast)'
    get_farmer.short_description = 'Farmer'

    def is_read_badge(self, obj):
        return _badge('Read', '#1B5E20') if obj.IsRead else _badge('Unread', '#E65100')
    is_read_badge.short_description = 'Status'

    @admin.action(description='✅ Mark selected alerts as read')
    def mark_read(self, request, queryset):
        n = queryset.update(IsRead=True)
        self.message_user(request, f'{n} alert(s) marked as read.')


# ============================================================
# 7. WEATHER DATA
# ============================================================
@admin.register(WeatherData)
class WeatherDataAdmin(admin.ModelAdmin):
    list_display  = (
        'WeatherID', 'district', 'Temperature', 'Humidity',
        'Rainfall', 'rainfall_last_7_days', 'AlertMessage', 'DateUpdated',
    )
    list_filter   = ('district',)
    search_fields = ('district',)
    ordering      = ('-DateUpdated',)
    list_per_page = 30


# ============================================================
# 8. KNOWLEDGE BASE
# ============================================================
@admin.register(KnowledgeBase)
class KnowledgeBaseAdmin(admin.ModelAdmin):
    list_display  = ('DiseaseName', 'short_symptoms', 'short_prevention', 'LastUpdated')
    search_fields = ('DiseaseName', 'Symptoms', 'Prevention')
    ordering      = ('DiseaseName',)
    list_per_page = 30

    def short_symptoms(self, obj):
        t = obj.Symptoms or ''
        return (t[:65] + '…') if len(t) > 65 else t
    short_symptoms.short_description = 'Symptoms'

    def short_prevention(self, obj):
        t = obj.Prevention or ''
        return (t[:65] + '…') if len(t) > 65 else t
    short_prevention.short_description = 'Prevention'


# ============================================================
# 9. AI MODEL
# ============================================================
@admin.register(AIModel)
class AIModelAdmin(admin.ModelAdmin):
    list_display  = ('ModelID', 'Version', 'accuracy_bar', 'LastTrainedDate')
    ordering      = ('-LastTrainedDate',)
    list_per_page = 20

    def accuracy_bar(self, obj):
        return conf_bar(obj.AccuracyRate)
    accuracy_bar.short_description = 'Accuracy'


# ============================================================
# 10. TRANSLATION CACHE
# ============================================================
@admin.register(TranslationCache)
class TranslationCacheAdmin(admin.ModelAdmin):
    list_display  = ('disease_name_en', 'pesticide_st', 'dosage_st', 'last_updated')
    search_fields = ('disease_name_en',)
    ordering      = ('disease_name_en',)
    list_per_page = 30


# ============================================================
# 11. PERSONALIZED RULE ENGINE
# ============================================================
@admin.register(PersonalizedRule)
class PersonalizedRuleAdmin(admin.ModelAdmin):
    list_display  = (
        'RuleID', 'DiseaseName', 'district_badge', 'soil_badge',
        'irrigation_badge', 'TriggerCropVariety', 'season_badge',
        'rainfall_badge', 'growth_stage_range',
        'RecommendationCategory', 'priority_score', 'short_advice',
    )
    list_filter   = (
        'DiseaseName', 'TriggerDistrict', 'TriggerSoilType',
        'TriggerIrrigation', 'TriggerSeason', 'TriggerRainfallLevel',
        'RecommendationCategory',
    )
    search_fields = ('DiseaseName', 'ExpertAdvice', 'TriggerCropVariety')
    ordering      = ('-priority_score',)
    list_per_page = 30

    fieldsets = (
        ('🔍 Disease Trigger (Required)', {
            'fields': ('DiseaseName',),
        }),
        ('📍 Context Triggers — leave blank to match ALL values', {
            'fields': (
                'TriggerDistrict', 'TriggerSoilType', 'TriggerIrrigation',
                'TriggerCropVariety', 'TriggerSeason', 'TriggerRainfallLevel',
            ),
        }),
        ('🌿 Growth Stage Window', {
            'fields': ('MinDaysSincePlanting', 'MaxDaysSincePlanting'),
            'description': 'Rule only fires when days since planting falls within this range.',
        }),
        ('💡 Expert Advice Output', {
            'fields': (
                'ExpertAdvice', 'advice_beginner',
                'RecommendationCategory', 'priority_score',
            ),
        }),
    )

    def district_badge(self, obj):
        return _badge(obj.TriggerDistrict, '#1B5E20') if obj.TriggerDistrict else any_label()
    district_badge.short_description = 'District'

    def soil_badge(self, obj):
        return _badge(obj.TriggerSoilType, '#E65100') if obj.TriggerSoilType else any_label()
    soil_badge.short_description = 'Soil'

    def irrigation_badge(self, obj):
        return _badge(obj.TriggerIrrigation, '#1565C0') if obj.TriggerIrrigation else any_label()
    irrigation_badge.short_description = 'Irrigation'

    def season_badge(self, obj):
        v = obj.TriggerSeason
        return _badge(v, '#1B5E20') if v and v != 'any' else any_label()
    season_badge.short_description = 'Season'

    def rainfall_badge(self, obj):
        v = obj.TriggerRainfallLevel
        return _badge(v, '#1565C0') if v and v != 'any' else any_label()
    rainfall_badge.short_description = 'Rainfall'

    def growth_stage_range(self, obj):
        mn = obj.MinDaysSincePlanting or 0
        mx = obj.MaxDaysSincePlanting or 999
        if mn == 0 and mx == 999:
            return any_label()
        return format_html('<span style="font-size:12px">Day {} – {}</span>', mn, mx)
    growth_stage_range.short_description = 'Growth Stage (Days)'

    def short_advice(self, obj):
        t = obj.ExpertAdvice or ''
        return (t[:60] + '…') if len(t) > 60 else t
    short_advice.short_description = 'Advice Preview'


# ============================================================
# 12. FARMER INSIGHT
# ============================================================
@admin.register(FarmerInsight)
class FarmerInsightAdmin(admin.ModelAdmin):
    list_display   = (
        'get_farmer', 'total_scans', 'total_diseases_detected',
        'total_healthy_scans', 'most_scanned_crop', 'most_common_disease',
        'streak_healthy_days', 'last_scan_date', 'last_updated',
    )
    search_fields  = ('FarmerID__username',)
    readonly_fields = (
        'total_scans', 'total_diseases_detected', 'total_healthy_scans',
        'most_scanned_crop', 'most_common_disease', 'highest_risk_month',
        'last_scan_date', 'streak_healthy_days', 'last_updated',
    )
    list_per_page  = 30

    def get_farmer(self, obj):
        return obj.FarmerID.username
    get_farmer.short_description = 'Farmer'


# ============================================================
# 13. GROWTH JOURNAL
# ============================================================
@admin.register(GrowthJournalEntry)
class GrowthJournalEntryAdmin(admin.ModelAdmin):
    list_display  = (
        'EntryID', 'get_farmer', 'get_crop',
        'title', 'mood_badge', 'entry_date', 'DateCreated',
    )
    list_filter   = ('mood', 'entry_date')
    search_fields = ('title', 'body', 'FarmerID__username')
    ordering      = ('-DateCreated',)
    list_per_page = 30

    def get_farmer(self, obj):
        return obj.FarmerID.username
    get_farmer.short_description = 'Farmer'

    def get_crop(self, obj):
        return obj.CropProfile.VegetableType
    get_crop.short_description = 'Crop'

    def mood_badge(self, obj):
        colours = {
            'great': '#1B5E20', 'good': '#388E3C',
            'okay':  '#F57F17', 'bad':  '#B71C1C', 'terrible': '#880E4F',
        }
        m = (obj.mood or '').lower()
        return _badge(obj.mood, colours.get(m, '#555')) if obj.mood else format_html(
            '<span style="color:#bbb">—</span>')
    mood_badge.short_description = 'Mood'


# ============================================================
# 14. MARKET PRICE
# ============================================================
@admin.register(MarketPrice)
class MarketPriceAdmin(admin.ModelAdmin):
    list_display  = (
        'PriceID', 'vegetable_name', 'market_name', 'district',
        'price_per_kg', 'currency', 'trend_badge', 'date_recorded',
    )
    list_filter   = ('vegetable_name', 'district', 'price_trend')
    search_fields = ('vegetable_name', 'market_name', 'district')
    ordering      = ('-date_recorded',)
    list_per_page = 30

    def trend_badge(self, obj):
        t = obj.price_trend or ''
        colours = {'up': '#1B5E20', 'down': '#B71C1C', 'stable': '#1565C0'}
        icons   = {'up': '↑', 'down': '↓', 'stable': '→'}
        label   = f"{icons.get(t.lower(), '')} {t}".strip()
        return _badge(label, colours.get(t.lower(), '#555')) if t else format_html(
            '<span style="color:#bbb">—</span>')
    trend_badge.short_description = 'Trend'


# ── Admin site branding ────────────────────────────────────────────────────
admin.site.site_header = "🌿 FarmAid Lesotho"
admin.site.site_title  = "FarmAid Admin"
admin.site.index_title = "Management Dashboard"



