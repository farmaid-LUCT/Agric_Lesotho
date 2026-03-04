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


import logging
import hashlib
from datetime import date

from django.contrib.auth import authenticate
from django.contrib.auth.tokens import default_token_generator
from django.contrib.sites.shortcuts import get_current_site
from django.core.mail import EmailMessage
from django.db.models import Q, Count
from django.http import HttpResponse
from django.shortcuts import render
from django.utils import timezone
from django.utils.encoding import force_bytes, force_str
from django.utils.http import urlsafe_base64_decode, urlsafe_base64_encode

from rest_framework import status
from rest_framework.authtoken.models import Token
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import (
    AppAlert, CropProfile, Diagnosis, FarmerInsight,
    Farmer, GrowthJournalEntry, KnowledgeBase, MarketPrice,
    PersonalizedRule, Plant, TranslationCache, Treatment,
    WeatherData, RuleMatchingService,
)
from .serializers import (
    AppAlertSerializer, CropProfileSerializer,
    WeatherDataSerializer, MarketPriceSerializer,
    GrowthJournalSerializer, FarmerInsightSerializer,
)

logger = logging.getLogger('api.rule_engine')
gps_logger = logging.getLogger('api.gps')


# ============================================================
# --- HELPER: SESOTHO TRANSLATION ---
# ============================================================
def _get_sesotho(disease_name: str, field: str, fallback: str) -> str:
    """
    Looks up Sesotho translation from TranslationCache by disease name.
    Falls back to English if admin hasn't filled in the translation yet.
    Also creates a blank cache record so admin can see it in the panel.
    """
    if not fallback or fallback in ("N/A", "Consult local expert"):
        return fallback

    cache = TranslationCache.objects.filter(disease_name_en__iexact=disease_name).first()

    if cache:
        value = getattr(cache, field, None)
        if value:
            return value

    # Auto-create empty record so admin sees it and can fill it in
    if not cache:
        TranslationCache.objects.get_or_create(
            disease_name_en=disease_name,
            defaults={'pesticide_st': '', 'dosage_st': '', 'steps_st': ''}
        )

    return fallback  # English fallback until admin translates


# ============================================================
# --- 1. AUTHENTICATION ---
# ============================================================
@api_view(['POST'])
@permission_classes([AllowAny])
def register_farmer(request):
    data = request.data
    try:
        if Farmer.objects.filter(email=data.get('email')).exists():
            return Response({'error': 'Email already exists'}, status=status.HTTP_400_BAD_REQUEST)

        user = Farmer.objects.create_user(
            username=data.get('email'),
            email=data.get('email'),
            password=data.get('password'),
            first_name=data.get('first_name', ''),
            last_name=data.get('last_name', ''),
            phone_number=data.get('phone_number', ''),
            district=data.get('district', ''),
            language_preferences=data.get('language_preferences', 'en'),
            experience_level=data.get('experience_level', 'beginner'),
        )
        user.is_active = False
        user.save()
        _send_activation_email(request, user)

        return Response({
            'status': 'success',
            'message': 'Verification email sent.',
            'email': user.email
        }, status=status.HTTP_201_CREATED)

    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


def _send_activation_email(request, user):
    current_site = get_current_site(request)
    uid = urlsafe_base64_encode(force_bytes(user.pk))
    token = default_token_generator.make_token(user)
    activation_link = f"http://{current_site.domain}/api/activate/{uid}/{token}/"
    mail_subject = 'Activate your FarmAid Lesotho Account'
    message = f"Dumela {user.first_name},\n\nPlease click the link below to verify your account:\n{activation_link}"
    EmailMessage(mail_subject, message, to=[user.email]).send()


@api_view(['POST'])
@permission_classes([AllowAny])
def resend_activation_email(request):
    email_addr = request.data.get('email')
    try:
        user = Farmer.objects.get(email=email_addr)
        if user.is_active:
            return Response({'error': 'Account already active.'}, status=400)
        _send_activation_email(request, user)
        return Response({'message': 'New activation link sent!'})
    except Farmer.DoesNotExist:
        return Response({'error': 'User not found.'}, status=404)


@api_view(['GET'])
@permission_classes([AllowAny])
def activate_account(request, uidb64, token):
    try:
        uid = force_str(urlsafe_base64_decode(uidb64))
        user = Farmer.objects.get(pk=uid)
    except (TypeError, ValueError, OverflowError, Farmer.DoesNotExist):
        user = None

    if user is not None and default_token_generator.check_token(user, token):
        user.is_active = True
        user.save()
        return render(request, 'api/activation_success.html')
    return HttpResponse("<h2>Activation link is invalid.</h2>", status=400)


