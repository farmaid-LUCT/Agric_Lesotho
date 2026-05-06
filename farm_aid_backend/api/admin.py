# from django.contrib import admin
# from django.contrib.auth.admin import UserAdmin
# from django.utils.html import format_html
# from django.urls import reverse
# from django.utils import timezone
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
#         if obj:  # Editing an existing object
#             return self.readonly_fields + ('created_at', 'updated_at') if hasattr(self, 'readonly_fields') else ()
#         return self.readonly_fields


# # ============================================================
# # --- 1. FARMER (Enhanced Admin) ---
# # ============================================================
# @admin.register(Farmer)
# class FarmerAdmin(UserAdmin):
#     list_display = (
#         'username', 'display_name', 'email', 'display_phone', 'district',
#         'display_experience', 'display_notifications', 'status_badge', 'is_staff'
#     )
#     search_fields = ('username', 'email', 'first_name', 'last_name', 'district', 'phone_number')
#     list_filter = ('district', 'experience_level', 'language_preferences', 'is_active', 'is_staff')
#     list_per_page = 20
    
#     fieldsets = UserAdmin.fieldsets + (
#         ('🌾 FarmAid — Farmer Profile', {
#             'classes': ('wide',),
#             'fields': (
#                 'phone_number', 'district', 'language_preferences',
#                 'profile_photo_url', 'farm_size_hectares', 'experience_level',
#             ),
#         }),
#         ('🔔 Notification Preferences', {
#             'classes': ('collapse',),
#             'fields': (
#                 'notification_diseases', 'notification_weather', 'notification_market',
#             ),
#         }),
#         ('📱 App Status', {
#             'classes': ('collapse',),
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
#                 return format_html('<span style="font-weight: 600;">{}</span>', full_name)
#         except Exception:
#             return 'Error'
#         return '—'
#     display_name.short_description = 'Full Name'
#     display_name.admin_order_field = 'first_name'

#     def display_phone(self, obj):
#         try:
#             if obj.phone_number:
#                 return format_html('<code>{}</code>', obj.phone_number)
#         except Exception:
#             return 'Error'
#         return '—'
#     display_phone.short_description = 'Phone'

#     def display_experience(self, obj):
#         try:
#             colors = {'beginner': '#6c757d', 'intermediate': '#fd7e14', 'expert': '#28a745'}
#             color = colors.get(obj.experience_level, '#6c757d')
#             icons = {'beginner': '🌱', 'intermediate': '🌿', 'expert': '🌾'}
#             icon = icons.get(obj.experience_level, '🌱')
#             return format_html('<span style="color: {};">{} {}</span>', color, icon, obj.get_experience_level_display())
#         except Exception:
#             return 'Error'
#     display_experience.short_description = 'Experience'

#     def display_notifications(self, obj):
#         try:
#             badges = []
#             if obj.notification_diseases:
#                 badges.append('<span style="background: #dc3545; color: white; padding: 2px 6px; border-radius: 10px; font-size: 10px;">🦠 Disease</span>')
#             if obj.notification_weather:
#                 badges.append('<span style="background: #007bff; color: white; padding: 2px 6px; border-radius: 10px; font-size: 10px;">☁️ Weather</span>')
#             if obj.notification_market:
#                 badges.append('<span style="background: #28a745; color: white; padding: 2px 6px; border-radius: 10px; font-size: 10px;">💰 Market</span>')
#             return format_html(' '.join(badges) if badges else '—')
#         except Exception:
#             return 'Error'
#     display_notifications.short_description = 'Notifications'

#     def status_badge(self, obj):
#         try:
#             if obj.is_active:
#                 return format_html('<span style="background: #28a745; color: white; padding: 3px 8px; border-radius: 12px; font-size: 11px;">✓ Active</span>')
#         except Exception:
#             return 'Error'
#         return format_html('<span style="background: #dc3545; color: white; padding: 3px 8px; border-radius: 12px; font-size: 11px;">✗ Inactive</span>')
#     status_badge.short_description = 'Status'


# # ============================================================
# # --- 2. CROP PROFILE ---
# # ============================================================
# @admin.register(CropProfile)
# class CropProfileAdmin(BaseAdmin):
#     list_display = (
#         'ProfileID', 'farmer_link', 'VegetableType', 'soil_badge', 'irrigation_badge',
#         'growth_stage_badge', 'plot_size', 'IsActive', 'planting_date'
#     )
#     list_filter = ('VegetableType', 'SoilEnvironment', 'irrigation_method', 'IsActive')
#     search_fields = ('VegetableType', 'seed_variety', 'FarmerID__username')
#     list_select_related = ('FarmerID',)
    
#     def farmer_link(self, obj):
#         try:
#             if obj.FarmerID:
#                 url = reverse('admin:api_farmer_change', args=[obj.FarmerID.id])
#                 return format_html('<a href="{}" style="font-weight: 600;">{}</a>', url, obj.FarmerID.username)
#         except Exception:
#             return 'Error'
#         return '—'
#     farmer_link.short_description = 'Farmer'

