# from rest_framework import status
# from rest_framework.response import Response
# from rest_framework.decorators import api_view, permission_classes
# from rest_framework.views import APIView
# from rest_framework.permissions import IsAuthenticated, AllowAny
# from rest_framework.authtoken.models import Token
# from django.contrib.auth import authenticate
# from django.db.models import Q
# from datetime import date

# # Email Verification & Activation Imports
# from django.contrib.sites.shortcuts import get_current_site
# from django.utils.encoding import force_bytes, force_str
# from django.utils.http import urlsafe_base64_encode, urlsafe_base64_decode
# from django.core.mail import EmailMessage
# from django.contrib.auth.tokens import default_token_generator
# from django.shortcuts import render
# from django.http import HttpResponse

# from .models import (
#     Farmer, Plant, Diagnosis, Treatment, 
#     CropProfile, AppAlert, WeatherData, PersonalizedRule, KnowledgeBase,
#     TranslationCache
# )
# from .serializers import CropProfileSerializer, AppAlertSerializer, WeatherDataSerializer

# # --- 1. AUTHENTICATION & SECURITY MODULE ---

# @api_view(['POST'])
# @permission_classes([AllowAny])
# def register_farmer(request):
#     data = request.data
#     try:
#         if Farmer.objects.filter(email=data.get('email')).exists():
#             return Response({'error': 'Email already exists'}, status=status.HTTP_400_BAD_REQUEST)
        
#         user = Farmer.objects.create_user(
#             username=data.get('email'), 
#             email=data.get('email'),
#             password=data.get('password'),
#             first_name=data.get('first_name', ''),
#             last_name=data.get('last_name', ''),
#             phone_number=data.get('phone_number', ''),
#             location=data.get('location', ''),
#             language_preferences=data.get('language_preferences', 'en')
#         )
#         user.is_active = False 
#         user.save()
#         send_activation_email(request, user)

#         return Response({
#             'status': 'success',
#             'message': 'Verification email sent.',
#             'email': user.email
#         }, status=status.HTTP_201_CREATED)
#     except Exception as e:
#         return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# def send_activation_email(request, user):
#     current_site = get_current_site(request)
#     uid = urlsafe_base64_encode(force_bytes(user.pk))
#     token = default_token_generator.make_token(user)
#     activation_link = f"http://{current_site.domain}/api/activate/{uid}/{token}/"
    
#     mail_subject = 'Activate your FarmAid Lesotho Account'
#     message = f"Dumela {user.first_name},\n\nPlease click link to verify: {activation_link}"
#     email = EmailMessage(mail_subject, message, to=[user.email])
#     email.send()

# @api_view(['POST'])
# @permission_classes([AllowAny])
# def resend_activation_email(request):
#     email_addr = request.data.get('email')
#     try:
#         user = Farmer.objects.get(email=email_addr)
#         if user.is_active:
#             return Response({'error': 'Account already active.'}, status=400)
#         send_activation_email(request, user)
#         return Response({'message': 'New activation link sent!'})
#     except Farmer.DoesNotExist:
#         return Response({'error': 'User not found.'}, status=404)

# @api_view(['GET'])
# @permission_classes([AllowAny])
# def activate_account(request, uidb64, token):
#     try:
#         uid = force_str(urlsafe_base64_decode(uidb64))
#         user = Farmer.objects.get(pk=uid)
#     except (TypeError, ValueError, OverflowError, Farmer.DoesNotExist):
#         user = None

#     if user is not None and default_token_generator.check_token(user, token):
#         user.is_active = True
#         user.save()
#         return render(request, 'api/activation_success.html')
#     else:
#         return HttpResponse("<h2>Activation link is invalid.</h2>", status=400)