@api_view(['POST'])
@permission_classes([AllowAny])
def login(request):
    email = request.data.get('email')
    password = request.data.get('password')
    user = authenticate(username=email, password=password)
    if user:
        if not user.is_active:
            return Response({'error': 'unverified'}, status=403)
        # Update last_active on every login
        user.last_active = timezone.now()
        user.save(update_fields=['last_active'])
        token, _ = Token.objects.get_or_create(user=user)
        return Response({
            'token': token.key,
            'farmerName': f"{user.first_name} {user.last_name}".strip(),
            'is_staff': user.is_staff,
            'experience_level': user.experience_level,
            'language_preferences': user.language_preferences,
            'onboarding_complete': user.onboarding_complete,
        })
    return Response({'error': 'Invalid credentials'}, status=401)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def change_password(request):
    user = request.user
    old_pw = request.data.get("old_password")
    new_pw = request.data.get("new_password")
    if not user.check_password(old_pw):
        return Response({"error": "Incorrect current password."}, status=400)
    user.set_password(new_pw)
    user.save()
    return Response({"status": "success", "message": "Password updated!"})


# ============================================================
# --- 2. PROFILE ---
# ============================================================
class ProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        u = request.user
        return Response({
            "first_name": u.first_name,
            "last_name": u.last_name,
            "full_name": f"{u.first_name} {u.last_name}".strip(),
            "email": u.email,
            "district": u.district,
            "phone_number": u.phone_number,
            "language_preferences": u.language_preferences,
            "experience_level": u.experience_level,
            "farm_size_hectares": u.farm_size_hectares,
            "profile_photo_url": u.profile_photo_url,
            "notification_diseases": u.notification_diseases,
            "notification_weather": u.notification_weather,
            "notification_market": u.notification_market,
            "onboarding_complete": u.onboarding_complete,
        })

    def patch(self, request):
        user = request.user
        # Whitelist of safely updatable fields
        allowed_fields = [
            'first_name', 'last_name', 'phone_number', 'district',
            'language_preferences', 'experience_level', 'farm_size_hectares',
            'profile_photo_url', 'notification_diseases', 'notification_weather',
            'notification_market', 'onboarding_complete',
        ]
        updated = []
        for field in allowed_fields:
            if field in request.data:
                setattr(user, field, request.data[field])
                updated.append(field)

        if updated:
            user.save(update_fields=updated)

        return Response({
            "status": "success",
            "farmerName": f"{user.first_name} {user.last_name}".strip(),
            "updated_fields": updated,
        })


# ============================================================
# --- 3. WEATHER ---
# ============================================================
class LatestWeatherView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        # Return weather for farmer's district if logged in, else latest overall
        district = None
        if request.user.is_authenticated:
            district = request.user.district

        if district:
            latest = WeatherData.objects.filter(district__iexact=district).order_by('-DateUpdated').first()
        else:
            latest = WeatherData.objects.order_by('-DateUpdated').first()

        if not latest:
            return Response({"error": "No weather data available"}, status=404)
        return Response(WeatherDataSerializer(latest).data)


# ============================================================
# --- 4. CROP PROFILES ---
# ============================================================
class CropProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        profiles = CropProfile.objects.filter(
            FarmerID=request.user, IsActive=True
        ).order_by('-CreatedAt')

        data = []
        for p in profiles:
            serialized = CropProfileSerializer(p).data
            # Attach computed properties for Flutter app
            serialized['days_since_planting'] = p.days_since_planting
            serialized['growth_stage_label'] = p.growth_stage_label
            data.append(serialized)

        return Response(data)

    def post(self, request):
        ser = CropProfileSerializer(data=request.data)
        if ser.is_valid():
            profile = ser.save(FarmerID=request.user)
            response_data = ser.data
            response_data['days_since_planting'] = profile.days_since_planting
            response_data['growth_stage_label'] = profile.growth_stage_label
            return Response(response_data, status=201)
        return Response(ser.errors, status=400)

    def patch(self, request):
        profile_id = request.data.get('ProfileID')
        profile = CropProfile.objects.filter(pk=profile_id, FarmerID=request.user).first()
        if not profile:
            return Response({'error': 'Profile not found'}, status=404)
        ser = CropProfileSerializer(profile, data=request.data, partial=True)
        if ser.is_valid():
            ser.save()
            return Response(ser.data)
        return Response(ser.errors, status=400)