#     def soil_badge(self, obj):
#         try:
#             colors = {
#                 'sandy': '#f4a460', 'clay': '#cd853f', 'loam': '#8b7355',
#                 'silt': '#a9a9a9', 'sandy_loam': '#deb887', 'clay_loam': '#bc8f8f'
#             }
#             color = colors.get(obj.SoilEnvironment, '#6c757d')
#             return format_html('<span style="background: {}; color: white; padding: 2px 8px; border-radius: 12px; font-size: 11px;">{}</span>', 
#                               color, obj.get_SoilEnvironment_display() if obj.SoilEnvironment else '—')
#         except Exception:
#             return 'Error'
#     soil_badge.short_description = 'Soil'

#     def irrigation_badge(self, obj):
#         try:
#             return format_html('<span>{}</span>', obj.get_irrigation_method_display() if obj.irrigation_method else '—')
#         except Exception:
#             return 'Error'
#     irrigation_badge.short_description = 'Irrigation'

#     def growth_stage_badge(self, obj):
#         try:
#             stage = obj.growth_stage_label
#             colors = {
#                 'Seedling': '#17a2b8', 'Vegetative': '#28a745', 
#                 'Flowering': '#fd7e14', 'Fruiting / Harvest': '#dc3545'
#             }
#             color = colors.get(stage, '#6c757d')
#             return format_html('<span style="background: {}; color: white; padding: 2px 8px; border-radius: 12px; font-size: 11px;">{}</span>', color, stage)
#         except Exception:
#             return 'Error'
#     growth_stage_badge.short_description = 'Growth Stage'

#     def plot_size(self, obj):
#         try:
#             if obj.plot_size_hectares:
#                 return format_html('<span style="font-weight: 600;">{} ha</span>', obj.plot_size_hectares)
#         except Exception:
#             return 'Error'
#         return '—'
#     plot_size.short_description = 'Plot Size'

#     def planting_date(self, obj):
#         try:
#             if obj.PlantingDate:
#                 days = obj.days_since_planting
#                 if days and days > 0:
#                     return format_html('{} <span style="color: #6c757d;">({} days)</span>', obj.PlantingDate, days)
#                 return obj.PlantingDate
#         except Exception:
#             return 'Error'
#         return '—'
#     planting_date.short_description = 'Planting Date'


# # ============================================================
# # --- 3. PLANT ---
# # ============================================================
# @admin.register(Plant)
# class PlantAdmin(BaseAdmin):
#     list_display = (
#         'PlantID', 'farmer_link', 'CropType', 'gps_district',
#         'location_preview', 'DateCaptured'
#     )
#     list_filter = ('CropType', 'gps_district')
#     search_fields = ('CropType', 'FarmerID__username', 'gps_district')
#     list_select_related = ('FarmerID', 'CropProfile')

#     def farmer_link(self, obj):
#         try:
#             if obj.FarmerID:
#                 url = reverse('admin:api_farmer_change', args=[obj.FarmerID.id])
#                 return format_html('<a href="{}">{}</a>', url, obj.FarmerID.username)
#         except Exception:
#             return 'Error'
#         return '—'
#     farmer_link.short_description = 'Farmer'

#     def location_preview(self, obj):
#         """Display GPS coordinates with robust validation and error handling"""
#         try:
#             lat = obj.latitude
#             lng = obj.longitude
            
#             # Check if values exist
#             if lat is not None and lng is not None:
#                 try:
#                     # Convert to float (handles both numbers and numeric strings)
#                     lat_val = float(lat)
#                     lng_val = float(lng)
                    
#                     # Validate latitude range (-90 to 90)
#                     if lat_val < -90 or lat_val > 90:
#                         return format_html(
#                             '<span style="color: #fd7e14;">⚠️ Lat {:.1f}° (invalid)</span>', 
#                             lat_val
#                         )
                    
#                     # Validate longitude range (-180 to 180)
#                     if lng_val < -180 or lng_val > 180:
#                         return format_html(
#                             '<span style="color: #fd7e14;">⚠️ Lng {:.1f}° (invalid)</span>', 
#                             lng_val
#                         )
                    
#                     # Check for suspicious values (likely altitude stored in lat field)
#                     if abs(lat_val) > 90 and lat_val > 500:
#                         return format_html(
#                             '<span style="color: #fd7e14;">⚠️ Lat looks like altitude ({:.0f}m)</span>', 
#                             lat_val
#                         )
                    
#                     # Valid coordinates
#                     return format_html(
#                         '<span style="font-family: monospace; color: #28a745;">✓ {:.6f}, {:.6f}</span>', 
#                         lat_val, lng_val
#                     )
#                 except (TypeError, ValueError) as e:
#                     return format_html(
#                         '<span style="color: #dc3545;">Invalid format ({})</span>', 
#                         str(lat) if lat else 'null'
#                     )
#             else:
#                 return format_html('<span style="color: #6c757d;">—</span>')
#         except Exception as e:
#             # Log the actual error for debugging
#             print(f"GPS Error for Plant {getattr(obj, 'PlantID', 'unknown')}: {e}")
#             return format_html('<span style="color: #dc3545;">Error</span>')
#     location_preview.short_description = 'GPS Coordinates'


# # ============================================================
# # --- 4. DIAGNOSIS ---
# # ============================================================
# @admin.register(Diagnosis)
# class DiagnosisAdmin(BaseAdmin):
#     list_display = (
#         'DiagnosisID', 'farmer_link', 'disease_badge', 'confidence_display',
#         'severity_badge', 'feedback_badge', 'treatment_status', 'follow_up_status'
#     )
#     list_filter = ('DiseaseName', 'severity', 'farmer_feedback', 'treatment_applied', 'treatment_outcome')
#     search_fields = ('DiseaseName', 'PlantID__FarmerID__username')
#     list_select_related = ('PlantID__FarmerID',)
#     readonly_fields = ('DateDiagnosed',)