# @api_view(['POST'])
# @permission_classes([AllowAny])
# def login_farmer(request):
#     email = request.data.get('email')
#     password = request.data.get('password')
#     user = authenticate(username=email, password=password)
#     if user:
#         if not user.is_active:
#             return Response({'error': 'unverified'}, status=403)
#         token, _ = Token.objects.get_or_create(user=user)
#         return Response({
#             'token': token.key,
#             'farmerName': f"{user.first_name} {user.last_name}".strip(),
#             'is_staff': user.is_staff 
#         })
#     return Response({'error': 'Invalid credentials'}, status=401)

# @api_view(['POST'])
# @permission_classes([IsAuthenticated])
# def change_password(request):
#     user = request.user
#     old_pw = request.data.get("old_password")
#     new_pw = request.data.get("new_password")
#     if not user.check_password(old_pw):
#         return Response({"error": "Incorrect current password."}, status=400)
#     user.set_password(new_pw)
#     user.save()
#     return Response({"status": "success", "message": "Password updated!"})

# # --- 2. PROFILE & WEATHER ---

# class ProfileView(APIView):
#     permission_classes = [IsAuthenticated]
#     def get(self, request):
#         u = request.user
#         return Response({
#             "first_name": u.first_name, 
#             "last_name": u.last_name, 
#             "email": u.email, 
#             "location": u.location, 
#             "phone_number": u.phone_number, 
#             "language_preferences": u.language_preferences
#         })

#     def patch(self, request):
#         user = request.user
#         for attr, value in request.data.items():
#             if hasattr(user, attr): setattr(user, attr, value)
#         user.save()
#         return Response({"status": "success", "farmerName": f"{user.first_name} {user.last_name}"})

# class LatestWeatherView(APIView):
#     permission_classes = [AllowAny] 
#     def get(self, request):
#         latest = WeatherData.objects.order_by('-DateUpdated').first()
#         return Response(WeatherDataSerializer(latest).data) if latest else Response({"error": "No data"}, status=404)

# # --- 3. CROP PROFILES & ALERTS ---

# class CropProfileView(APIView):
#     permission_classes = [IsAuthenticated]
    
#     def get(self, request):
#         profiles = CropProfile.objects.filter(FarmerID=request.user, IsActive=True)
#         return Response(CropProfileSerializer(profiles, many=True).data)

#     def post(self, request):
#         ser = CropProfileSerializer(data=request.data)
#         if ser.is_valid():
#             # FIXED: Explicitly return the generated ProfileID from the instance
#             profile = ser.save(FarmerID=request.user)
#             return Response({
#                 "status": "success",
#                 "ProfileID": profile.ProfileID, # Matches your model key
#                 "id": profile.ProfileID,        # Helper for Flutter camelCase
#                 "VegetableType": profile.VegetableType,
#                 "PlantingDate": profile.PlantingDate,
#                 "IsActive": profile.IsActive
#             }, status=status.HTTP_201_CREATED)
#         return Response(ser.errors, status=status.HTTP_400_BAD_REQUEST)

# class FarmerAlertsView(APIView):
#     permission_classes = [IsAuthenticated]
#     def get(self, request):
#         user_dist = request.user.location or ""
#         alerts = AppAlert.objects.filter(Q(FarmerID=request.user) | Q(Message__icontains=user_dist)).order_by('-DateCreated')
#         return Response(AppAlertSerializer(alerts, many=True).data)
    
#     def post(self, request):
#         AppAlert.objects.filter(FarmerID=request.user, IsRead=False).update(IsRead=True)
#         return Response({'status': 'success'})

# # --- 4. AI SCAN & REPORTS (ENHANCED PERSONALIZATION) ---

# class SaveScanView(APIView):
#     permission_classes = [IsAuthenticated]

#     def _get_manual_sesotho_lookup(self, english_disease_name):
#         """Direct database lookup for Sesotho translations from TranslationCache."""
#         try:
#             cache = TranslationCache.objects.filter(disease_name_en__iexact=english_disease_name).first()
#             if cache:
#                 return {
#                     'pesticide': cache.pesticide_st,
#                     'dosage': cache.dosage_st,
#                     'steps': cache.steps_st
#                 }
#         except Exception:
#             pass
#         return None