# ============================================================
# --- 5. ALERTS ---
# ============================================================
class FarmerAlertsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        now = timezone.now()

        # Fetch alerts targeted to this farmer OR broadcast to their district
        # Exclude expired alerts
        alerts = AppAlert.objects.filter(
            Q(FarmerID=user) | Q(district_target__iexact=user.district),
            Q(expires_at__isnull=True) | Q(expires_at__gte=now)
        ).order_by('-priority', '-DateCreated')

        return Response(AppAlertSerializer(alerts, many=True).data)

    def post(self, request):
        # Mark all unread alerts as read
        AppAlert.objects.filter(FarmerID=request.user, IsRead=False).update(IsRead=True)
        return Response({'status': 'success'})


# ============================================================
# --- 6. CORE: AI SCAN + 8-FACTOR RULE ENGINE ---
# ============================================================
class SaveScanView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        try:
            user = request.user

            # Sync language preference if sent from Flutter
            incoming_lang = request.data.get('language') or request.data.get('lang')
            if incoming_lang in ['st', 'en']:
                user.language_preferences = incoming_lang
                user.save(update_fields=['language_preferences'])
            lang = user.language_preferences

            # --- 1. Extract scan data from Flutter request ---
            raw_label    = request.data.get('diseaseName') or "Healthy"
            clean_label  = raw_label.replace('___', ' ').replace('_', ' ').strip()
            image_url    = request.data.get('imageUrl') or request.data.get('ImageFile')
            confidence   = float(request.data.get('confidence') or 0.0)
            profile_id   = request.data.get('profileId')

            # --- 2. Live GPS data from geolocator (sent by Flutter) ---
            latitude     = request.data.get('latitude')
            longitude    = request.data.get('longitude')
            altitude     = request.data.get('altitude')
            gps_district = request.data.get('gps_district') or user.district or ''

            gps_logger.debug(
                f"Scan GPS: farmer={user.username}, district={gps_district}, "
                f"lat={latitude}, lon={longitude}, alt={altitude}"
            )

            if not image_url:
                return Response({'error': 'Supabase image URL is missing'}, status=400)

            # --- 3. Resolve crop profile ---
            target_profile = None
            if profile_id and str(profile_id).lower() != "null":
                target_profile = CropProfile.objects.filter(
                    pk=profile_id, FarmerID=user
                ).first()

            # --- 4. Save Plant with GPS coordinates ---
            new_plant = Plant.objects.create(
                FarmerID=user,
                CropProfile=target_profile,
                CropType=target_profile.VegetableType if target_profile else 'Vegetable',
                ImageFile=image_url,
                latitude=latitude,
                longitude=longitude,
                altitude_meters=altitude,
                gps_district=gps_district,
            )

            # --- 5. Save Diagnosis ---
            diagnosis = Diagnosis.objects.create(
                PlantID=new_plant,
                DiseaseName=clean_label,
                ConfidenceLevel=confidence,
            )

            # --- 6. Retrieve treatment ---
            treatment_query = Q(DiseaseName__iexact=clean_label) | Q(DiseaseName__iexact=raw_label)
            treat    = Treatment.objects.filter(treatment_query).first()
            kb_entry = KnowledgeBase.objects.filter(treatment_query).first()

            res_pesticide = treat.RecommendedPesticide if treat else "Consult local expert"
            res_dosage    = treat.Dosage if treat else "N/A"
            res_steps     = (
                treat.ApplicationSteps if treat and treat.ApplicationSteps
                else kb_entry.TreatmentInfo if kb_entry and kb_entry.TreatmentInfo
                else "Isolate plant immediately and consult an agronomist."
            )

            # --- 7. Apply Sesotho translation if needed ---
            res_disease = clean_label
            if lang == 'st':
                res_disease   = _get_sesotho(clean_label, 'disease_name_en', clean_label)
                res_pesticide = _get_sesotho(clean_label, 'pesticide_st', res_pesticide)
                res_dosage    = _get_sesotho(clean_label, 'dosage_st', res_dosage)
                res_steps     = _get_sesotho(clean_label, 'steps_st', res_steps)

            # --- 8. Run 8-Factor Personalized Rule Engine ---
            personalized_advice = None
            rule_match_info = None

            if target_profile and clean_label.lower() != 'healthy':
                # Get recent rainfall for this district from WeatherData
                weather = WeatherData.objects.filter(
                    district__iexact=gps_district
                ).order_by('-DateUpdated').first()
                rainfall_mm = weather.rainfall_last_7_days if weather else 0.0

                rule_result = RuleMatchingService.get_best_match(
                    disease_name=clean_label,
                    farmer=user,
                    crop_profile=target_profile,
                    gps_district=gps_district,
                    rainfall_mm=rainfall_mm,
                )

                logger.debug(
                    f"Rule match: farmer={user.username}, disease={clean_label}, "
                    f"found={rule_result['found']}, matched_on={rule_result.get('matched_on')}"
                )

                if rule_result['found']:
                    advice_text = rule_result['advice']

                    # Translate personalized advice to Sesotho if needed
                    if lang == 'st' and advice_text:
                        advice_text = _get_sesotho(clean_label, 'steps_st', advice_text)

                    personalized_advice = {
                        "ExpertAdvice": advice_text,
                        "category": rule_result['category'],
                    }
                    rule_match_info = rule_result['matched_on']

            # --- 9. Update FarmerInsight stats ---
            _update_farmer_insight(user, clean_label, target_profile)

            # --- 10. Schedule follow-up scan if disease detected ---
            if clean_label.lower() != 'healthy':
                from datetime import timedelta
                diagnosis.follow_up_date = date.today() + timedelta(days=7)
                diagnosis.save(update_fields=['follow_up_date'])

            return Response({
                'status': 'success',
                'diagnosis_id': diagnosis.DiagnosisID,
                'results': {
                    'disease': res_disease,
                    'pesticide': res_pesticide,
                    'dosage': res_dosage,
                    'steps': res_steps,
                },
                'personalized_advice': personalized_advice,
                'rule_matched_on': rule_match_info,
                'growth_stage': target_profile.growth_stage_label if target_profile else None,
            })

        except Exception as e:
            logger.error(f"SaveScanView error: {e}", exc_info=True)
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)


