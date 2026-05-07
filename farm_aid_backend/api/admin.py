# from django.contrib import admin
# from django.contrib.auth.admin import UserAdmin
# from django.utils.html import format_html
# from django.urls import reverse
# from django.utils import timezone
# from django.contrib.admin import SimpleListFilter
# from .models import (
#     Farmer, KnowledgeBase, AIModel, Diagnosis,
#     Treatment,
# )

# # Unregister default models that might cause duplicates
# from django.contrib.auth.models import Group
# from allauth.account.models import EmailAddress
# from allauth.socialaccount.models import SocialAccount, SocialToken, SocialApp

# # Custom admin site header and title
# admin.site.site_header = "FarmAid Management System"
# admin.site.site_title = "FarmAid Admin Portal"
# admin.site.index_title = "Dashboard | FarmAid Agriculture Management"
# admin.site.site_url = "/"

# # Unregister to prevent duplicates
# try:
#     admin.site.unregister(Group)
# except admin.sites.NotRegistered:
#     pass

# try:
#     admin.site.unregister(EmailAddress)
# except admin.sites.NotRegistered:
#     pass

# try:
#     admin.site.unregister(SocialAccount)
# except admin.sites.NotRegistered:
#     pass

# try:
#     admin.site.unregister(SocialToken)
# except admin.sites.NotRegistered:
#     pass

# try:
#     admin.site.unregister(SocialApp)
# except admin.sites.NotRegistered:
#     pass


# # ============================================================
# # --- CUSTOM ADMIN CLASSES WITH STYLING ---
# # ============================================================

# class BaseAdmin(admin.ModelAdmin):
#     """Base admin class with common styling"""
#     save_on_top = True
#     list_per_page = 25
    
#     def get_readonly_fields(self, request, obj=None):
#         if obj:
#             return self.readonly_fields + ('created_at', 'updated_at') if hasattr(self, 'readonly_fields') else ()
#         return self.readonly_fields


# class ReadOnlyAdmin(BaseAdmin):
#     """Admin class that prevents adding, editing, or deleting"""
#     def has_add_permission(self, request):
#         return False
    
#     def has_change_permission(self, request, obj=None):
#         return False
    
#     def has_delete_permission(self, request, obj=None):
#         return False
    
#     def has_view_permission(self, request, obj=None):
#         return True


# class InteractiveAdmin(BaseAdmin):
#     """Admin with interactive features and inline editing"""
#     actions_on_top = True
#     actions_on_bottom = True
#     show_full_result_count = True


# # ============================================================
# # --- CUSTOM FILTERS ---
# # ============================================================

# class ActiveFilter(SimpleListFilter):
#     title = 'Status'
#     parameter_name = 'is_active'
    
#     def lookups(self, request, model_admin):
#         return (
#             ('active', 'Active'),
#             ('inactive', 'Inactive'),
#         )
    
#     def queryset(self, request, queryset):
#         if self.value() == 'active':
#             return queryset.filter(is_active=True)
#         if self.value() == 'inactive':
#             return queryset.filter(is_active=False)
#         return queryset


# # ============================================================
# # --- SECTION 1: USER MANAGEMENT ---
# # ============================================================

# @admin.register(Farmer)
# class FarmerAdmin(InteractiveAdmin, UserAdmin):
#     list_display = (
#         'username', 'display_name', 'email', 'display_phone', 'district',
#         'display_experience', 'status_badge', 'last_active_badge'
#     )
#     search_fields = ('username', 'email', 'first_name', 'last_name', 'district', 'phone_number')
#     list_filter = ('district', 'experience_level', 'is_active', 'is_staff', ActiveFilter)
#     list_per_page = 25
    
