# from django.contrib import admin
# from django.contrib.auth.admin import UserAdmin
# from django.utils.html import format_html
# from django.urls import reverse
# from django.utils import timezone
# from django.contrib.admin import SimpleListFilter
# from .models import (
#     Farmer, KnowledgeBase, AIModel, Diagnosis,
#     Treatment, TranslationCache,
#     CropProfile, Plant, AppAlert, WeatherData,
#     FarmerInsight, GrowthJournalEntry,
# )

# # Unregister default models that might cause duplicates
# from django.contrib.auth.models import Group
# from allauth.account.models import EmailAddress
# from allauth.socialaccount.models import SocialAccount, SocialToken, SocialApp

# # Custom admin site header and title
# admin.site.site_header = "🌱 FarmAid Management System"
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
#     list_editable = ()
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
#             ('active', '✓ Active'),
#             ('inactive', '✗ Inactive'),
#         )
    
#     def queryset(self, request, queryset):
#         if self.value() == 'active':
#             return queryset.filter(is_active=True)
#         if self.value() == 'inactive':
#             return queryset.filter(is_active=False)
#         return queryset


# # ============================================================
# # --- SECTION 1: USER MANAGEMENT 👥 ---
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
#     list_editable = ()
    
#     fieldsets = UserAdmin.fieldsets + (
#         ('🌾 FarmAid — Farmer Profile', {
#             'classes': ('wide', 'collapse'),
#             'fields': (
#                 'phone_number', 'district', 'language_preferences',
#                 'profile_photo_url', 'farm_size_hectares', 'experience_level',
#             ),
#         }),
#         ('🔔 Notification Preferences', {
#             'classes': ('wide', 'collapse'),
#             'fields': (
#                 'notification_diseases', 'notification_weather', 'notification_market',
#             ),
#         }),
#         ('📱 App Status', {
#             'classes': ('wide', 'collapse'),
#             'fields': ('onboarding_complete', 'last_active'),
#         }),
#     )

#     add_fieldsets = UserAdmin.add_fieldsets + (
#         ('🌾 FarmAid — Farmer Profile', {
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
#                 return format_html('<code style="background: #f0f2f0; padding: 2px 6px; border-radius: 6px;">{}</code>', obj.phone_number)
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
#                 return format_html('<span style="background: linear-gradient(135deg, #28a745, #20c997); color: white; padding: 4px 12px; border-radius: 20px; font-size: 11px; font-weight: 600;">✓ Active</span>')
#         except Exception:
#             return '—'
#         return format_html('<span style="background: #dc3545; color: white; padding: 4px 12px; border-radius: 20px; font-size: 11px; font-weight: 600;">✗ Inactive</span>')
#     status_badge.short_description = 'Status'

#     def last_active_badge(self, obj):
#         try:
#             if obj.last_active:
#                 days_ago = (timezone.now() - obj.last_active).days
#                 if days_ago <= 1:
#                     return format_html('<span style="color: #28a745;">🟢 Recently active</span>')
#                 elif days_ago <= 7:
#                     return format_html('<span style="color: #fd7e14;">🟡 {} days ago</span>', days_ago)
#                 else:
#                     return format_html('<span style="color: #6c757d;">⚪ {} days ago</span>', days_ago)
#         except Exception:
#             return '—'
#         return '—'
#     last_active_badge.short_description = 'Last Active'


# # ============================================================
# # --- SECTION 2: CROP MANAGEMENT 🌾 ---
# # ============================================================

# @admin.register(Plant)
# class PlantAdmin(InteractiveAdmin):
#     list_display = (
#         'PlantID', 'farmer_link', 'crop_type_badge', 'gps_district',
#         'location_preview', 'date_captured_badge'
#     )
#     list_filter = ('CropType', 'gps_district')
#     search_fields = ('CropType', 'FarmerID__username', 'gps_district')
#     list_select_related = ('FarmerID', 'CropProfile')
#     list_per_page = 25

#     def farmer_link(self, obj):
#         try:
#             if obj.FarmerID:
#                 url = reverse('admin:api_farmer_change', args=[obj.FarmerID.id])
#                 return format_html('<a href="{}" style="color: #2d6a4f; font-weight: 500; text-decoration: none;">👨‍🌾 {}</a>', url, obj.FarmerID.username)
#         except Exception:
#             return '—'
#         return '—'
#     farmer_link.short_description = 'Farmer'