def _update_farmer_insight(user, disease_name: str, crop_profile):
    """
    Updates FarmerInsight after every scan.
    Called internally — not an API endpoint.
    """
    try:
        insight, _ = FarmerInsight.objects.get_or_create(FarmerID=user)
        insight.total_scans += 1
        insight.last_scan_date = timezone.now()

        is_healthy = disease_name.lower() == 'healthy'

        if is_healthy:
            insight.total_healthy_scans += 1
            insight.streak_healthy_days += 1
        else:
            insight.total_diseases_detected += 1
            insight.streak_healthy_days = 0  # Reset streak on disease detection

        # Update most scanned crop
        if crop_profile:
            crop_counts = (
                Plant.objects
                .filter(FarmerID=user, CropProfile__isnull=False)
                .values('CropType')
                .annotate(count=Count('CropType'))
                .order_by('-count')
                .first()
            )
            if crop_counts:
                insight.most_scanned_crop = crop_counts['CropType']

        # Update most common disease
        if not is_healthy:
            disease_counts = (
                Diagnosis.objects
                .filter(PlantID__FarmerID=user)
                .exclude(DiseaseName__iexact='healthy')
                .values('DiseaseName')
                .annotate(count=Count('DiseaseName'))
                .order_by('-count')
                .first()
            )
            if disease_counts:
                insight.most_common_disease = disease_counts['DiseaseName']

        # Update highest risk month
        current_month = timezone.now().month
        month_counts = (
            Diagnosis.objects
            .filter(PlantID__FarmerID=user)
            .exclude(DiseaseName__iexact='healthy')
            .extra(select={'month': "EXTRACT(MONTH FROM \"DateDiagnosed\")"})
            .values('month')
            .annotate(count=Count('DiagnosisID'))
            .order_by('-count')
            .first()
        )
        if month_counts:
            insight.highest_risk_month = int(month_counts['month'])

        insight.save()

    except Exception as e:
        logger.warning(f"FarmerInsight update failed for {user.username}: {e}")


# ============================================================
# --- 7. DIAGNOSIS FEEDBACK ---
# ============================================================
class DiagnosisFeedbackView(APIView):
    """
    Flutter app calls this after showing results so farmer
    can confirm or dispute the AI diagnosis.
    Also records treatment outcome on follow-up.
    """
    permission_classes = [IsAuthenticated]

    def patch(self, request, diagnosis_id):
        diagnosis = Diagnosis.objects.filter(
            DiagnosisID=diagnosis_id,
            PlantID__FarmerID=request.user
        ).first()

        if not diagnosis:
            return Response({'error': 'Diagnosis not found'}, status=404)

        allowed = ['farmer_feedback', 'severity', 'treatment_applied', 'treatment_outcome']
        for field in allowed:
            if field in request.data:
                setattr(diagnosis, field, request.data[field])
        diagnosis.save()

        return Response({'status': 'success', 'diagnosis_id': diagnosis.DiagnosisID})