#     def post(self, request):
#         try:
#             # 1. Capture and Clean Data
#             raw_label = request.data.get('diseaseName') or request.data.get('DiseaseName') or "Healthy"
#             clean_label = raw_label.replace('___', ' ').replace('_', ' ').strip()
            
#             image_url = request.data.get('imageUrl') or request.data.get('image_url') or request.data.get('ImageFile')
#             confidence = request.data.get('confidence') or request.data.get('ConfidenceLevel') or 0.0
#             profile_id = request.data.get('profileId') or request.data.get('ProfileID')
#             lang = request.user.language_preferences

#             if not image_url:
#                 return Response({'error': 'Image URL is missing'}, status=400)

#             # Link to the specific Vegetable Profile
#             target_profile = None
#             if profile_id and str(profile_id).lower() not in ["null", "", "none"]:
#                 target_profile = CropProfile.objects.filter(ProfileID=profile_id, FarmerID=request.user).first()

#             # 2. SAVE TO DATABASE
#             new_plant = Plant.objects.create(
#                 FarmerID=request.user, 
#                 CropProfile=target_profile, 
#                 ImageFile=image_url,
#                 CropType=target_profile.VegetableType if target_profile else 'Vegetable'
#             )
#             Diagnosis.objects.create(PlantID=new_plant, DiseaseName=clean_label, ConfidenceLevel=float(confidence))

#             # 3. TREATMENT QUERY (ENGLISH BASELINE)
#             treat = Treatment.objects.filter(DiseaseName__iexact=clean_label).first()
#             kb_entry = KnowledgeBase.objects.filter(DiseaseName__iexact=clean_label).first()

#             res_disease = clean_label
#             res_pesticide = treat.RecommendedPesticide if treat else "Consult local expert"
#             res_dosage = treat.Dosage if treat else "N/A"
#             res_steps = treat.ApplicationSteps if treat else (kb_entry.TreatmentInfo if kb_entry else "Isolate plant.")

#             # 4. MANUAL TRANSLATION LOOKUP (Sesotho)
#             if lang == 'st':
#                 st_lookup = self._get_manual_sesotho_lookup(clean_label)
#                 if st_lookup:
#                     res_pesticide = st_lookup['pesticide'] or res_pesticide
#                     res_dosage = st_lookup['dosage'] or res_dosage
#                     res_steps = st_lookup['steps'] or res_steps
#                 else:
#                     res_steps = f"Phetolelo ha e eo polokelong ea rona bakeng sa: {clean_label}"

#             # 5. PERSONALIZED LOGIC (Age & Soil Specific)
#             personalized_data = []
#             age_days = None
            
#             if target_profile and target_profile.PlantingDate:
#                 age_days = (date.today() - target_profile.PlantingDate).days
                
#                 # Fetch rules matching Disease + Age Window
#                 rules = PersonalizedRule.objects.filter(
#                     DiseaseName__iexact=clean_label,
#                     MinDaysSincePlanting__lte=age_days,
#                     MaxDaysSincePlanting__gte=age_days
#                 )

#                 # Filter by soil type if applicable
#                 if target_profile.SoilEnvironment:
#                     rules = rules.filter(
#                         Q(TriggerSoilType__iexact=target_profile.SoilEnvironment) |
#                         Q(TriggerSoilType__isnull=True) | Q(TriggerSoilType="")
#                     )

#                 for r in rules:
#                     personalized_data.append({
#                         "ExpertAdvice": r.ExpertAdvice,
#                         "RuleType": "Stage-Specific" if r.MinDaysSincePlanting > 0 else "General"
#                     })

#             return Response({
#                 'status': 'success',
#                 'results': {
#                     'disease': res_disease,
#                     'pesticide': res_pesticide,
#                     'dosage': res_dosage,
#                     'steps': res_steps
#                 },
#                 'personalized_rules': personalized_data,
#                 'crop_info': {
#                     'age_days': age_days,
#                     'vegetable': target_profile.VegetableType if target_profile else "Vegetable",
#                     'profile_id': profile_id
#                 }
#             })
            