#     def crop_type_badge(self, obj):
#         try:
#             return format_html('<span style="background: #e8f5e9; color: #2e7d32; padding: 4px 12px; border-radius: 20px; font-size: 12px; font-weight: 500;">🌿 {}</span>', obj.CropType)
#         except Exception:
#             return '—'
#     crop_type_badge.short_description = 'Crop Type'

#     def location_preview(self, obj):
#         try:
#             lat = obj.latitude
#             lng = obj.longitude
            
#             if lat is not None and lng is not None:
#                 try:
#                     lat_str = str(lat).strip()
#                     lng_str = str(lng).strip()
                    
#                     import re
#                     lat_match = re.search(r'-?\d+\.?\d*(?:[eE][-+]?\d+)?', lat_str)
#                     lng_match = re.search(r'-?\d+\.?\d*(?:[eE][-+]?\d+)?', lng_str)
                    
#                     if lat_match and lng_match:
#                         lat_val = float(lat_match.group())
#                         lng_val = float(lng_match.group())
                        
#                         if -90 <= lat_val <= 90 and -180 <= lng_val <= 180:
#                             return format_html(
#                                 '<span style="font-family: monospace; background: #f8f9fa; padding: 4px 8px; border-radius: 6px;">📍 {:.6f}, {:.6f}</span>', 
#                                 lat_val, lng_val
#                             )
#                 except:
#                     pass
#             return format_html('<span style="color: #6c757d;">📍 No GPS</span>')
#         except Exception:
#             return format_html('<span style="color: #6c757d;">—</span>')
#     location_preview.short_description = 'GPS Coordinates'

#     def date_captured_badge(self, obj):
#         try:
#             if obj.DateCaptured:
#                 date_str = obj.DateCaptured.strftime('%d %b %Y')
#                 return format_html('<span style="color: #6c757d; font-size: 11px;">📅 {}</span>', date_str)
#         except Exception:
#             return '—'
#         return '—'
#     date_captured_badge.short_description = 'Date Captured'


# # ============================================================
# # --- SECTION 3: DIAGNOSTICS & HEALTH 🔬 (READ ONLY) ---
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
#                 return format_html('<a href="{}" style="color: #2d6a4f;">👨‍🌾 {}</a>', url, obj.PlantID.FarmerID.username)
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
#                 icon = '✅'
#             elif pct >= 50:
#                 color = '#fd7e14'
#                 icon = '⚠️'
#             else:
#                 color = '#dc3545'
#                 icon = '❌'
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
#                 return format_html('<span style="color: #6c757d;">📅 {}</span>', obj.DateDiagnosed.strftime('%d %b %Y, %H:%M'))
#         except Exception:
#             return '—'
#         return '—'
#     date_diagnosed_badge.short_description = 'Date Diagnosed'


# # ============================================================
# # --- SECTION 4: WEATHER & ENVIRONMENT ☁️ (READ ONLY) ---
# # ============================================================

# @admin.register(WeatherData)
# class WeatherDataAdmin(ReadOnlyAdmin):
#     list_display = (
#         'WeatherID', 'district_badge', 'temperature_display', 'humidity_display', 
#         'rainfall_display', 'alert_status', 'date_updated_badge'
#     )
#     list_filter = ('district',)
#     search_fields = ('district',)
#     list_per_page = 25
    
#     def has_add_permission(self, request):
#         return False
    
#     def has_change_permission(self, request, obj=None):
#         return False
    
#     def has_delete_permission(self, request, obj=None):
#         return False

#     def district_badge(self, obj):
#         try:
#             return format_html('<span style="background: #e3f2fd; color: #1976d2; padding: 4px 12px; border-radius: 20px; font-size: 12px;">📍 {}</span>', 
#                               obj.district or '—')
#         except Exception:
#             return '—'
#     district_badge.short_description = 'District'

#     def temperature_display(self, obj):
#         try:
#             temp = obj.Temperature
#             if temp > 30:
#                 icon = '🔥'
#                 color = '#dc3545'
#             elif temp < 10:
#                 icon = '❄️'
#                 color = '#17a2b8'
#             else:
#                 icon = '🌡️'
#                 color = '#28a745'
#             return format_html('<span style="color: {}; font-weight: bold;">{} {}°C</span>', color, icon, temp)
#         except Exception:
#             return '—'
#     temperature_display.short_description = 'Temperature'