#     def farmer_link(self, obj):
#         try:
#             if obj.PlantID and obj.PlantID.FarmerID:
#                 url = reverse('admin:api_farmer_change', args=[obj.PlantID.FarmerID.id])
#                 return format_html('<a href="{}" style="font-weight: 500;">{}</a>', url, obj.PlantID.FarmerID.username)
#         except Exception:
#             return 'Error'
#         return '—'
#     farmer_link.short_description = 'Farmer'

#     def disease_badge(self, obj):
#         try:
#             is_healthy = 'healthy' in obj.DiseaseName.lower()
#             color = '#28a745' if is_healthy else '#dc3545'
#             return format_html('<span style="background: {}; color: white; padding: 3px 8px; border-radius: 12px; font-size: 12px;">{}</span>', 
#                               color, obj.DiseaseName.replace('_', ' '))
#         except Exception:
#             return 'Error'
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
#             return 'Error'
#     confidence_display.short_description = 'Confidence'

#     def severity_badge(self, obj):
#         try:
#             colors = {'mild': '#17a2b8', 'moderate': '#fd7e14', 'severe': '#dc3545'}
#             color = colors.get(obj.severity, '#6c757d')
#             icons = {'mild': '🟢', 'moderate': '🟡', 'severe': '🔴'}
#             icon = icons.get(obj.severity, '⚪')
#             return format_html('<span style="color: {};">{} {}</span>', color, icon, obj.get_severity_display() if obj.severity else '—')
#         except Exception:
#             return 'Error'
#     severity_badge.short_description = 'Severity'

#     def feedback_badge(self, obj):
#         try:
#             if obj.farmer_feedback:
#                 return format_html('<span>{}</span>', obj.get_farmer_feedback_display())
#         except Exception:
#             return 'Error'
#         return format_html('<span style="color: #6c757d;">⏳ Pending</span>')
#     feedback_badge.short_description = 'Feedback'

#     def treatment_status(self, obj):
#         try:
#             if obj.treatment_applied:
#                 if obj.treatment_outcome:
#                     outcomes = {'recovered': '✅ Recovered', 'no_change': '🟡 No Change', 'worsened': '🔴 Worsened'}
#                     return format_html('<span style="color: #28a745;">✓ Applied - {}</span>', outcomes.get(obj.treatment_outcome, obj.treatment_outcome))
#                 return format_html('<span style="color: #17a2b8;">✓ Applied</span>')
#         except Exception:
#             return 'Error'
#         return format_html('<span style="color: #6c757d;">○ Not Applied</span>')
#     treatment_status.short_description = 'Treatment'

#     def follow_up_status(self, obj):
#         try:
#             if obj.follow_up_date:
#                 today = timezone.now().date()
#                 if obj.follow_up_date < today:
#                     return format_html('<span style="color: #dc3545;">🔴 Overdue ({})</span>', obj.follow_up_date)
#                 elif obj.follow_up_date == today:
#                     return format_html('<span style="color: #fd7e14;">🟡 Today</span>')
#                 else:
#                     return format_html('<span style="color: #28a745;">🟢 {}</span>', obj.follow_up_date)
#         except Exception:
#             return 'Error'
#         return '—'
#     follow_up_status.short_description = 'Follow-up'


# # ============================================================
# # --- 5. TREATMENT ---
# # ============================================================
# @admin.register(Treatment)
# class TreatmentAdmin(BaseAdmin):
#     list_display = ('TreatmentID', 'disease_badge', 'pesticide_display', 'dosage_display', 'has_calculations')
#     search_fields = ('DiseaseName', 'RecommendedPesticide')
    
#     def disease_badge(self, obj):
#         try:
#             return format_html('<span style="font-weight: 600; color: #1B5E20;">{}</span>', obj.DiseaseName if obj.DiseaseName else '—')
#         except Exception:
#             return 'Error'
#     disease_badge.short_description = 'Disease'

#     def pesticide_display(self, obj):
#         try:
#             return format_html('<span style="font-family: monospace;">{}</span>', obj.RecommendedPesticide)
#         except Exception:
#             return 'Error'
#     pesticide_display.short_description = 'Pesticide'

#     def dosage_display(self, obj):
#         try:
#             return format_html('<code>{}</code>', obj.Dosage)
#         except Exception:
#             return 'Error'
#     dosage_display.short_description = 'Dosage'

#     def has_calculations(self, obj):
#         try:
#             if obj.dosage_per_hectare_g:
#                 return format_html('<span style="color: #28a745;">✓ {}g/ha</span>', obj.dosage_per_hectare_g)
#         except Exception:
#             return 'Error'
#         return format_html('<span style="color: #6c757d;">—</span>')
#     has_calculations.short_description = 'Dosage/ha'


# # ============================================================
# # --- 6. APP ALERT ---
# # ============================================================
# @admin.register(AppAlert)
# class AppAlertAdmin(BaseAdmin):
#     list_display = (
#         'AlertID', 'farmer_link', 'alert_type_badge', 'priority_badge',
#         'title_preview', 'read_status', 'expiry_status', 'DateCreated'
#     )
#     list_filter = ('alert_type', 'priority', 'IsRead', 'district_target')
#     search_fields = ('Title', 'Message', 'FarmerID__username')
#     list_select_related = ('FarmerID',)

