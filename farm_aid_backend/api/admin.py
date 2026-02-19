# from django.contrib import admin
# from django.contrib.auth.admin import UserAdmin
# from .models import (
#     Farmer, KnowledgeBase, AIModel, Diagnosis, 
#     Treatment, PersonalizedRule  # Added PersonalizedRule
# )

# @admin.register(Farmer)
# class FarmerAdmin(UserAdmin):
#     list_display = ('username', 'email', 'phone_number', 'location', 'is_staff', 'is_superuser')
#     search_fields = ('username', 'email')
#     list_filter = ('is_staff', 'is_superuser', 'location')

#     fieldsets = UserAdmin.fieldsets + (
#         ('FarmAid Lesotho: Custom Fields', {
#             'fields': ('phone_number', 'location', 'language_preferences'),
#         }),
#     )

#     add_fieldsets = UserAdmin.add_fieldsets + (
#         ('FarmAid Lesotho: Custom Fields', {
#             'fields': ('email', 'phone_number', 'location', 'language_preferences'),
#         }),
#     )

# @admin.register(KnowledgeBase)
# class KnowledgeBaseAdmin(admin.ModelAdmin):
#     list_display = ('DiseaseName', 'LastUpdated')
#     search_fields = ('DiseaseName',)

# @admin.register(AIModel)
# class AIModelAdmin(admin.ModelAdmin):
#     list_display = ('ModelID', 'Version', 'AccuracyRate', 'LastTrainedDate')

# @admin.register(Diagnosis)
# class DiagnosisAdmin(admin.ModelAdmin):
#     list_display = ('DiagnosisID', 'get_farmer', 'DiseaseName', 'ConfidenceLevel', 'DateDiagnosed')
#     list_filter = ('DiseaseName', 'DateDiagnosed')

#     def get_farmer(self, obj):
#         return obj.PlantID.FarmerID.username
#     get_farmer.short_description = 'Farmer'

# @admin.register(Treatment)
# class TreatmentAdmin(admin.ModelAdmin):
#     list_display = ('TreatmentID', 'DiseaseName', 'RecommendedPesticide', 'Dosage')
#     search_fields = ('DiseaseName', 'RecommendedPesticide')

# # --- NEW: Personalized Rules Admin ---
# @admin.register(PersonalizedRule)
# class PersonalizedRuleAdmin(admin.ModelAdmin):
#     """Allows Admins to manage the Expert Advice shown in the Flutter App."""
#     list_display = ('DiseaseName', 'RecommendationCategory', 'short_advice')
#     list_filter = ('RecommendationCategory', 'DiseaseName')
#     search_fields = ('DiseaseName', 'ExpertAdvice')

#     def short_advice(self, obj):
#         """Truncates long advice so the table stays clean."""
#         if len(obj.ExpertAdvice) > 50:
#             return f"{obj.ExpertAdvice[:50]}..."
#         return obj.ExpertAdvice
#     short_advice.short_description = 'Expert Advice Preview'


from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django.utils.html import format_html
from .models import (
    Farmer, KnowledgeBase, AIModel, Diagnosis, 
    Treatment, PersonalizedRule
)

@admin.register(Farmer)
class FarmerAdmin(UserAdmin):
    # Professional display with account status
    list_display = ('username', 'email', 'phone_number', 'location', 'account_status', 'is_staff')
    search_fields = ('username', 'email', 'phone_number')
    list_filter = ('is_staff', 'is_superuser', 'location', 'is_active')

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

@admin.register(Diagnosis)
class DiagnosisAdmin(admin.ModelAdmin):
    # Added confidence badges and date formatting
    list_display = ('DiagnosisID', 'get_farmer', 'DiseaseName', 'confidence_badge', 'DateDiagnosed')
    list_filter = ('DiseaseName', 'DateDiagnosed')
    readonly_fields = ('DateDiagnosed',)

    def confidence_badge(self, obj):
        # Professional colored pills based on AI confidence
        confidence = float(obj.ConfidenceLevel)
        if confidence >= 85:
            color = "#28a745"  # Success Green
        elif confidence >= 60:
            color = "#ffc107"  # Warning Yellow
        else:
            color = "#dc3545"  # Danger Red
            
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 10px; border-radius: 10px; font-weight: bold;">{}%</span>',
            color, confidence
        )
    confidence_badge.short_description = 'AI Confidence'

    def get_farmer(self, obj):
        return obj.PlantID.FarmerID.username
    get_farmer.short_description = 'Farmer'

@admin.register(KnowledgeBase)
class KnowledgeBaseAdmin(admin.ModelAdmin):
    list_display = ('DiseaseName', 'LastUpdated', 'view_details_btn')
    search_fields = ('DiseaseName',)

    def view_details_btn(self, obj):
        return format_html('<a class="button" href="{}">Edit Content</a>', obj.get_absolute_url if hasattr(obj, 'get_absolute_url') else "#")
    view_details_btn.short_description = 'Actions'

@admin.register(AIModel)
class AIModelAdmin(admin.ModelAdmin):
    list_display = ('Version', 'accuracy_rate_bar', 'LastTrainedDate')
    
    def accuracy_rate_bar(self, obj):
        # Visual progress bar for model accuracy
        return format_html(
            '''
            <div style="width: 100px; background-color: #f1f1f1; border-radius: 5px;">
                <div style="width: {}%; background-color: #2e7d32; height: 10px; border-radius: 5px;"></div>
            </div>
            <span>{}%</span>
            ''',
            obj.AccuracyRate, obj.AccuracyRate
        )
    accuracy_rate_bar.short_description = 'Model Accuracy'

@admin.register(Treatment)
class TreatmentAdmin(admin.ModelAdmin):
    list_display = ('DiseaseName', 'pesticide_tag', 'Dosage')
    list_filter = ('DiseaseName',)

    def pesticide_tag(self, obj):
        return format_html('<code style="color: #c7254e; background: #f9f2f4; padding: 2px 4px;">{}</code>', obj.RecommendedPesticide)
    pesticide_tag.short_description = 'Pesticide'

@admin.register(PersonalizedRule)
class PersonalizedRuleAdmin(admin.ModelAdmin):
    list_display = ('DiseaseName', 'category_label', 'short_advice')
    list_filter = ('RecommendationCategory', 'DiseaseName')
    
    def category_label(self, obj):
        # Distinct colors for Organic vs Chemical categories
        is_organic = "Organic" in obj.RecommendationCategory
        color = "#155724" if is_organic else "#004085"
        bg = "#d4edda" if is_organic else "#cce5ff"
        return format_html(
            '<span style="color: {}; background: {}; padding: 2px 8px; border-radius: 5px;">{}</span>',
            color, bg, obj.RecommendationCategory
        )
    category_label.short_description = 'Category'

    def short_advice(self, obj):
        return (obj.ExpertAdvice[:75] + '...') if len(obj.ExpertAdvice) > 75 else obj.ExpertAdvice
    short_advice.short_description = 'Expert Advice Preview'