#     fieldsets = UserAdmin.fieldsets + (
#         ('FarmAid — Farmer Profile', {
#             'classes': ('wide', 'collapse'),
#             'fields': (
#                 'phone_number', 'district', 'language_preferences',
#                 'profile_photo_url', 'farm_size_hectares', 'experience_level',
#             ),
#         }),
#         ('Notification Preferences', {
#             'classes': ('wide', 'collapse'),
#             'fields': (
#                 'notification_diseases', 'notification_weather', 'notification_market',
#             ),
#         }),
#         ('App Status', {
#             'classes': ('wide', 'collapse'),
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

#     def display_name(self, obj):
#         try:
#             full_name = f"{obj.first_name} {obj.last_name}".strip()
#             if full_name:
#                 return format_html('<span style="font-weight: 600; color: #2d6a4f;">{}</span>', full_name)
#         except Exception:
#             return '—'
#         return '—'
#     display_name.short_description = 'Full Name'
#     display_name.admin_order_field = 'first_name'

#     def display_phone(self, obj):
#         try:
#             if obj.phone_number:
#                 return format_html('<code style="background: #f0f2f0; padding: 4px 8px; border-radius: 6px;">{}</code>', obj.phone_number)
#         except Exception:
#             return '—'
#         return '—'
#     display_phone.short_description = 'Phone'

#     def display_experience(self, obj):
#         try:
#             colors = {'beginner': '#6c757d', 'intermediate': '#fd7e14', 'expert': '#28a745'}
#             color = colors.get(obj.experience_level, '#6c757d')
#             icons = {'beginner': '🌱', 'intermediate': '🌿', 'expert': '🌾'}
#             icon = icons.get(obj.experience_level, '🌱')
#             return format_html('<span style="color: {}; font-weight: 500;">{} {}</span>', color, icon, obj.get_experience_level_display())
#         except Exception:
#             return '—'
#     display_experience.short_description = 'Experience'

#     def status_badge(self, obj):
#         try:
#             if obj.is_active:
#                 return format_html('<span style="background: linear-gradient(135deg, #28a745, #20c997); color: white; padding: 4px 12px; border-radius: 20px; font-size: 11px; font-weight: 600;">Active</span>')
#         except Exception:
#             return '—'
#         return format_html('<span style="background: #dc3545; color: white; padding: 4px 12px; border-radius: 20px; font-size: 11px; font-weight: 600;">Inactive</span>')
#     status_badge.short_description = 'Status'

#     def last_active_badge(self, obj):
#         try:
#             if obj.last_active:
#                 days_ago = (timezone.now() - obj.last_active).days
#                 if days_ago <= 1:
#                     return format_html('<span style="color: #28a745;">● Recently active</span>')
#                 elif days_ago <= 7:
#                     return format_html('<span style="color: #fd7e14;">● {} days ago</span>', days_ago)
#                 else:
#                     return format_html('<span style="color: #6c757d;">○ {} days ago</span>', days_ago)
#         except Exception:
#             return '—'
#         return '—'
#     last_active_badge.short_description = 'Last Active'


# # ============================================================
# # --- SECTION 2: DIAGNOSTICS (READ ONLY) ---
# # ============================================================

# @admin.register(Diagnosis)
# class DiagnosisAdmin(ReadOnlyAdmin):
#     list_display = (
#         'DiagnosisID', 'farmer_link', 'disease_badge', 'confidence_display',
#         'severity_badge', 'date_diagnosed_badge'
#     )
#     list_filter = ('DiseaseName', 'severity')
#     search_fields = ('DiseaseName', 'PlantID__FarmerID__username')
#     list_select_related = ('PlantID__FarmerID',)
#     list_per_page = 25
    
#     def has_add_permission(self, request):
#         return False
    
#     def has_change_permission(self, request, obj=None):
#         return False
    
#     def has_delete_permission(self, request, obj=None):
#         return False

#     def farmer_link(self, obj):
#         try:
#             if obj.PlantID and obj.PlantID.FarmerID:
#                 url = reverse('admin:api_farmer_change', args=[obj.PlantID.FarmerID.id])
#                 return format_html('<a href="{}" style="color: #2d6a4f;">👤 {}</a>', url, obj.PlantID.FarmerID.username)
#         except Exception:
#             return '—'
#         return '—'
#     farmer_link.short_description = 'Farmer'