#     def farmer_link(self, obj):
#         try:
#             if obj.FarmerID:
#                 url = reverse('admin:api_farmer_change', args=[obj.FarmerID.id])
#                 return format_html('<a href="{}">{}</a>', url, obj.FarmerID.username)
#             if obj.district_target:
#                 return format_html('<span style="color: #6c757d;">📡 {} (broadcast)</span>', obj.district_target)
#         except Exception:
#             return 'Error'
#         return '—'
#     farmer_link.short_description = 'Target'

#     def alert_type_badge(self, obj):
#         try:
#             return format_html('<span>{}</span>', obj.get_alert_type_display())
#         except Exception:
#             return 'Error'
#     alert_type_badge.short_description = 'Type'

#     def priority_badge(self, obj):
#         try:
#             colors = {'low': '#17a2b8', 'medium': '#fd7e14', 'high': '#dc3545'}
#             color = colors.get(obj.priority, '#6c757d')
#             icons = {'low': '🔵', 'medium': '🟡', 'high': '🔴'}
#             icon = icons.get(obj.priority, '⚪')
#             return format_html('<span style="color: {};">{} {}</span>', color, icon, obj.get_priority_display())
#         except Exception:
#             return 'Error'
#     priority_badge.short_description = 'Priority'

#     def title_preview(self, obj):
#         try:
#             return format_html('<span style="font-weight: 500;">{}</span>', obj.Title[:50] + ('...' if len(obj.Title) > 50 else ''))
#         except Exception:
#             return 'Error'
#     title_preview.short_description = 'Title'

#     def read_status(self, obj):
#         try:
#             if obj.IsRead:
#                 return format_html('<span style="color: #28a745;">✓ Read</span>')
#         except Exception:
#             return 'Error'
#         return format_html('<span style="color: #dc3545; font-weight: bold;">● Unread</span>')
#     read_status.short_description = 'Status'

#     def expiry_status(self, obj):
#         try:
#             if obj.expires_at:
#                 if obj.expires_at < timezone.now():
#                     return format_html('<span style="color: #6c757d;">Expired</span>')
#                 return format_html('<span style="color: #28a745;">Active</span>')
#         except Exception:
#             return 'Error'
#         return '—'
#     expiry_status.short_description = 'Valid'


# # ============================================================
# # --- 7. WEATHER DATA ---
# # ============================================================
# @admin.register(WeatherData)
# class WeatherDataAdmin(BaseAdmin):
#     list_display = ('WeatherID', 'district', 'temperature_display', 'humidity_display', 
#                    'rainfall_display', 'alert_status', 'DateUpdated')
#     list_filter = ('district',)
#     search_fields = ('district',)

#     def temperature_display(self, obj):
#         try:
#             icon = '🔥' if obj.Temperature > 30 else '❄️' if obj.Temperature < 10 else '🌡️'
#             return format_html('<span>{}</span>', obj.Temperature)
#         except Exception:
#             return 'Error'
#     temperature_display.short_description = 'Temp (°C)'

#     def humidity_display(self, obj):
#         try:
#             color = '#28a745' if obj.Humidity < 70 else '#fd7e14' if obj.Humidity < 85 else '#dc3545'
#             return format_html('<span style="color: {};">{}%</span>', color, obj.Humidity)
#         except Exception:
#             return 'Error'
#     humidity_display.short_description = 'Humidity'

#     def rainfall_display(self, obj):
#         try:
#             if obj.Rainfall > 50:
#                 return format_html('<span style="color: #dc3545;">🌧️ {}mm</span>', obj.Rainfall)
#             return format_html('{}mm', obj.Rainfall)
#         except Exception:
#             return 'Error'
#     rainfall_display.short_description = 'Rainfall'

#     def alert_status(self, obj):
#         try:
#             if obj.AlertMessage:
#                 return format_html('<span style="color: #fd7e14;">⚠️ Alert</span>')
#         except Exception:
#             return 'Error'
#         return format_html('<span style="color: #28a745;">✓ Normal</span>')
#     alert_status.short_description = 'Alert'


# # ============================================================
# # --- 8. KNOWLEDGE BASE ---
# # ============================================================
# @admin.register(KnowledgeBase)
# class KnowledgeBaseAdmin(BaseAdmin):
#     list_display = ('DiseaseName', 'has_causes', 'causes_preview', 'treatment_preview', 'LastUpdated')
#     search_fields = ('DiseaseName',)
#     fieldsets = (
#         ('Disease Information', {
#             'fields': ('DiseaseName',),
#             'classes': ('wide',),
#         }),
#         ('Symptoms & Causes', {
#             'fields': ('Symptoms', 'Causes'),
#             'classes': ('wide',),
#         }),
#         ('Treatment Information', {
#             'fields': ('TreatmentInfo',),
#             'classes': ('wide',),
#         }),
#     )

#     def has_causes(self, obj):
#         try:
#             if obj.Causes:
#                 return format_html('<span style="color: #28a745;">✓ Yes</span>')
#         except Exception:
#             return 'Error'
#         return format_html('<span style="color: #dc3545;">✗ Missing</span>')
#     has_causes.short_description = 'Has Causes'

