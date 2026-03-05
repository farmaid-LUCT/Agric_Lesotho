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
from datetime import date, timedelta

from django.contrib.auth import authenticate, update_session_auth_hash
from django.contrib.auth.tokens import default_token_generator
from django.contrib.sites.shortcuts import get_current_site
from django.core.mail import EmailMessage
from django.db.models import Q
from django.http import HttpResponse
from django.utils import timezone
from django.utils.encoding import force_bytes, force_str
from django.utils.http import urlsafe_base64_encode, urlsafe_base64_decode

from rest_framework import status
from rest_framework.authtoken.models import Token
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import (
    AppAlert, CropProfile, Diagnosis, FarmerInsight,
    Farmer, Plant, MarketPrice, Treatment,
    WeatherData, RuleMatchingService, TranslationCache,
    GrowthJournalEntry
)
from .serializers import (
    AppAlertSerializer, CropProfileSerializer,
    WeatherDataSerializer, MarketPriceSerializer,
    FarmerInsightSerializer, GrowthJournalSerializer
)

logger = logging.getLogger('api.rule_engine')

# ============================================================
# --- HELPER: SESOTHO TRANSLATION (MANUAL LOOKUP TABLE) ---
# ============================================================
def _get_sesotho(disease_name: str, field: str, fallback: str) -> str:
    if not fallback or fallback in ("N/A", "Consult local expert"):
        return fallback

    cache = TranslationCache.objects.filter(disease_name_en__iexact=disease_name).first()
    if cache:
        value = getattr(cache, field, None)
        if value: return value

    TranslationCache.objects.get_or_create(
        disease_name_en=disease_name,
        defaults={'pesticide_st': '', 'dosage_st': '', 'steps_st': ''}
    )
    return fallback 

# ============================================================
# --- 1. AUTHENTICATION & ONBOARDING ---
# ============================================================

@api_view(['POST'])
@permission_classes([AllowAny])
def login_farmer(request):
    email = request.data.get('email')
    password = request.data.get('password')
    user = authenticate(username=email, password=password)
    
    if user:
        if not user.is_active:
            return Response({'error': 'unverified'}, status=403)
        
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
@permission_classes([AllowAny])
def register_farmer(request):
    data = request.data
    try:
        if Farmer.objects.filter(email=data.get('email')).exists():
            return Response({'error': 'Email already exists'}, status=400)

        user = Farmer.objects.create_user(
            username=data.get('email'),
            email=data.get('email'),
            password=data.get('password'),
            first_name=data.get('first_name', ''),
            last_name=data.get('last_name', ''),
            district=data.get('district', ''),
            language_preferences=data.get('language_preferences', 'en'),
        )
        user.is_active = False 
        user.save()
        _send_activation_email(request, user)
        return Response({'status': 'success', 'message': 'Verification email sent.'}, status=201)
    except Exception as e:
        return Response({'error': str(e)}, status=500)

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
        return HttpResponse('<h1>Account activated!</h1><p>You can now log in to the app.</p>')
    return HttpResponse('<h1>Invalid Link</h1>', status=400)

@api_view(['POST'])
@permission_classes([AllowAny])
def resend_activation_email(request):
    email = request.data.get('email')
    user = Farmer.objects.filter(email=email).first()
    if user and not user.is_active:
        _send_activation_email(request, user)
        return Response({'status': 'sent'})
    return Response({'error': 'Invalid request'}, status=400)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def change_password(request):
    old_pw = request.data.get('old_password')
    new_pw = request.data.get('new_password')
    if request.user.check_password(old_pw):
        request.user.set_password(new_pw)
        request.user.save()
        update_session_auth_hash(request, request.user)
        return Response({'status': 'password changed'})
    return Response({'error': 'Old password incorrect'}, status=400)

def _send_activation_email(request, user):
    current_site = get_current_site(request)
    uid = urlsafe_base64_encode(force_bytes(user.pk))
    token = default_token_generator.make_token(user)
    link = f"http://{current_site.domain}/api/activate/{uid}/{token}/"
    EmailMessage('Activate FarmAid', f"Click here: {link}", to=[user.email]).send()