#     def disease_badge(self, obj):
#         try:
#             is_healthy = 'healthy' in obj.DiseaseName.lower()
#             color = '#28a745' if is_healthy else '#dc3545'
#             bg = '#d4edda' if is_healthy else '#f8d7da'
#             return format_html('<span style="background: {}; color: {}; padding: 4px 12px; border-radius: 20px; font-size: 12px; font-weight: 500;">🔬 {}</span>', 
#                               bg, color, obj.DiseaseName.replace('_', ' '))
#         except Exception:
#             return '—'
#     disease_badge.short_description = 'Disease'

#     def confidence_display(self, obj):
#         try:
#             if obj.ConfidenceLevel is None:
#                 return '—'
#             pct = int(obj.ConfidenceLevel * 100)
#             if pct >= 75:
#                 color = '#28a745'
#                 icon = '✓'
#             elif pct >= 50:
#                 color = '#fd7e14'
#                 icon = '⚠'
#             else:
#                 color = '#dc3545'
#                 icon = '✗'
#             return format_html('<span style="color: {}; font-weight: bold;">{} {:.0f}%</span>', color, icon, obj.ConfidenceLevel * 100)
#         except Exception:
#             return '—'
#     confidence_display.short_description = 'Confidence'

#     def severity_badge(self, obj):
#         try:
#             colors = {'mild': '#17a2b8', 'moderate': '#fd7e14', 'severe': '#dc3545'}
#             bg_colors = {'mild': '#d1ecf1', 'moderate': '#fff3cd', 'severe': '#f8d7da'}
#             color = colors.get(obj.severity, '#6c757d')
#             bg = bg_colors.get(obj.severity, '#e9ecef')
#             icons = {'mild': '🟢', 'moderate': '🟡', 'severe': '🔴'}
#             icon = icons.get(obj.severity, '⚪')
#             display = obj.get_severity_display() if obj.severity else '—'
#             return format_html('<span style="background: {}; color: {}; padding: 4px 12px; border-radius: 20px; font-size: 11px;">{} {}</span>', 
#                               bg, color, icon, display)
#         except Exception:
#             return '—'
#     severity_badge.short_description = 'Severity'

#     def date_diagnosed_badge(self, obj):
#         try:
#             if obj.DateDiagnosed:
#                 return format_html('<span style="color: #6c757d;">📅 {}</span>', obj.DateDiagnosed.strftime('%d %b %Y'))
#         except Exception:
#             return '—'
#         return '—'
#     date_diagnosed_badge.short_description = 'Date'


# # ============================================================
# # --- SECTION 3: TREATMENT DATABASE ---
# # ============================================================

# @admin.register(Treatment)
# class TreatmentAdmin(InteractiveAdmin):
#     list_display = ('TreatmentID', 'disease_badge', 'pesticide_display', 'dosage_display')
#     search_fields = ('DiseaseName', 'RecommendedPesticide')
#     list_per_page = 25

#     def disease_badge(self, obj):
#         try:
#             return format_html('<span style="background: #f8d7da; color: #dc2626; padding: 4px 12px; border-radius: 20px; font-weight: 500;">💊 {}</span>', 
#                               obj.DiseaseName if obj.DiseaseName else '—')
#         except Exception:
#             return '—'
#     disease_badge.short_description = 'Disease'

#     def pesticide_display(self, obj):
#         try:
#             return format_html('<code style="background: #f3f4f6; padding: 4px 8px; border-radius: 6px;">🧪 {}</code>', obj.RecommendedPesticide)
#         except Exception:
#             return '—'
#     pesticide_display.short_description = 'Pesticide'