#     def causes_preview(self, obj):
#         try:
#             if obj.Causes:
#                 preview = obj.Causes[:60]
#                 return format_html('<span style="color: #6c757d; font-size: 11px;">{}{}</span>', 
#                                   preview, '...' if len(obj.Causes) > 60 else '')
#         except Exception:
#             return 'Error'
#         return format_html('<span style="color: #dc3545;">Not populated</span>')
#     causes_preview.short_description = 'Causes Preview'

#     def treatment_preview(self, obj):
#         try:
#             if obj.TreatmentInfo:
#                 preview = obj.TreatmentInfo[:60]
#                 return format_html('<span style="color: #6c757d; font-size: 11px;">{}{}</span>', 
#                                   preview, '...' if len(obj.TreatmentInfo) > 60 else '')
#         except Exception:
#             return 'Error'
#         return '—'
#     treatment_preview.short_description = 'Treatment Preview'


# # ============================================================
# # --- 9. AI MODEL ---
# # ============================================================
# @admin.register(AIModel)
# class AIModelAdmin(BaseAdmin):
#     list_display = ('ModelID', 'Version', 'accuracy_display', 'LastTrainedDate')
    
#     def accuracy_display(self, obj):
#         try:
#             pct = obj.AccuracyRate * 100
#             color = '#28a745' if pct >= 85 else '#fd7e14' if pct >= 70 else '#dc3545'
#             return format_html('<span style="color: {}; font-weight: bold;">{:.1f}%</span>', color, pct)
#         except Exception:
#             return 'Error'
#     accuracy_display.short_description = 'Accuracy'


# # ============================================================
# # --- 10. TRANSLATION CACHE ---
# # ============================================================
# @admin.register(TranslationCache)
# class TranslationCacheAdmin(BaseAdmin):
#     list_display = ('disease_name_en', 'pesticide_st', 'dosage_st', 'has_full_translation', 'last_updated')
#     search_fields = ('disease_name_en',)

#     def has_full_translation(self, obj):
#         try:
#             if obj.pesticide_st and obj.dosage_st and obj.steps_st:
#                 return format_html('<span style="color: #28a745;">✓ Complete</span>')
#             missing = []
#             if not obj.pesticide_st: missing.append('pesticide')
#             if not obj.dosage_st: missing.append('dosage')
#             if not obj.steps_st: missing.append('steps')
#             return format_html('<span style="color: #dc3545;">⚠️ Missing: {}</span>', ', '.join(missing))
#         except Exception:
#             return 'Error'
#     has_full_translation.short_description = 'Translation Status'


# # ============================================================
# # --- 11. FARMER INSIGHT ---
# # ============================================================
# @admin.register(FarmerInsight)
# class FarmerInsightAdmin(BaseAdmin):
#     list_display = (
#         'farmer_link', 'total_scans_display', 'healthy_ratio', 
#         'most_scanned_crop', 'most_common_disease', 'streak_badge'
#     )
#     search_fields = ('FarmerID__username',)
#     readonly_fields = (
#         'total_scans', 'total_diseases_detected', 'total_healthy_scans',
#         'most_scanned_crop', 'most_common_disease', 'highest_risk_month',
#         'last_scan_date', 'streak_healthy_days', 'last_updated'
#     )

#     def farmer_link(self, obj):
#         try:
#             if obj.FarmerID:
#                 url = reverse('admin:api_farmer_change', args=[obj.FarmerID.id])
#                 return format_html('<a href="{}" style="font-weight: 600;">{}</a>', url, obj.FarmerID.username)
#         except Exception:
#             return 'Error'
#         return '—'
#     farmer_link.short_description = 'Farmer'

#     def total_scans_display(self, obj):
#         try:
#             return format_html('<span style="font-weight: bold; font-size: 14px;">{}</span>', obj.total_scans or 0)
#         except Exception:
#             return '0'
#     total_scans_display.short_description = 'Total Scans'

#     def healthy_ratio(self, obj):
#         try:
#             if obj.total_scans and obj.total_scans > 0:
#                 ratio = (obj.total_healthy_scans / obj.total_scans) * 100
#                 color = '#28a745' if ratio >= 70 else '#fd7e14' if ratio >= 40 else '#dc3545'
#                 return format_html('<span style="color: {};">{:.0f}% ({}/{})</span>', color, ratio, obj.total_healthy_scans or 0, obj.total_scans)
#         except Exception:
#             return 'Error'
#         return '—'
#     healthy_ratio.short_description = 'Healthy Ratio'

#     def streak_badge(self, obj):
#         try:
#             days = obj.streak_healthy_days or 0
#             if days >= 7:
#                 return format_html('<span style="color: #28a745;">🔥 {} days</span>', days)
#             return format_html('{} days', days)
#         except Exception:
#             return '—'
#     streak_badge.short_description = 'Healthy Streak'


# # ============================================================
# # --- 12. GROWTH JOURNAL ---
# # ============================================================
# @admin.register(GrowthJournalEntry)
# class GrowthJournalEntryAdmin(BaseAdmin):
#     list_display = (
#         'EntryID', 'farmer_link', 'crop_link', 'title_preview',
#         'mood_icon', 'entry_date', 'DateCreated'
#     )
#     list_filter = ('mood', 'entry_date')
#     search_fields = ('title', 'body', 'FarmerID__username')
#     list_select_related = ('FarmerID', 'CropProfile')

