# from django.contrib import admin
# from django.contrib.auth.admin import UserAdmin
# from .models import Farmer, KnowledgeBase, AIModel, Diagnosis, Treatment

# @admin.register(Farmer)
# class FarmerAdmin(UserAdmin):
#     # 1. Display list in Admin Panel
#     list_display = ('username', 'email', 'phone_number', 'location', 'is_staff', 'is_superuser')
#     search_fields = ('username', 'email')
#     list_filter = ('is_staff', 'is_superuser', 'location')

#     # 2. Control fields when EDITING an existing user
#     # This allows you to check 'is_superuser' to make them an Admin
#     fieldsets = UserAdmin.fieldsets + (
#         ('FarmAid Lesotho: Custom Fields', {
#             'fields': ('phone_number', 'location', 'language_preferences'),
#         }),
#     )

#     # 3. Control fields when ADDING a new user for the first time
#     # This ensures password, username, and custom fields appear together
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

#     # Helper to see which farmer the diagnosis belongs to
#     def get_farmer(self, obj):
#         return obj.PlantID.FarmerID.username
#     get_farmer.short_description = 'Farmer'

# @admin.register(Treatment)
# class TreatmentAdmin(admin.ModelAdmin):
#     list_display = ('TreatmentID', 'DiseaseName', 'RecommendedPesticide', 'Dosage')
#     search_fields = ('DiseaseName', 'RecommendedPesticide')




from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import (
    Farmer, KnowledgeBase, AIModel, Diagnosis, 
    Treatment, PersonalizedRule  # Added PersonalizedRule
)

@admin.register(Farmer)
class FarmerAdmin(UserAdmin):
    list_display = ('username', 'email', 'phone_number', 'location', 'is_staff', 'is_superuser')
    search_fields = ('username', 'email')
    list_filter = ('is_staff', 'is_superuser', 'location')

    fieldsets = UserAdmin.fieldsets + (
        ('FarmAid Lesotho: Custom Fields', {
            'fields': ('phone_number', 'location', 'language_preferences'),
        }),
    )

    add_fieldsets = UserAdmin.add_fieldsets + (
        ('FarmAid Lesotho: Custom Fields', {
            'fields': ('email', 'phone_number', 'location', 'language_preferences'),
        }),
    )

@admin.register(KnowledgeBase)
class KnowledgeBaseAdmin(admin.ModelAdmin):
    list_display = ('DiseaseName', 'LastUpdated')
    search_fields = ('DiseaseName',)

@admin.register(AIModel)
class AIModelAdmin(admin.ModelAdmin):
    list_display = ('ModelID', 'Version', 'AccuracyRate', 'LastTrainedDate')

@admin.register(Diagnosis)
class DiagnosisAdmin(admin.ModelAdmin):
    list_display = ('DiagnosisID', 'get_farmer', 'DiseaseName', 'ConfidenceLevel', 'DateDiagnosed')
    list_filter = ('DiseaseName', 'DateDiagnosed')

    def get_farmer(self, obj):
        return obj.PlantID.FarmerID.username
    get_farmer.short_description = 'Farmer'

@admin.register(Treatment)
class TreatmentAdmin(admin.ModelAdmin):
    list_display = ('TreatmentID', 'DiseaseName', 'RecommendedPesticide', 'Dosage')
    search_fields = ('DiseaseName', 'RecommendedPesticide')

# --- NEW: Personalized Rules Admin ---
@admin.register(PersonalizedRule)
class PersonalizedRuleAdmin(admin.ModelAdmin):
    """Allows Admins to manage the Expert Advice shown in the Flutter App."""
    list_display = ('DiseaseName', 'RecommendationCategory', 'short_advice')
    list_filter = ('RecommendationCategory', 'DiseaseName')
    search_fields = ('DiseaseName', 'ExpertAdvice')

    def short_advice(self, obj):
        """Truncates long advice so the table stays clean."""
        if len(obj.ExpertAdvice) > 50:
            return f"{obj.ExpertAdvice[:50]}..."
        return obj.ExpertAdvice
    short_advice.short_description = 'Expert Advice Preview'