# ============================================================
# --- 2. CROP PROFILES & SCANNING ---
# ============================================================

class CropProfileView(APIView):
    permission_classes = [IsAuthenticated]
    def get(self, request):
        profiles = CropProfile.objects.filter(FarmerID=request.user, IsActive=True)
        return Response(CropProfileSerializer(profiles, many=True).data)

    def post(self, request):
        serializer = CropProfileSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(FarmerID=request.user)
            return Response(serializer.data, status=201)
        return Response(serializer.errors, status=400)

class SaveScanView(APIView):
    permission_classes = [IsAuthenticated]
    def post(self, request):
        # Implementation from previous message (rejection logic for non-veg)
        raw_label = request.data.get('diseaseName')
        if not raw_label or "invalid" in raw_label.lower():
            return Response({'error': 'Not a vegetable.'}, status=400)
        # ... (rest of scan logic)
        return Response({'status': 'success'})

class DiagnosisFeedbackView(APIView):
    permission_classes = [IsAuthenticated]
    def post(self, request, diagnosis_id):
        diag = Diagnosis.objects.get(pk=diagnosis_id, PlantID__FarmerID=request.user)
        diag.farmer_feedback = request.data.get('feedback')
        diag.save()
        return Response({'status': 'feedback saved'})

# ============================================================
# --- 3. DASHBOARD, WEATHER & ANALYTICS ---
# ============================================================

class LatestWeatherView(APIView):
    permission_classes = [AllowAny]
    def get(self, request):
        district = request.user.district if request.user.is_authenticated else "Maseru"
        latest = WeatherData.objects.filter(district__iexact=district).order_by('-DateUpdated').first()
        return Response(WeatherDataSerializer(latest).data if latest else {"error": "no data"})

class FarmerInsightView(APIView):
    permission_classes = [IsAuthenticated]
    def get(self, request):
        insight, _ = FarmerInsight.objects.get_or_create(FarmerID=request.user)
        return Response(FarmerInsightSerializer(insight).data)

class GrowthJournalView(APIView):
    permission_classes = [IsAuthenticated]
    def get(self, request):
        entries = GrowthJournalEntry.objects.filter(FarmerID=request.user)
        return Response(GrowthJournalSerializer(entries, many=True).data)
    
    def delete(self, request, entry_id):
        GrowthJournalEntry.objects.filter(pk=entry_id, FarmerID=request.user).delete()
        return Response(status=204)

class MarketPriceView(APIView):
    permission_classes = [IsAuthenticated]
    def get(self, request):
        prices = MarketPrice.objects.all().order_by('-date_recorded')
        return Response(MarketPriceSerializer(prices, many=True).data)

# ============================================================
# --- 4. HISTORY & PROFILE ---
# ============================================================

class FarmerHistoryView(APIView):
    permission_classes = [IsAuthenticated]
    def get(self, request):
        plants = Plant.objects.filter(FarmerID=request.user).order_by('-DateScanned')
        # Simple list of history (can use a simplified serializer here)
        return Response([{"id": p.PlantID, "crop": p.CropType, "date": p.DateScanned} for p in plants])

class FarmerReportsView(APIView):
    permission_classes = [IsAuthenticated]
    def get(self, request):
        # Placeholder for reporting logic
        return Response({"message": "Reports feature coming soon."})

class FarmerAlertsView(APIView):
    permission_classes = [IsAuthenticated]
    def get(self, request):
        alerts = AppAlert.objects.filter(Q(FarmerID=request.user) | Q(district_target=request.user.district))
        return Response(AppAlertSerializer(alerts, many=True).data)

class ProfileView(APIView):
    permission_classes = [IsAuthenticated]
    def get(self, request):
        u = request.user
        return Response({"full_name": f"{u.first_name} {u.last_name}", "district": u.district})
    
    def patch(self, request):
        for attr, value in request.data.items():
            setattr(request.user, attr, value)
        request.user.save()
        return Response({"status": "updated"})