#     def dosage_display(self, obj):
#         try:
#             return format_html('<span style="font-family: monospace;">📊 {}</span>', obj.Dosage)
#         except Exception:
#             return '—'
#     dosage_display.short_description = 'Dosage'


# # ============================================================
# # --- SECTION 4: KNOWLEDGE BASE ---
# # ============================================================

# @admin.register(KnowledgeBase)
# class KnowledgeBaseAdmin(InteractiveAdmin):
#     list_display = ('DiseaseName', 'has_causes', 'last_updated_badge')
#     search_fields = ('DiseaseName',)
#     list_per_page = 25
    
#     fieldsets = (
#         ('Disease Information', {
#             'fields': ('DiseaseName',),
#         }),
#         ('Symptoms and Causes', {
#             'fields': ('Symptoms', 'Causes'),
#         }),
#         ('Treatment Protocol', {
#             'fields': ('TreatmentInfo',),
#         }),
#     )

#     def has_causes(self, obj):
#         try:
#             if obj.Causes:
#                 return format_html('<span style="color: #10b981;">✓ Documented</span>')
#         except Exception:
#             return '—'
#         return format_html('<span style="color: #ef4444;">✗ Missing</span>')
#     has_causes.short_description = 'Has Causes'

#     def last_updated_badge(self, obj):
#         try:
#             if obj.LastUpdated:
#                 return format_html('<span style="color: #6b7280; font-size: 11px;">🕒 {}</span>', 
#                                   obj.LastUpdated.strftime('%d %b %Y'))
#         except Exception:
#             return '—'
#         return '—'
#     last_updated_badge.short_description = 'Last Updated'


# # ============================================================
# # --- SECTION 5: AI MODELS ---
# # ============================================================

# @admin.register(AIModel)
# class AIModelAdmin(InteractiveAdmin):
#     list_display = ('ModelID', 'Version', 'accuracy_display', 'last_trained_badge')
#     list_per_page = 25
    
#     def accuracy_display(self, obj):
#         try:
#             pct = obj.AccuracyRate * 100
#             if pct >= 85:
#                 color = '#10b981'
#                 icon = '🚀'
#             elif pct >= 70:
#                 color = '#f59e0b'
#                 icon = '📈'
#             else:
#                 color = '#ef4444'
#                 icon = '⚠️'
#             return format_html('<span style="color: {}; font-weight: 600;">{} {:.1f}%</span>', color, icon, pct)
#         except Exception:
#             return '—'
#     accuracy_display.short_description = 'Accuracy'

#     def last_trained_badge(self, obj):
#         try:
#             if obj.LastTrainedDate:
#                 return format_html('<span style="color: #6b7280; font-size: 11px;">🧠 {}</span>', 
#                                   obj.LastTrainedDate.strftime('%d %b %Y'))
#         except Exception:
#             return '—'
#         return '—'
#     last_trained_badge.short_description = 'Last Trained'


# # ============================================================
# # --- HIDDEN MODELS (Not Displayed in Admin) ---
# # ============================================================

# # TranslationCache - Hidden (system managed)
# try:
#     admin.site.unregister(TranslationCache)
# except:
#     pass

# # CropProfile - Hidden (managed through Plant model)
# try:
#     admin.site.unregister(CropProfile)
# except:
#     pass

# # Plant - Hidden
# try:
#     admin.site.unregister(Plant)
# except:
#     pass

# # AppAlert - Hidden (system generated only)
# try:
#     admin.site.unregister(AppAlert)
# except:
#     pass

# # WeatherData - Hidden (system generated only)
# try:
#     admin.site.unregister(WeatherData)
# except:
#     pass

# # FarmerInsight - Hidden (auto-generated)
# try:
#     admin.site.unregister(FarmerInsight)
# except:
#     pass

# # GrowthJournalEntry - Hidden (user app only)
# try:
#     admin.site.unregister(GrowthJournalEntry)
# except:
#     pass