#     def farmer_link(self, obj):
#         try:
#             if obj.FarmerID:
#                 url = reverse('admin:api_farmer_change', args=[obj.FarmerID.id])
#                 return format_html('<a href="{}">{}</a>', url, obj.FarmerID.username)
#         except Exception:
#             return 'Error'
#         return '—'
#     farmer_link.short_description = 'Farmer'

#     def crop_link(self, obj):
#         try:
#             if obj.CropProfile:
#                 url = reverse('admin:api_cropprofile_change', args=[obj.CropProfile.ProfileID])
#                 return format_html('<a href="{}">{}</a>', url, obj.CropProfile.VegetableType)
#         except Exception:
#             return 'Error'
#         return '—'
#     crop_link.short_description = 'Crop'

#     def title_preview(self, obj):
#         try:
#             return format_html('<span style="font-weight: 500;">{}</span>', obj.title[:40] + ('...' if len(obj.title) > 40 else ''))
#         except Exception:
#             return 'Error'
#     title_preview.short_description = 'Title'

#     def mood_icon(self, obj):
#         try:
#             icons = {'great': '😊 Great', 'ok': '😐 OK', 'concerned': '😟 Concerned', 'bad': '😢 Bad'}
#             return format_html('<span>{}</span>', icons.get(obj.mood, '😐'))
#         except Exception:
#             return 'Error'
#     mood_icon.short_description = 'Mood'


from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django.utils.html import format_html
from django.urls import reverse
from django.utils import timezone
from django.contrib.admin import SimpleListFilter
from django.shortcuts import render
from django.urls import path
from .models import (
    Farmer, KnowledgeBase, AIModel, Diagnosis,
    Treatment, TranslationCache,
    CropProfile, Plant, AppAlert, WeatherData,
    FarmerInsight, GrowthJournalEntry,
)

# Unregister default models
from django.contrib.auth.models import Group
from allauth.account.models import EmailAddress
from allauth.socialaccount.models import SocialAccount, SocialToken, SocialApp

# Custom admin site header
admin.site.site_header = "FarmAid Management System"
admin.site.site_title = "FarmAid Admin Portal"
admin.site.index_title = "Administration Dashboard"
admin.site.site_url = "/"


# ============================================================
# --- CUSTOM ADMIN SITE WITH STYLED DASHBOARD ---
# ============================================================

class FarmAidAdminSite(admin.AdminSite):
    """Custom admin site with professional dashboard"""
    
    def get_urls(self):
        urls = super().get_urls()
        custom_urls = [
            path('', self.admin_view(self.dashboard), name='index'),
        ]
        return custom_urls + urls
    
    def dashboard(self, request):
        """Render professional dashboard"""
        context = {
            'title': 'Dashboard',
            'site_header': self.site_header,
            'site_title': self.site_title,
            **self.each_context(request),
        }
        return render(request, 'admin/dashboard.html', context)
    
    def index(self, request, extra_context=None):
        return self.dashboard(request)


# Replace default admin site
admin_site = FarmAidAdminSite(name='farmaid_admin')


# ============================================================
# --- HELPER CLASSES ---
# ============================================================

class BaseAdmin(admin.ModelAdmin):
    """Base admin with professional styling"""
    save_on_top = True
    list_per_page = 25
    actions_on_top = True
    actions_on_bottom = True
    show_full_result_count = True


class ReadOnlyAdmin(BaseAdmin):
    """Read-only admin (view only)"""
    def has_add_permission(self, request):
        return False
    
    def has_change_permission(self, request, obj=None):
        return False
    
    def has_delete_permission(self, request, obj=None):
        return False
    
    def has_view_permission(self, request, obj=None):
        return True


# ============================================================
# --- CUSTOM FILTERS ---
# ============================================================

class StatusFilter(SimpleListFilter):
    title = 'Account Status'
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

@admin.register(Farmer, site=admin_site)
class FarmerAdmin(UserAdmin, BaseAdmin):
    list_display = (
        'username', 'full_name', 'email', 'phone_number', 'district',
        'experience_level', 'account_status', 'last_activity'
    )
    search_fields = ('username', 'email', 'first_name', 'last_name', 'district', 'phone_number')
    list_filter = ('district', 'experience_level', 'is_active', 'is_staff', StatusFilter)
    list_per_page = 25
    
    fieldsets = UserAdmin.fieldsets + (
        ('Farmer Profile', {
            'classes': ('wide',),
            'fields': (
                'phone_number', 'district', 'language_preferences',
                'profile_photo_url', 'farm_size_hectares', 'experience_level',
            ),
        }),
        ('Notification Preferences', {
            'classes': ('collapse',),
            'fields': (
                'notification_diseases', 'notification_weather', 'notification_market',
            ),
        }),
        ('Application Status', {
            'classes': ('collapse',),
            'fields': ('onboarding_complete', 'last_active'),
        }),
    )

    add_fieldsets = UserAdmin.add_fieldsets + (
        ('Farmer Profile', {
            'fields': (
                'email', 'phone_number', 'district',
                'language_preferences', 'experience_level',
            ),
        }),
    )

    def full_name(self, obj):
        name = f"{obj.first_name} {obj.last_name}".strip()
        return name or '—'
    full_name.short_description = 'Full Name'
    full_name.admin_order_field = 'first_name'

    def account_status(self, obj):
        if obj.is_active:
            return format_html(
                '<span class="status-active" style="display: inline-block; padding: 4px 10px; border-radius: 4px; font-size: 11px; font-weight: 500; background: #e8f5e9; color: #2e7d32;">Active</span>'
            )
        return format_html(
            '<span class="status-inactive" style="display: inline-block; padding: 4px 10px; border-radius: 4px; font-size: 11px; font-weight: 500; background: #ffebee; color: #c62828;">Inactive</span>'
        )
    account_status.short_description = 'Status'

    def last_activity(self, obj):
        if obj.last_active:
            days = (timezone.now() - obj.last_active).days
            if days <= 1:
                return format_html('<span style="color: #2e7d32;">Recent</span>')
            elif days <= 7:
                return format_html('<span style="color: #ed6c02;">{} days ago</span>', days)
            return format_html('<span style="color: #6c757d;">{} days ago</span>', days)
        return '—'
    last_activity.short_description = 'Last Active'
    
    class Media:
        css = {
            'all': ('admin/css/custom-hover.css',)
        }