#     def humidity_display(self, obj):
#         try:
#             humidity = obj.Humidity
#             if humidity < 40:
#                 color = '#fd7e14'
#                 icon = '🔥'
#             elif humidity > 80:
#                 color = '#17a2b8'
#                 icon = '💧'
#             else:
#                 color = '#28a745'
#                 icon = '💨'
#             return format_html('<span style="color: {};">{} {}%</span>', color, icon, humidity)
#         except Exception:
#             return '—'
#     humidity_display.short_description = 'Humidity'

#     def rainfall_display(self, obj):
#         try:
#             rain = obj.Rainfall
#             if rain > 50:
#                 return format_html('<span style="color: #dc3545;">🌧️ {}mm (Heavy)</span>', rain)
#             elif rain > 20:
#                 return format_html('<span style="color: #fd7e14;">🌦️ {}mm (Moderate)</span>', rain)
#             elif rain > 0:
#                 return format_html('<span style="color: #28a745;">☔ {}mm (Light)</span>', rain)
#             else:
#                 return format_html('<span style="color: #6c757d;">☀️ {}mm (Dry)</span>', rain)
#         except Exception:
#             return '—'
#     rainfall_display.short_description = 'Rainfall'

#     def alert_status(self, obj):
#         try:
#             if obj.AlertMessage:
#                 return format_html('<span style="background: #fff3cd; color: #856404; padding: 4px 12px; border-radius: 20px; font-size: 11px;">⚠️ {}</span>', 
#                                   obj.AlertMessage[:30])
#             return format_html('<span style="background: #d4edda; color: #155724; padding: 4px 12px; border-radius: 20px; font-size: 11px;">✅ Normal</span>')
#         except Exception:
#             return '—'
#     alert_status.short_description = 'Alert Status'

#     def date_updated_badge(self, obj):
#         try:
#             if obj.DateUpdated:
#                 return format_html('<span style="color: #6c757d; font-size: 11px;">🕒 {}</span>', 
#                                   obj.DateUpdated.strftime('%d %b %Y, %H:%M'))
#         except Exception:
#             return '—'
#         return '—'
#     date_updated_badge.short_description = 'Last Updated'


# # ============================================================
# # --- SECTION 5: TREATMENT & KNOWLEDGE 📚 ---
# # ============================================================

# @admin.register(Treatment)
# class TreatmentAdmin(InteractiveAdmin):
#     list_display = ('TreatmentID', 'disease_badge', 'pesticide_display', 'dosage_display')
#     search_fields = ('DiseaseName', 'RecommendedPesticide')
#     list_per_page = 25

#     def disease_badge(self, obj):
#         try:
#             return format_html('<span style="background: #f8d7da; color: #721c24; padding: 4px 12px; border-radius: 20px; font-weight: 500;">💊 {}</span>', 
#                               obj.DiseaseName if obj.DiseaseName else '—')
#         except Exception:
#             return '—'
#     disease_badge.short_description = 'Disease'

#     def pesticide_display(self, obj):
#         try:
#             return format_html('<code style="background: #f0f2f0; padding: 4px 8px; border-radius: 6px;">🧪 {}</code>', obj.RecommendedPesticide)
#         except Exception:
#             return '—'
#     pesticide_display.short_description = 'Pesticide'

#     def dosage_display(self, obj):
#         try:
#             return format_html('<span style="font-family: monospace;">📊 {}</span>', obj.Dosage)
#         except Exception:
#             return '—'
#     dosage_display.short_description = 'Dosage'


# @admin.register(KnowledgeBase)
# class KnowledgeBaseAdmin(InteractiveAdmin):
#     list_display = ('DiseaseName', 'has_causes', 'last_updated_badge')
#     search_fields = ('DiseaseName',)
#     list_per_page = 25
    
#     fieldsets = (
#         ('📋 Disease Information', {
#             'fields': ('DiseaseName',),
#             'classes': ('wide',),
#         }),
#         ('🩺 Symptoms & Causes', {
#             'fields': ('Symptoms', 'Causes'),
#             'classes': ('wide',),
#         }),
#         ('💊 Treatment Information', {
#             'fields': ('TreatmentInfo',),
#             'classes': ('wide',),
#         }),
#     )

#     def has_causes(self, obj):
#         try:
#             if obj.Causes:
#                 return format_html('<span style="color: #28a745;">✓ Yes</span>')
#         except Exception:
#             return '—'
#         return format_html('<span style="color: #dc3545;">✗ Missing</span>')
#     has_causes.short_description = 'Has Causes'