from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django.utils.html import format_html
from django.urls import reverse
from django.utils import timezone
from django.contrib.admin import SimpleListFilter
from .models import (
    Farmer, KnowledgeBase, AIModel, Diagnosis,
    Treatment,
)

# IMPORT the models you want to hide (must import before unregistering)
from .models import (
    TranslationCache,
    CropProfile,
    Plant,
    AppAlert,
    WeatherData,
    FarmerInsight,
    GrowthJournalEntry,
)

# Unregister default models that might cause duplicates
from django.contrib.auth.models import Group
from allauth.account.models import EmailAddress
from allauth.socialaccount.models import SocialAccount, SocialToken, SocialApp

# Custom admin site header and title
admin.site.site_header = "FarmAid Management System"
admin.site.site_title = "FarmAid Admin Portal"
admin.site.index_title = "Dashboard | FarmAid Agriculture Management"
admin.site.site_url = "/"

# Unregister default auth models
try:
    admin.site.unregister(Group)
except admin.sites.NotRegistered:
    pass

try:
    admin.site.unregister(EmailAddress)
except admin.sites.NotRegistered:
    pass

try:
    admin.site.unregister(SocialAccount)
except admin.sites.NotRegistered:
    pass

try:
    admin.site.unregister(SocialToken)
except admin.sites.NotRegistered:
    pass

try:
    admin.site.unregister(SocialApp)
except admin.sites.NotRegistered:
    pass


# ============================================================
# --- CUSTOM ADMIN CLASSES WITH STYLING ---
# ============================================================

class BaseAdmin(admin.ModelAdmin):
    """Base admin class with common styling"""
    save_on_top = True
    list_per_page = 25
    
    def get_readonly_fields(self, request, obj=None):
        if obj:
            return self.readonly_fields + ('created_at', 'updated_at') if hasattr(self, 'readonly_fields') else ()
        return self.readonly_fields


class ReadOnlyAdmin(BaseAdmin):
    """Admin class that prevents adding, editing, or deleting"""
    def has_add_permission(self, request):
        return False
    
    def has_change_permission(self, request, obj=None):
        return False
    
    def has_delete_permission(self, request, obj=None):
        return False
    
    def has_view_permission(self, request, obj=None):
        return True


class InteractiveAdmin(BaseAdmin):
    """Admin with interactive features and inline editing"""
    actions_on_top = True
    actions_on_bottom = True
    show_full_result_count = True


# ============================================================
# --- CUSTOM FILTERS ---
# ============================================================

class ActiveFilter(SimpleListFilter):
    title = 'Status'
    parameter_name = 'is_active'
    
    def lookups(self, request, model_admin):
        return (
            ('active', 'Active'),
            ('inactive', 'Inactive'),
        )
    
    def queryset(self, request, queryset):
        if self.value() == 'active':
            return queryset.filter(is_active=True)
        if self.value() == 'inactive':
            return queryset.filter(is_active=False)
        return queryset


# ============================================================
# --- SECTION 1: USER MANAGEMENT ---
# ============================================================

