# from django.contrib import admin
# from django.contrib.auth.admin import UserAdmin
# from django.utils.html import format_html
# from .models import (
#     Farmer, KnowledgeBase, AIModel, Diagnosis, 
#     Treatment, PersonalizedRule
# )

# @admin.register(Farmer)
# class FarmerAdmin(UserAdmin):
#     # Professional display with account status
#     list_display = ('username', 'email', 'phone_number', 'location', 'account_status', 'is_staff')
#     search_fields = ('username', 'email', 'phone_number')
#     list_filter = ('is_staff', 'is_superuser', 'location', 'is_active')

#     def account_status(self, obj):
#         color = "green" if obj.is_active else "red"
#         text = "ACTIVE" if obj.is_active else "LOCKED"
#         return format_html('<b style="color: {};">{}</b>', color, text)
#     account_status.short_description = 'Status'

#     fieldsets = UserAdmin.fieldsets + (
#         ('FarmAid Lesotho: Custom Fields', {
#             'fields': ('phone_number', 'location', 'language_preferences'),
#         }),
#     )

# @admin.register(Diagnosis)
# class DiagnosisAdmin(admin.ModelAdmin):
#     # Added confidence badges and date formatting
#     list_display = ('DiagnosisID', 'get_farmer', 'DiseaseName', 'confidence_badge', 'DateDiagnosed')
#     list_filter = ('DiseaseName', 'DateDiagnosed')
#     readonly_fields = ('DateDiagnosed',)

#     def confidence_badge(self, obj):
#         # Professional colored pills based on AI confidence
#         confidence = float(obj.ConfidenceLevel)
#         if confidence >= 85:
#             color = "#28a745"  # Success Green
#         elif confidence >= 60:
#             color = "#ffc107"  # Warning Yellow
#         else:
#             color = "#dc3545"  # Danger Red
            
#         return format_html(
#             '<span style="background-color: {}; color: white; padding: 3px 10px; border-radius: 10px; font-weight: bold;">{}%</span>',
#             color, confidence
#         )
#     confidence_badge.short_description = 'AI Confidence'

#     def get_farmer(self, obj):
#         return obj.PlantID.FarmerID.username
#     get_farmer.short_description = 'Farmer'

# @admin.register(KnowledgeBase)
# class KnowledgeBaseAdmin(admin.ModelAdmin):
#     list_display = ('DiseaseName', 'LastUpdated', 'view_details_btn')
#     search_fields = ('DiseaseName',)

#     def view_details_btn(self, obj):
#         return format_html('<a class="button" href="{}">Edit Content</a>', obj.get_absolute_url if hasattr(obj, 'get_absolute_url') else "#")
#     view_details_btn.short_description = 'Actions'

# @admin.register(AIModel)
# class AIModelAdmin(admin.ModelAdmin):
#     list_display = ('Version', 'accuracy_rate_bar', 'LastTrainedDate')
    
#     def accuracy_rate_bar(self, obj):
#         # Visual progress bar for model accuracy
#         return format_html(
#             '''
#             <div style="width: 100px; background-color: #f1f1f1; border-radius: 5px;">
#                 <div style="width: {}%; background-color: #2e7d32; height: 10px; border-radius: 5px;"></div>
#             </div>
#             <span>{}%</span>
#             ''',
#             obj.AccuracyRate, obj.AccuracyRate
#         )
#     accuracy_rate_bar.short_description = 'Model Accuracy'

# @admin.register(Treatment)
# class TreatmentAdmin(admin.ModelAdmin):
#     list_display = ('DiseaseName', 'pesticide_tag', 'Dosage')
#     list_filter = ('DiseaseName',)

#     def pesticide_tag(self, obj):
#         return format_html('<code style="color: #c7254e; background: #f9f2f4; padding: 2px 4px;">{}</code>', obj.RecommendedPesticide)
#     pesticide_tag.short_description = 'Pesticide'

# @admin.register(PersonalizedRule)
# class PersonalizedRuleAdmin(admin.ModelAdmin):
#     list_display = ('DiseaseName', 'category_label', 'short_advice')
#     list_filter = ('RecommendationCategory', 'DiseaseName')
    
#     def category_label(self, obj):
#         # Distinct colors for Organic vs Chemical categories
#         is_organic = "Organic" in obj.RecommendationCategory
#         color = "#155724" if is_organic else "#004085"
#         bg = "#d4edda" if is_organic else "#cce5ff"
#         return format_html(
#             '<span style="color: {}; background: {}; padding: 2px 8px; border-radius: 5px;">{}</span>',
#             color, bg, obj.RecommendationCategory
#         )
#     category_label.short_description = 'Category'

#     def short_advice(self, obj):
#         return (obj.ExpertAdvice[:75] + '...') if len(obj.ExpertAdvice) > 75 else obj.ExpertAdvice
#     short_advice.short_description = 'Expert Advice Preview'