#     def last_updated_badge(self, obj):
#         try:
#             if obj.LastUpdated:
#                 return format_html('<span style="color: #6c757d; font-size: 11px;">🕒 {}</span>', 
#                                   obj.LastUpdated.strftime('%d %b %Y'))
#         except Exception:
#             return '—'
#         return '—'
#     last_updated_badge.short_description = 'Last Updated'


# # ============================================================
# # --- SECTION 6: AI & TRANSLATION 🤖 ---
# # ============================================================

# @admin.register(AIModel)
# class AIModelAdmin(InteractiveAdmin):
#     list_display = ('ModelID', 'Version', 'accuracy_display', 'last_trained_badge')
#     list_per_page = 25
    
#     def accuracy_display(self, obj):
#         try:
#             pct = obj.AccuracyRate * 100
#             if pct >= 85:
#                 color = '#28a745'
#                 icon = '🚀'
#             elif pct >= 70:
#                 color = '#fd7e14'
#                 icon = '📈'
#             else:
#                 color = '#dc3545'
#                 icon = '⚠️'
#             return format_html('<span style="color: {}; font-weight: bold;">{} {:.1f}%</span>', color, icon, pct)
#         except Exception:
#             return '—'
#     accuracy_display.short_description = 'Accuracy'

#     def last_trained_badge(self, obj):
#         try:
#             if obj.LastTrainedDate:
#                 return format_html('<span style="color: #6c757d; font-size: 11px;">🧠 {}</span>', 
#                                   obj.LastTrainedDate.strftime('%d %b %Y'))
#         except Exception:
#             return '—'
#         return '—'
#     last_trained_badge.short_description = 'Last Trained'


# @admin.register(TranslationCache)
# class TranslationCacheAdmin(InteractiveAdmin):
#     list_display = ('disease_name_en', 'pesticide_st', 'dosage_st', 'last_updated_badge')
#     search_fields = ('disease_name_en',)
#     list_per_page = 25

#     def last_updated_badge(self, obj):
#         try:
#             if obj.last_updated:
#                 return format_html('<span style="color: #6c757d; font-size: 11px;">🔄 {}</span>', 
#                                   obj.last_updated.strftime('%d %b %Y'))
#         except Exception:
#             return '—'
#         return '—'
#     last_updated_badge.short_description = 'Last Updated'


# # ============================================================
# # --- HIDDEN MODELS (System Generated Only) ---
# # ============================================================

# # AppAlert - Hidden (system generated only)
# try:
#     admin.site.unregister(AppAlert)
# except:
#     pass

# # CropProfile - Hidden (managed through Plant model)
# try:
#     admin.site.unregister(CropProfile)
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
    # REMOVED: TranslationCache, CropProfile, Plant, AppAlert, WeatherData, FarmerInsight, GrowthJournalEntry
)

# Unregister default models that might cause duplicates
from django.contrib.auth.models import Group
from allauth.account.models import EmailAddress
from allauth.socialaccount.models import SocialAccount, SocialToken, SocialApp

# Custom admin site header and title
admin.site.site_header = "🌱 FarmAid Management System"
admin.site.site_title = "FarmAid Admin Portal"
admin.site.index_title = "Dashboard | FarmAid Agriculture Management"
admin.site.site_url = "/"

# Unregister to prevent duplicates
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
            ('active', '✓ Active'),
            ('inactive', '✗ Inactive'),
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
# --- HIDDEN MODELS (Not Displayed in Admin) ---
# ============================================================

# TranslationCache - Hidden (system managed)
try:
    admin.site.unregister(TranslationCache)
except:
    pass

# CropProfile - Hidden (managed through Plant model)
try:
    admin.site.unregister(CropProfile)
except:
    pass

# Plant - Hidden
try:
    admin.site.unregister(Plant)
except:
    pass

# AppAlert - Hidden (system generated only)
try:
    admin.site.unregister(AppAlert)
except:
    pass

# WeatherData - Hidden (system generated only)
try:
    admin.site.unregister(WeatherData)
except:
    pass

# FarmerInsight - Hidden (auto-generated)
try:
    admin.site.unregister(FarmerInsight)
except:
    pass

# GrowthJournalEntry - Hidden (user app only)
try:
    admin.site.unregister(GrowthJournalEntry)
except:
    pass