# ============================================================
# --- SECTION 2: PLANT MANAGEMENT (READ ONLY) ---
# ============================================================

@admin.register(Plant, site=admin_site)
class PlantAdmin(ReadOnlyAdmin):
    list_display = (
        'id', 'farmer_name', 'crop_type', 'district',
        'gps_coordinates', 'captured_date'
    )
    list_filter = ('CropType', 'gps_district')
    search_fields = ('CropType', 'FarmerID__username', 'gps_district')
    list_select_related = ('FarmerID', 'CropProfile')
    list_per_page = 25

    def farmer_name(self, obj):
        if obj.FarmerID:
            url = reverse('admin:api_farmer_change', args=[obj.FarmerID.id])
            return format_html(
                '<a href="{}" class="hover-link" style="color: #1976d2; text-decoration: none;">{}</a>',
                url, obj.FarmerID.username
            )
        return '—'
    farmer_name.short_description = 'Farmer'

    def crop_type(self, obj):
        return obj.CropType or '—'
    crop_type.short_description = 'Crop Type'

    def district(self, obj):
        return obj.gps_district or '—'
    district.short_description = 'District'

    def gps_coordinates(self, obj):
        lat, lng = obj.latitude, obj.longitude
        if lat is not None and lng is not None:
            return format_html(
                '<code style="background: #f5f5f5; padding: 4px 8px; border-radius: 4px; font-size: 11px;">{:.6f}, {:.6f}</code>',
                float(lat), float(lng)
            )
        return '—'
    gps_coordinates.short_description = 'GPS Coordinates'

    def captured_date(self, obj):
        if obj.DateCaptured:
            return obj.DateCaptured.strftime('%d %b %Y, %H:%M')
        return '—'
    captured_date.short_description = 'Capture Date'


# ============================================================
# --- SECTION 3: DIAGNOSTICS (READ ONLY) ---
# ============================================================

@admin.register(Diagnosis, site=admin_site)
class DiagnosisAdmin(ReadOnlyAdmin):
    list_display = (
        'id', 'farmer_name', 'disease_name', 'confidence',
        'severity_level', 'diagnosis_date'
    )
    list_filter = ('DiseaseName', 'severity')
    search_fields = ('DiseaseName', 'PlantID__FarmerID__username')
    list_select_related = ('PlantID__FarmerID',)
    list_per_page = 25

    def farmer_name(self, obj):
        if obj.PlantID and obj.PlantID.FarmerID:
            url = reverse('admin:api_farmer_change', args=[obj.PlantID.FarmerID.id])
            return format_html(
                '<a href="{}" class="hover-link" style="color: #1976d2; text-decoration: none;">{}</a>',
                url, obj.PlantID.FarmerID.username
            )
        return '—'
    farmer_name.short_description = 'Farmer'

    def disease_name(self, obj):
        return obj.DiseaseName.replace('_', ' ') if obj.DiseaseName else '—'
    disease_name.short_description = 'Disease'

    def confidence(self, obj):
        if obj.ConfidenceLevel:
            pct = obj.ConfidenceLevel * 100
            if pct >= 75:
                style = 'color: #2e7d32;'
            elif pct >= 50:
                style = 'color: #ed6c02;'
            else:
                style = 'color: #c62828;'
            return format_html('<span style="{}; font-weight: 500;">{:.0f}%</span>', style, pct)
        return '—'
    confidence.short_description = 'Confidence'

    def severity_level(self, obj):
        levels = {
            'mild': ('#e3f2fd', '#1976d2', 'Mild'),
            'moderate': ('#fff3e0', '#ed6c02', 'Moderate'),
            'severe': ('#ffebee', '#c62828', 'Severe')
        }
        if obj.severity and obj.severity in levels:
            bg, color, label = levels[obj.severity]
            return format_html(
                '<span style="display: inline-block; padding: 4px 10px; border-radius: 4px; font-size: 11px; font-weight: 500; background: {}; color: {};">{}</span>',
                bg, color, label
            )
        return '—'
    severity_level.short_description = 'Severity'

    def diagnosis_date(self, obj):
        if obj.DateDiagnosed:
            return obj.DateDiagnosed.strftime('%d %b %Y')
        return '—'
    diagnosis_date.short_description = 'Date'


# ============================================================
# --- SECTION 4: WEATHER DATA (READ ONLY) ---
# ============================================================