# ============================================================
# --- 8. SCAN HISTORY ---
# ============================================================
class FarmerHistoryView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        plants = Plant.objects.filter(
            FarmerID=request.user
        ).select_related('CropProfile').order_by('-DateCaptured')

        history = []
        for p in plants:
            diag = Diagnosis.objects.filter(PlantID=p).first()
            if diag:
                history.append({
                    "plant_id": p.PlantID,
                    "crop": p.CropType,
                    "image": p.ImageFile,
                    "disease": diag.DiseaseName,
                    "confidence": f"{diag.ConfidenceLevel:.0%}",
                    "severity": diag.severity,
                    "farmer_feedback": diag.farmer_feedback,
                    "treatment_outcome": diag.treatment_outcome,
                    "gps_district": p.gps_district,
                    "growth_stage": p.CropProfile.growth_stage_label if p.CropProfile else None,
                    "date": p.DateCaptured.strftime("%d %b, %Y"),
                })
        return Response(history)


# ============================================================
# --- 9. REPORTS ---
# ============================================================
class FarmerReportsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        plants = Plant.objects.filter(
            FarmerID=request.user
        ).order_by('-DateCaptured')

        report_data = []
        for p in plants:
            diag = Diagnosis.objects.filter(PlantID=p).first()
            if diag:
                treat = Treatment.objects.filter(
                    DiseaseName__iexact=diag.DiseaseName
                ).first()
                report_data.append({
                    "FarmerID_id": request.user.id,
                    "ReportDate": p.DateCaptured.isoformat(),
                    "DiagnosisSummary": diag.DiseaseName.replace('_', ' ').upper(),
                    "Confidence": f"{diag.ConfidenceLevel:.0%}",
                    "Severity": diag.severity or "Not recorded",
                    "TreatmentOutcome": diag.treatment_outcome or "Pending",
                    "TreatmentSummary": treat.ApplicationSteps if treat else "Isolate plant immediately.",
                    "GPSDistrict": p.gps_district or "Unknown",
                    "ImageURL": p.ImageFile,
                })
        return Response(report_data)


# ============================================================
# --- 10. FARMER INSIGHT (Personalized Dashboard) ---
# ============================================================
class FarmerInsightView(APIView):
    """
    Returns personalized stats for the Flutter dashboard.
    Cards like: 'Your most common disease', 'Healthy streak', etc.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        insight, _ = FarmerInsight.objects.get_or_create(FarmerID=request.user)
        return Response(FarmerInsightSerializer(insight).data)


# ============================================================
# --- 11. GROWTH JOURNAL ---
# ============================================================
class GrowthJournalView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        profile_id = request.query_params.get('profile_id')
        entries = GrowthJournalEntry.objects.filter(FarmerID=request.user)
        if profile_id:
            entries = entries.filter(CropProfile__ProfileID=profile_id)
        return Response(GrowthJournalSerializer(entries, many=True).data)

    def post(self, request):
        profile_id = request.data.get('profile_id')
        profile = CropProfile.objects.filter(
            pk=profile_id, FarmerID=request.user
        ).first()
        if not profile:
            return Response({'error': 'Crop profile not found'}, status=404)

        entry = GrowthJournalEntry.objects.create(
            FarmerID=request.user,
            CropProfile=profile,
            title=request.data.get('title', ''),
            body=request.data.get('body', ''),
            photo_url=request.data.get('photo_url'),
            mood=request.data.get('mood', 'ok'),
            entry_date=request.data.get('entry_date', date.today()),
        )
        return Response(GrowthJournalSerializer(entry).data, status=201)

    def delete(self, request, entry_id):
        entry = GrowthJournalEntry.objects.filter(
            EntryID=entry_id, FarmerID=request.user
        ).first()
        if not entry:
            return Response({'error': 'Entry not found'}, status=404)
        entry.delete()
        return Response({'status': 'deleted'})


# ============================================================
# --- 12. MARKET PRICES ---
# ============================================================
class MarketPriceView(APIView):
    """
    Returns market prices filtered by the farmer's district
    and only for crops they are actively growing.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user

        # Get crops this farmer is actively growing
        active_crops = CropProfile.objects.filter(
            FarmerID=user, IsActive=True
        ).values_list('VegetableType', flat=True)

        # Filter prices by their crops and district first, fallback to all
        prices = MarketPrice.objects.filter(
            vegetable_name__in=active_crops
        ).order_by('-date_recorded')

        district = request.query_params.get('district') or user.district
        if district:
            district_prices = prices.filter(district__iexact=district)
            if district_prices.exists():
                prices = district_prices

        return Response(MarketPriceSerializer(prices, many=True).data)