#         except Exception as e:
#             return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

# class FarmerHistoryView(APIView):
#     permission_classes = [IsAuthenticated]
#     def get(self, request):
#         plants = Plant.objects.filter(FarmerID=request.user).order_by('-DateCaptured')
#         history = []
#         for p in plants:
#             diag = Diagnosis.objects.filter(PlantID=p).first()
#             if diag:
#                 history.append({
#                     "plant_id": p.PlantID, 
#                     "crop": p.CropProfile.VegetableType if p.CropProfile else p.CropType, 
#                     "image": p.ImageFile, 
#                     "disease": diag.DiseaseName, 
#                     "date": p.DateCaptured.strftime("%d %b, %Y")
#                 })
#         return Response(history)

# class FarmerReportsView(APIView):
#     permission_classes = [IsAuthenticated]
#     def get(self, request):
#         plants = Plant.objects.filter(FarmerID=request.user).order_by('-DateCaptured')
#         report_data = []
#         for p in plants:
#             diag = Diagnosis.objects.filter(PlantID=p).first()
#             if diag:
#                 treat = Treatment.objects.filter(DiseaseName__iexact=diag.DiseaseName).first()
#                 report_data.append({
#                     "FarmerID_id": request.user.id,
#                     "ReportDate": p.DateCaptured.isoformat(),
#                     "DiagnosisSummary": diag.DiseaseName.replace('_', ' ').upper(),
#                     "TreatmentSummary": treat.ApplicationSteps if treat else "Isolate plant immediately.",
#                     "ImageURL": p.ImageFile
#                 })
#         return Response(report_data)


from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django.utils.html import format_html
from .models import (
    Farmer, KnowledgeBase, AIModel, Diagnosis,
    Treatment, PersonalizedRule, TranslationCache,
    CropProfile, Plant, AppAlert, WeatherData,
    FarmerInsight, GrowthJournalEntry, MarketPrice,
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
# --- 11. PERSONALIZED RULE ENGINE ---
# ============================================================
@admin.register(PersonalizedRule)
class PersonalizedRuleAdmin(admin.ModelAdmin):
    list_display = (
        'RuleID', 'DiseaseName', 'TriggerDistrict', 'TriggerSoilType',
        'TriggerIrrigation', 'TriggerCropVariety', 'TriggerSeason',
        'TriggerRainfallLevel', 'growth_stage_range',
        'RecommendationCategory', 'priority_score', 'short_advice'
    )
    list_filter = (
        'DiseaseName', 'TriggerDistrict', 'TriggerSoilType',
        'TriggerIrrigation', 'TriggerSeason', 'TriggerRainfallLevel',
        'RecommendationCategory',
    )
    search_fields = ('DiseaseName', 'ExpertAdvice', 'TriggerCropVariety')
    ordering = ('-priority_score',)

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

    def growth_stage_range(self, obj):
        return f"Day {obj.MinDaysSincePlanting} – {obj.MaxDaysSincePlanting}"
    growth_stage_range.short_description = 'Growth Stage (Days)'

    def short_advice(self, obj):
        return f"{obj.ExpertAdvice[:60]}..." if len(obj.ExpertAdvice) > 60 else obj.ExpertAdvice
    short_advice.short_description = 'Advice Preview'


# ============================================================
# --- 12. FARMER INSIGHT ---
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
# --- 13. GROWTH JOURNAL ---
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


# ============================================================
# --- 14. MARKET PRICE ---
# ============================================================
@admin.register(MarketPrice)
class MarketPriceAdmin(admin.ModelAdmin):
    list_display = (
        'PriceID', 'vegetable_name', 'market_name', 'district',
        'price_per_kg', 'currency', 'price_trend', 'date_recorded'
    )
    list_filter = ('vegetable_name', 'district', 'price_trend')
    search_fields = ('vegetable_name', 'market_name', 'district')
    ordering = ('-date_recorded',)