@admin.register(WeatherData, site=admin_site)
class WeatherDataAdmin(ReadOnlyAdmin):
    list_display = (
        'id', 'district_name', 'temperature', 'humidity',
        'rainfall', 'alert', 'record_date'
    )
    list_filter = ('district',)
    search_fields = ('district',)
    list_per_page = 25

    def district_name(self, obj):
        return obj.district or '—'
    district_name.short_description = 'District'

    def temperature(self, obj):
        temp = obj.Temperature
        if temp > 30:
            color = '#c62828'
        elif temp < 10:
            color = '#1976d2'
        else:
            color = '#2e7d32'
        return format_html('<span style="color: {}; font-weight: 500;">{}°C</span>', color, temp)
    temperature.short_description = 'Temperature'

    def humidity(self, obj):
        return f"{obj.Humidity}%"
    humidity.short_description = 'Humidity'

    def rainfall(self, obj):
        return f"{obj.Rainfall} mm"
    rainfall.short_description = 'Rainfall'

    def alert(self, obj):
        if obj.AlertMessage:
            return format_html(
                '<span style="display: inline-block; padding: 4px 10px; border-radius: 4px; font-size: 11px; background: #fff3e0; color: #ed6c02;">⚠ {}</span>',
                obj.AlertMessage[:30]
            )
        return format_html(
            '<span style="color: #6c757d;">Normal</span>'
        )
    alert.short_description = 'Alert Status'

    def record_date(self, obj):
        if obj.DateUpdated:
            return obj.DateUpdated.strftime('%d %b %Y, %H:%M')
        return '—'
    record_date.short_description = 'Recorded'


# ============================================================
# --- SECTION 5: TREATMENT DATABASE ---
# ============================================================

@admin.register(Treatment, site=admin_site)
class TreatmentAdmin(BaseAdmin):
    list_display = ('id', 'disease', 'pesticide', 'dosage')
    search_fields = ('DiseaseName', 'RecommendedPesticide')
    list_per_page = 25

    def disease(self, obj):
        return obj.DiseaseName or '—'
    disease.short_description = 'Disease'

    def pesticide(self, obj):
        return obj.RecommendedPesticide
    pesticide.short_description = 'Pesticide'

    def dosage(self, obj):
        return obj.Dosage
    dosage.short_description = 'Dosage'


# ============================================================
# --- SECTION 6: KNOWLEDGE BASE ---
# ============================================================

@admin.register(KnowledgeBase, site=admin_site)
class KnowledgeBaseAdmin(BaseAdmin):
    list_display = ('disease', 'has_causes', 'last_updated')
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

    def disease(self, obj):
        return obj.DiseaseName
    disease.short_description = 'Disease'

    def has_causes(self, obj):
        if obj.Causes:
            return format_html('<span style="color: #2e7d32;">✓ Documented</span>')
        return format_html('<span style="color: #c62828;">✗ Missing</span>')
    has_causes.short_description = 'Causes'

    def last_updated(self, obj):
        if obj.LastUpdated:
            return obj.LastUpdated.strftime('%d %b %Y')
        return '—'
    last_updated.short_description = 'Last Updated'


# ============================================================
# --- SECTION 7: AI MODELS ---
# ============================================================

@admin.register(AIModel, site=admin_site)
class AIModelAdmin(BaseAdmin):
    list_display = ('id', 'version', 'accuracy', 'trained_date')
    list_per_page = 25

    def accuracy(self, obj):
        pct = obj.AccuracyRate * 100
        if pct >= 85:
            color = '#2e7d32'
        elif pct >= 70:
            color = '#ed6c02'
        else:
            color = '#c62828'
        return format_html('<span style="color: {}; font-weight: 500;">{:.1f}%</span>', color, pct)
    accuracy.short_description = 'Accuracy'

    def trained_date(self, obj):
        if obj.LastTrainedDate:
            return obj.LastTrainedDate.strftime('%d %b %Y')
        return '—'
    trained_date.short_description = 'Last Trained'


# ============================================================
# --- SECTION 8: TRANSLATION CACHE ---
# ============================================================

@admin.register(TranslationCache, site=admin_site)
class TranslationCacheAdmin(BaseAdmin):
    list_display = ('disease', 'pesticide', 'dosage', 'updated')
    search_fields = ('disease_name_en',)
    list_per_page = 25

    def disease(self, obj):
        return obj.disease_name_en
    disease.short_description = 'Disease (English)'

    def pesticide(self, obj):
        return obj.pesticide_st or '—'
    pesticide.short_description = 'Pesticide (Sesotho)'

    def dosage(self, obj):
        return obj.dosage_st or '—'
    dosage.short_description = 'Dosage (Sesotho)'

    def updated(self, obj):
        if obj.last_updated:
            return obj.last_updated.strftime('%d %b %Y')
        return '—'
    updated.short_description = 'Last Updated'


# ============================================================
# --- HIDDEN MODELS (System Managed) ---
# ============================================================

# AppAlert - System generated only
try:
    admin_site.unregister(AppAlert)
except:
    pass

# CropProfile - Managed through Plant model
try:
    admin_site.unregister(CropProfile)
except:
    pass

# FarmerInsight - Auto-generated
try:
    admin_site.unregister(FarmerInsight)
except:
    pass

# GrowthJournalEntry - User application only
try:
    admin_site.unregister(GrowthJournalEntry)
except:
    pass