# from django.contrib import admin
# from django.contrib.auth.admin import UserAdmin
# from django.utils.html import format_html
# from django.contrib.admin.models import LogEntry, ADDITION, CHANGE, DELETION
# from .models import (
#     Farmer, KnowledgeBase, AIModel, Diagnosis, 
#     Treatment, PersonalizedRule
# )

# # --- NEW: Admin Activity Log (Recent Actions) ---
# @admin.register(LogEntry)
# class LogEntryAdmin(admin.ModelAdmin):
#     """Monitor what other Admins are doing in the system."""
#     list_display = ('action_time', 'user', 'content_type', 'object_repr', 'action_flag_tag')
#     list_filter = ('action_flag', 'user', 'content_type')
#     search_fields = ('object_repr', 'change_message')
    
#     # Per your request: Allow deletion to keep history clean
#     def has_delete_permission(self, request, obj=None):
#         return True
    
#     def has_add_permission(self, request):
#         return False # Logs are generated by the system

#     def action_flag_tag(self, obj):
#         # Professional color coding for admin actions
#         colors = {
#             ADDITION: "#28a745", # Green
#             CHANGE: "#ffc107",   # Yellow
#             DELETION: "#dc3545", # Red
#         }
#         labels = {ADDITION: "ADDED", CHANGE: "CHANGED", DELETION: "DELETED"}
#         return format_html(
#             '<span style="background-color: {}; color: white; padding: 2px 8px; border-radius: 5px; font-weight: bold; font-size: 11px;">{}</span>',
#             colors.get(obj.action_flag, "#6c757d"),
#             labels.get(obj.action_flag, "UNKNOWN")
#         )
#     action_flag_tag.short_description = "Action"

# # --- EXISTING MODELS WITH ENHANCED STYLES ---

# @admin.register(Farmer)
# class FarmerAdmin(UserAdmin):
#     list_display = ('username', 'email', 'phone_number', 'location', 'account_status', 'is_staff')
#     search_fields = ('username', 'email', 'phone_number')
#     list_filter = ('is_staff', 'is_superuser', 'location', 'is_active')

#     def account_status(self, obj):
#         color = "green" if obj.is_active else "red"
#         text = "ACTIVE" if obj.is_active else "LOCKED"
#         return format_html('<b style="color: {};">{}</b>', color, text)
#     account_status.short_description = 'Status'

#     fieldsets = UserAdmin.fieldsets + (
#         ('FarmAid Lesotho: Custom Fields', {
#             'fields': ('phone_number', 'location', 'language_preferences'),
#         }),
#     )

# @admin.register(Diagnosis)
# class DiagnosisAdmin(admin.ModelAdmin):
#     list_display = ('DiagnosisID', 'get_farmer', 'DiseaseName', 'confidence_badge', 'DateDiagnosed')
#     list_filter = ('DiseaseName', 'DateDiagnosed')
#     readonly_fields = ('DateDiagnosed',)

#     def confidence_badge(self, obj):
#         confidence = float(obj.ConfidenceLevel)
#         if confidence >= 85:
#             color = "#28a745"
#         elif confidence >= 60:
#             color = "#ffc107"
#         else:
#             color = "#dc3545"
            
#         return format_html(
#             '<span style="background-color: {}; color: white; padding: 3px 10px; border-radius: 10px; font-weight: bold;">{}%</span>',
#             color, confidence
#         )
#     confidence_badge.short_description = 'AI Confidence'

#     def get_farmer(self, obj):
#         return obj.PlantID.FarmerID.username
#     get_farmer.short_description = 'Farmer'

# @admin.register(KnowledgeBase)
# class KnowledgeBaseAdmin(admin.ModelAdmin):
#     list_display = ('DiseaseName', 'LastUpdated', 'view_details_btn')
#     search_fields = ('DiseaseName',)

#     def view_details_btn(self, obj):
#         return format_html('<a class="button" style="padding: 2px 10px;" href="{}">Edit</a>', "#")
#     view_details_btn.short_description = 'Actions'

# @admin.register(AIModel)
# class AIModelAdmin(admin.ModelAdmin):
#     list_display = ('Version', 'accuracy_rate_bar', 'LastTrainedDate')
    
#     def accuracy_rate_bar(self, obj):
#         return format_html(
#             '''
#             <div style="width: 100px; background-color: #f1f1f1; border-radius: 5px; display: inline-block; vertical-align: middle;">
#                 <div style="width: {}%; background-color: #2e7d32; height: 10px; border-radius: 5px;"></div>
#             </div>
#             <span style="margin-left: 5px;">{}%</span>
#             ''',
#             obj.AccuracyRate, obj.AccuracyRate
#         )
#     accuracy_rate_bar.short_description = 'Model Accuracy'