@admin.register(Farmer)
class FarmerAdmin(InteractiveAdmin, UserAdmin):
    list_display = (
        'username', 'display_name', 'email', 'display_phone', 'district',
        'display_experience', 'status_badge', 'last_active_badge'
    )
    search_fields = ('username', 'email', 'first_name', 'last_name', 'district', 'phone_number')
    list_filter = ('district', 'experience_level', 'is_active', 'is_staff', ActiveFilter)
    list_per_page = 25
    
    fieldsets = UserAdmin.fieldsets + (
        ('FarmAid — Farmer Profile', {
            'classes': ('wide', 'collapse'),
            'fields': (
                'phone_number', 'district', 'language_preferences',
                'profile_photo_url', 'farm_size_hectares', 'experience_level',
            ),
        }),
        ('Notification Preferences', {
            'classes': ('wide', 'collapse'),
            'fields': (
                'notification_diseases', 'notification_weather', 'notification_market',
            ),
        }),
        ('App Status', {
            'classes': ('wide', 'collapse'),
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

    def display_name(self, obj):
        try:
            full_name = f"{obj.first_name} {obj.last_name}".strip()
            if full_name:
                return format_html('<span style="font-weight: 600; color: #2d6a4f;">{}</span>', full_name)
        except Exception:
            return '—'
        return '—'
    display_name.short_description = 'Full Name'
    display_name.admin_order_field = 'first_name'

    def display_phone(self, obj):
        try:
            if obj.phone_number:
                return format_html('<code style="background: #f0f2f0; padding: 4px 8px; border-radius: 6px;">{}</code>', obj.phone_number)
        except Exception:
            return '—'
        return '—'
    display_phone.short_description = 'Phone'

    def display_experience(self, obj):
        try:
            colors = {'beginner': '#6c757d', 'intermediate': '#fd7e14', 'expert': '#28a745'}
            color = colors.get(obj.experience_level, '#6c757d')
            icons = {'beginner': '🌱', 'intermediate': '🌿', 'expert': '🌾'}
            icon = icons.get(obj.experience_level, '🌱')
            return format_html('<span style="color: {}; font-weight: 500;">{} {}</span>', color, icon, obj.get_experience_level_display())
        except Exception:
            return '—'
    display_experience.short_description = 'Experience'

    def status_badge(self, obj):
        try:
            if obj.is_active:
                return format_html('<span style="background: linear-gradient(135deg, #28a745, #20c997); color: white; padding: 4px 12px; border-radius: 20px; font-size: 11px; font-weight: 600;">Active</span>')
        except Exception:
            return '—'
        return format_html('<span style="background: #dc3545; color: white; padding: 4px 12px; border-radius: 20px; font-size: 11px; font-weight: 600;">Inactive</span>')
    status_badge.short_description = 'Status'

    def last_active_badge(self, obj):
        try:
            if obj.last_active:
                days_ago = (timezone.now() - obj.last_active).days
                if days_ago <= 1:
                    return format_html('<span style="color: #28a745;">● Recently active</span>')
                elif days_ago <= 7:
                    return format_html('<span style="color: #fd7e14;">● {} days ago</span>', days_ago)
                else:
                    return format_html('<span style="color: #6c757d;">○ {} days ago</span>', days_ago)
        except Exception:
            return '—'
        return '—'
    last_active_badge.short_description = 'Last Active'


# ============================================================
# --- SECTION 2: DIAGNOSTICS (READ ONLY) ---
# ============================================================

@admin.register(Diagnosis)
class DiagnosisAdmin(ReadOnlyAdmin):
    list_display = (
        'DiagnosisID', 'farmer_link', 'disease_badge', 'confidence_display',
        'severity_badge', 'date_diagnosed_badge'
    )
    list_filter = ('DiseaseName', 'severity')
    search_fields = ('DiseaseName', 'PlantID__FarmerID__username')
    list_select_related = ('PlantID__FarmerID',)
    list_per_page = 25
    
    def has_add_permission(self, request):
        return False
    
    def has_change_permission(self, request, obj=None):
        return False
    
    def has_delete_permission(self, request, obj=None):
        return False

    def farmer_link(self, obj):
        try:
            if obj.PlantID and obj.PlantID.FarmerID:
                url = reverse('admin:api_farmer_change', args=[obj.PlantID.FarmerID.id])
                return format_html('<a href="{}" style="color: #2d6a4f;">👤 {}</a>', url, obj.PlantID.FarmerID.username)
        except Exception:
            return '—'
        return '—'
    farmer_link.short_description = 'Farmer'

    def disease_badge(self, obj):
        try:
            is_healthy = 'healthy' in obj.DiseaseName.lower()
            color = '#28a745' if is_healthy else '#dc3545'
            bg = '#d4edda' if is_healthy else '#f8d7da'
            return format_html('<span style="background: {}; color: {}; padding: 4px 12px; border-radius: 20px; font-size: 12px; font-weight: 500;">🔬 {}</span>', 
                              bg, color, obj.DiseaseName.replace('_', ' '))
        except Exception:
            return '—'
    disease_badge.short_description = 'Disease'

    def confidence_display(self, obj):
        try:
            if obj.ConfidenceLevel is None:
                return '—'
            pct = int(obj.ConfidenceLevel * 100)
            if pct >= 75:
                color = '#28a745'
                icon = '✓'
            elif pct >= 50:
                color = '#fd7e14'
                icon = '⚠'
            else:
                color = '#dc3545'
                icon = '✗'
            return format_html('<span style="color: {}; font-weight: bold;">{} {:.0f}%</span>', color, icon, obj.ConfidenceLevel * 100)
        except Exception:
            return '—'
    confidence_display.short_description = 'Confidence'

    def severity_badge(self, obj):
        try:
            colors = {'mild': '#17a2b8', 'moderate': '#fd7e14', 'severe': '#dc3545'}
            bg_colors = {'mild': '#d1ecf1', 'moderate': '#fff3cd', 'severe': '#f8d7da'}
            color = colors.get(obj.severity, '#6c757d')
            bg = bg_colors.get(obj.severity, '#e9ecef')
            icons = {'mild': '🟢', 'moderate': '🟡', 'severe': '🔴'}
            icon = icons.get(obj.severity, '⚪')
            display = obj.get_severity_display() if obj.severity else '—'
            return format_html('<span style="background: {}; color: {}; padding: 4px 12px; border-radius: 20px; font-size: 11px;">{} {}</span>', 
                              bg, color, icon, display)
        except Exception:
            return '—'
    severity_badge.short_description = 'Severity'

    def date_diagnosed_badge(self, obj):
        try:
            if obj.DateDiagnosed:
                return format_html('<span style="color: #6c757d;">📅 {}</span>', obj.DateDiagnosed.strftime('%d %b %Y'))
        except Exception:
            return '—'
        return '—'
    date_diagnosed_badge.short_description = 'Date'


# ============================================================
# --- SECTION 3: TREATMENT DATABASE ---
# ============================================================

@admin.register(Treatment)
class TreatmentAdmin(InteractiveAdmin):
    list_display = ('TreatmentID', 'disease_badge', 'pesticide_display', 'dosage_display')
    search_fields = ('DiseaseName', 'RecommendedPesticide')
    list_per_page = 25

    def disease_badge(self, obj):
        try:
            return format_html('<span style="background: #f8d7da; color: #dc2626; padding: 4px 12px; border-radius: 20px; font-weight: 500;">💊 {}</span>', 
                              obj.DiseaseName if obj.DiseaseName else '—')
        except Exception:
            return '—'
    disease_badge.short_description = 'Disease'

    def pesticide_display(self, obj):
        try:
            return format_html('<code style="background: #f3f4f6; padding: 4px 8px; border-radius: 6px;">🧪 {}</code>', obj.RecommendedPesticide)
        except Exception:
            return '—'
    pesticide_display.short_description = 'Pesticide'

    def dosage_display(self, obj):
        try:
            return format_html('<span style="font-family: monospace;">📊 {}</span>', obj.Dosage)
        except Exception:
            return '—'
    dosage_display.short_description = 'Dosage'


# ============================================================
# --- SECTION 4: KNOWLEDGE BASE ---
# ============================================================

@admin.register(KnowledgeBase)
class KnowledgeBaseAdmin(InteractiveAdmin):
    list_display = ('DiseaseName', 'has_causes', 'last_updated_badge')
    search_fields = ('DiseaseName',)
    list_per_page = 25
    
    fieldsets = (
        ('Disease Information', {
            'fields': ('DiseaseName',),
        }),
        ('Symptoms and Causes', {
            'fields': ('Symptoms', 'Causes'),
        }),
        ('Treatment Protocol', {
            'fields': ('TreatmentInfo',),
        }),
    )

    def has_causes(self, obj):
        try:
            if obj.Causes:
                return format_html('<span style="color: #10b981;">✓ Documented</span>')
        except Exception:
            return '—'
        return format_html('<span style="color: #ef4444;">✗ Missing</span>')
    has_causes.short_description = 'Has Causes'

    def last_updated_badge(self, obj):
        try:
            if obj.LastUpdated:
                return format_html('<span style="color: #6b7280; font-size: 11px;">🕒 {}</span>', 
                                  obj.LastUpdated.strftime('%d %b %Y'))
        except Exception:
            return '—'
        return '—'
    last_updated_badge.short_description = 'Last Updated'


# ============================================================
# --- SECTION 5: AI MODELS ---
# ============================================================

@admin.register(AIModel)
class AIModelAdmin(InteractiveAdmin):
    list_display = ('ModelID', 'Version', 'accuracy_display', 'last_trained_badge')
    list_per_page = 25
    
    def accuracy_display(self, obj):
        try:
            pct = obj.AccuracyRate * 100
            if pct >= 85:
                color = '#10b981'
                icon = '🚀'
            elif pct >= 70:
                color = '#f59e0b'
                icon = '📈'
            else:
                color = '#ef4444'
                icon = '⚠️'
            return format_html('<span style="color: {}; font-weight: 600;">{} {:.1f}%</span>', color, icon, pct)
        except Exception:
            return '—'
    accuracy_display.short_description = 'Accuracy'

    def last_trained_badge(self, obj):
        try:
            if obj.LastTrainedDate:
                return format_html('<span style="color: #6b7280; font-size: 11px;">🧠 {}</span>', 
                                  obj.LastTrainedDate.strftime('%d %b %Y'))
        except Exception:
            return '—'
        return '—'
    last_trained_badge.short_description = 'Last Trained'


# ============================================================
# --- HIDDEN MODELS (System Generated Only) ---
# ============================================================

# IMPORTANT: Import models first (done at top), then unregister

# TranslationCache - Hidden (system managed)
try:
    admin.site.unregister(TranslationCache)
except (admin.sites.NotRegistered, NameError):
    pass

# CropProfile - Hidden (managed through Plant model)
try:
    admin.site.unregister(CropProfile)
except (admin.sites.NotRegistered, NameError):
    pass

# Plant - Hidden (crop management UI)
try:
    admin.site.unregister(Plant)
except (admin.sites.NotRegistered, NameError):
    pass

# AppAlert - Hidden (system generated only)
try:
    admin.site.unregister(AppAlert)
except (admin.sites.NotRegistered, NameError):
    pass

# WeatherData - Hidden (system generated only)
try:
    admin.site.unregister(WeatherData)
except (admin.sites.NotRegistered, NameError):
    pass

# FarmerInsight - Hidden (auto-generated)
try:
    admin.site.unregister(FarmerInsight)
except (admin.sites.NotRegistered, NameError):
    pass

# GrowthJournalEntry - Hidden (user app only)
try:
    admin.site.unregister(GrowthJournalEntry)
except (admin.sites.NotRegistered, NameError):
    pass


# ============================================================
# --- FORCE HIDE ANY ROGUE MODELS ---
# ============================================================

# List of model names to ensure they're hidden
HIDE_MODELS = [
    'TranslationCache',
    'CropProfile',
    'Plant', 
    'AppAlert',
    'WeatherData',
    'FarmerInsight',
    'GrowthJournalEntry',
]

from django.apps import apps
for model_name in HIDE_MODELS:
    try:
        model = apps.get_model('api', model_name)
        if model in admin.site._registry:
            del admin.site._registry[model]
            print(f"✓ Force removed {model_name} from admin registry")
    except (LookupError, KeyError):
        pass