# @admin.register(Treatment)
# class TreatmentAdmin(admin.ModelAdmin):
#     list_display = ('DiseaseName', 'pesticide_tag', 'Dosage')
#     list_filter = ('DiseaseName',)

#     def pesticide_tag(self, obj):
#         return format_html('<code style="color: #c7254e; background: #f9f2f4; padding: 2px 4px;">{}</code>', obj.RecommendedPesticide)
#     pesticide_tag.short_description = 'Pesticide'

# @admin.register(PersonalizedRule)
# class PersonalizedRuleAdmin(admin.ModelAdmin):
#     list_display = ('DiseaseName', 'category_label', 'short_advice')
#     list_filter = ('RecommendationCategory', 'DiseaseName')
    
#     def category_label(self, obj):
#         is_organic = "Organic" in obj.RecommendationCategory
#         color = "#155724" if is_organic else "#004085"
#         bg = "#d4edda" if is_organic else "#cce5ff"
#         return format_html(
#             '<span style="color: {}; background: {}; padding: 2px 8px; border-radius: 5px; font-weight: bold;">{}</span>',
#             color, bg, obj.RecommendationCategory
#         )
#     category_label.short_description = 'Category'

#     def short_advice(self, obj):
#         return (obj.ExpertAdvice[:75] + '...') if len(obj.ExpertAdvice) > 75 else obj.ExpertAdvice
#     short_advice.short_description = 'Expert Advice'




from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django.utils.html import format_html
from django.contrib.admin.models import LogEntry, ADDITION, CHANGE, DELETION
from .models import (
    Farmer, KnowledgeBase, AIModel, Diagnosis, 
    Treatment, PersonalizedRule, TranslationCache,
    CropProfile, Plant, AppAlert, WeatherData
)

# --- 1. ADMIN ACTIVITY LOG ---
@admin.register(LogEntry)
class LogEntryAdmin(admin.ModelAdmin):
    """Monitor what other Admins are doing in the system."""
    list_display = ('action_time', 'user', 'content_type', 'object_repr', 'action_flag_tag')
    list_filter = ('action_flag', 'user', 'content_type')
    search_fields = ('object_repr', 'change_message')
    
    def has_delete_permission(self, request, obj=None):
        return True
    
    def has_add_permission(self, request):
        return False 

    def action_flag_tag(self, obj):
        colors = {
            ADDITION: "#28a745", # Green
            CHANGE: "#ffc107",   # Yellow
            DELETION: "#dc3545", # Red
        }
        labels = {ADDITION: "ADDED", CHANGE: "CHANGED", DELETION: "DELETED"}
        return format_html(
            '<span style="background-color: {}; color: white; padding: 2px 8px; border-radius: 5px; font-weight: bold; font-size: 11px;">{}</span>',
            colors.get(obj.action_flag, "#6c757d"),
            labels.get(obj.action_flag, "UNKNOWN")
        )
    action_flag_tag.short_description = "Action"

# --- 2. MANUAL TRANSLATION MODULE (THE MASTER LOOKUP) ---
@admin.register(TranslationCache)
class TranslationCacheAdmin(admin.ModelAdmin):
    list_display = ('english_preview', 'sesotho_text_editable', 'last_updated')
    list_editable = ('sesotho_text_editable',) # NOT ALLOWED: See note below
    search_fields = ('english_text', 'sesotho_text')
    list_filter = ('last_updated',)
    ordering = ('-last_updated',)

    # Custom editable field for the list view to speed up translation
    def sesotho_text_editable(self, obj):
        return obj.sesotho_text
    
    def english_preview(self, obj):
        return (obj.english_text[:50] + '...') if len(obj.english_text) > 50 else obj.english_text
    english_preview.short_description = "English Text (Auto-Detected)"

    # Making the list editable requires the field to be in list_display
    # We use 'sesotho_text' directly for list_editable
    list_display = ('english_preview', 'sesotho_text', 'last_updated')
    list_editable = ('sesotho_text',)

# --- 3. FARMER & PROFILES ---

@admin.register(Farmer)
class FarmerAdmin(UserAdmin):
    list_display = ('username', 'email', 'phone_number', 'location', 'lang_badge', 'account_status')
    search_fields = ('username', 'email', 'phone_number')
    list_filter = ('language_preferences', 'location', 'is_active')

    def lang_badge(self, obj):
        color = "#007bff" if obj.language_preferences == 'en' else "#6f42c1"
        return format_html('<span style="color: white; background: {}; padding: 2px 6px; border-radius: 4px;">{}</span>', color, obj.language_preferences.upper())
    lang_badge.short_description = 'Lang'

    def account_status(self, obj):
        color = "green" if obj.is_active else "red"
        text = "ACTIVE" if obj.is_active else "LOCKED"
        return format_html('<b style="color: {};">{}</b>', color, text)
    account_status.short_description = 'Status'

    fieldsets = UserAdmin.fieldsets + (
        ('FarmAid Lesotho: Custom Fields', {
            'fields': ('phone_number', 'location', 'language_preferences'),
        }),
    )

@admin.register(CropProfile)
class CropProfileAdmin(admin.ModelAdmin):
    list_display = ('VegetableType', 'FarmerID', 'FarmLocation', 'IsActive', 'PlantingDate')
    list_filter = ('VegetableType', 'IsActive', 'FarmLocation')

@admin.register(Plant)
class PlantAdmin(admin.ModelAdmin):
    list_display = ('PlantID', 'FarmerID', 'CropType', 'DateCaptured', 'view_image_link')
    readonly_fields = ('DateCaptured',)

    def view_image_link(self, obj):
        if obj.ImageFile:
            return format_html('<a href="{}" target="_blank">View Photo</a>', obj.ImageFile)
        return "No Image"
    view_image_link.short_description = "Supabase URL"

# --- 4. AI & DIAGNOSIS ---

@admin.register(Diagnosis)
class DiagnosisAdmin(admin.ModelAdmin):
    list_display = ('DiagnosisID', 'get_farmer', 'DiseaseName', 'confidence_badge', 'DateDiagnosed')
    list_filter = ('DiseaseName', 'DateDiagnosed')
    readonly_fields = ('DateDiagnosed',)

    def confidence_badge(self, obj):
        confidence = float(obj.ConfidenceLevel)
        color = "#28a745" if confidence >= 85 else "#ffc107" if confidence >= 60 else "#dc3545"
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 10px; border-radius: 10px; font-weight: bold;">{}%</span>',
            color, confidence
        )
    confidence_badge.short_description = 'AI Confidence'

    def get_farmer(self, obj):
        return obj.PlantID.FarmerID.username
    get_farmer.short_description = 'Farmer'

@admin.register(Treatment)
class TreatmentAdmin(admin.ModelAdmin):
    list_display = ('DiseaseName', 'pesticide_tag', 'Dosage')
    search_fields = ('DiseaseName', 'RecommendedPesticide')

    def pesticide_tag(self, obj):
        return format_html('<code style="color: #c7254e; background: #f9f2f4; padding: 2px 4px;">{}</code>', obj.RecommendedPesticide)
    pesticide_tag.short_description = 'Pesticide'

# --- 5. SYSTEM & WEATHER ---

@admin.register(AppAlert)
class AppAlertAdmin(admin.ModelAdmin):
    list_display = ('Title', 'FarmerID', 'alert_type', 'IsRead', 'DateCreated')
    list_filter = ('alert_type', 'IsRead')

@admin.register(WeatherData)
class WeatherDataAdmin(admin.ModelAdmin):
    list_display = ('DateUpdated', 'Temperature', 'Humidity', 'Rainfall', 'AlertMessage')

@admin.register(KnowledgeBase)
class KnowledgeBaseAdmin(admin.ModelAdmin):
    list_display = ('DiseaseName', 'LastUpdated')
    search_fields = ('DiseaseName',)

@admin.register(AIModel)
class AIModelAdmin(admin.ModelAdmin):
    list_display = ('Version', 'accuracy_rate_bar', 'LastTrainedDate')
    
    def accuracy_rate_bar(self, obj):
        return format_html(
            '''
            <div style="width: 100px; background-color: #f1f1f1; border-radius: 5px; display: inline-block; vertical-align: middle;">
                <div style="width: {}%; background-color: #2e7d32; height: 10px; border-radius: 5px;"></div>
            </div>
            <span style="margin-left: 5px;">{}%</span>
            ''',
            obj.AccuracyRate, obj.AccuracyRate
        )
    accuracy_rate_bar.short_description = 'Model Accuracy'

@admin.register(PersonalizedRule)
class PersonalizedRuleAdmin(admin.ModelAdmin):
    list_display = ('DiseaseName', 'category_label', 'short_advice')
    list_filter = ('RecommendationCategory', 'DiseaseName')
    
    def category_label(self, obj):
        is_organic = "Organic" in obj.RecommendationCategory
        color, bg = ("#155724", "#d4edda") if is_organic else ("#004085", "#cce5ff")
        return format_html(
            '<span style="color: {}; background: {}; padding: 2px 8px; border-radius: 5px; font-weight: bold;">{}</span>',
            color, bg, obj.RecommendationCategory
        )
    category_label.short_description = 'Category'

    def short_advice(self, obj):
        return (obj.ExpertAdvice[:75] + '...') if len(obj.ExpertAdvice) > 75 else obj.ExpertAdvice
    short_advice.short_description = 'Expert Advice'
