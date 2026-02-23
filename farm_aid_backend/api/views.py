# from rest_framework import status
# from rest_framework.response import Response
# from rest_framework.decorators import api_view, permission_classes
# from rest_framework.views import APIView
# from rest_framework.permissions import IsAuthenticated, AllowAny
# from rest_framework.authtoken.models import Token
# from django.contrib.auth import authenticate
# from django.db.models import Q
# from datetime import date
# import hashlib
# import requests  # Required for LibreTranslate API calls

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
#         return Response({"first_name": u.first_name, "last_name": u.last_name, "email": u.email, "location": u.location, "phone_number": u.phone_number, "language_preferences": u.language_preferences})

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
#             ser.save(FarmerID=request.user)
#             return Response(ser.data, status=201)
#         return Response(ser.errors, status=400)

# class FarmerAlertsView(APIView):
#     permission_classes = [IsAuthenticated]
#     def get(self, request):
#         user_dist = request.user.location or ""
#         alerts = AppAlert.objects.filter(Q(FarmerID=request.user) | Q(Message__icontains=user_dist)).order_by('-DateCreated')
#         return Response(AppAlertSerializer(alerts, many=True).data)
#     def post(self, request):
#         AppAlert.objects.filter(FarmerID=request.user, IsRead=False).update(IsRead=True)
#         return Response({'status': 'success'})

# # --- 4. AI SCAN & REPORTS ---
# class SaveScanView(APIView):
#     permission_classes = [IsAuthenticated]

#     def _get_sesotho_translation(self, text):
#         """Helper to check cache or call LibreTranslate"""
#         if not text: return text
#         t_hash = hashlib.sha256(text.strip().lower().encode()).hexdigest()
#         cached = TranslationCache.objects.filter(text_hash=t_hash).first()
#         if cached:
#             return cached.sesotho_text
        
#         try:
#             url = "https://translate.terraprint.co/translate"
#             res = requests.post(url, json={"q": text, "source": "en", "target": "st", "format": "text"})
#             if res.status_code == 200:
#                 translated = res.json().get('translatedText', text)
#                 TranslationCache.objects.create(text_hash=t_hash, english_text=text, sesotho_text=translated)
#                 return translated
#         except:
#             pass
#         return text

#     def post(self, request):
#         try:
#             # 1. Capture Data
#             raw_label = request.data.get('diseaseName') or request.data.get('DiseaseName') or "Healthy"
#             clean_label = raw_label.replace('___', ' ').replace('_', ' ').strip()
            
#             image_url = request.data.get('imageUrl') or request.data.get('image_url') or request.data.get('ImageFile')
#             confidence = request.data.get('confidence') or request.data.get('ConfidenceLevel') or 0.0
#             profile_id = request.data.get('profileId') or request.data.get('ProfileID')
            
#             is_personalized = request.data.get('RequestPersonalized', False) or (profile_id is not None)
#             lang = request.user.language_preferences

#             if not image_url:
#                 return Response({'error': 'Supabase image URL is missing'}, status=400)

#             target_profile = None
#             if profile_id and str(profile_id).lower() != "null":
#                 target_profile = CropProfile.objects.filter(pk=profile_id, FarmerID=request.user).first()

#             # 2. SAVE TO NEON
#             new_plant = Plant.objects.create(FarmerID=request.user, CropProfile=target_profile, ImageFile=image_url)
#             Diagnosis.objects.create(PlantID=new_plant, DiseaseName=clean_label, ConfidenceLevel=float(confidence))

#             # 3. TREATMENT QUERY
#             treatment_query = (
#                 Q(DiseaseName__iexact=raw_label) | 
#                 Q(DiseaseName__iexact=clean_label) |
#                 Q(DiseaseName__iexact=clean_label.replace(' ', '_'))
#             )
            
#             treat = Treatment.objects.filter(treatment_query).first()
#             kb_entry = KnowledgeBase.objects.filter(treatment_query).first()

#             res_disease = clean_label
#             res_pesticide = treat.RecommendedPesticide if treat else "Consult local expert"
#             res_dosage = treat.Dosage if treat else "N/A"
#             res_steps = treat.ApplicationSteps if treat else (kb_entry.TreatmentInfo if kb_entry else "Isolate plant.")

#             # 4. TRANSLATION LOGIC
#             if lang == 'st':
#                 res_disease = self._get_sesotho_translation(res_disease)
#                 res_pesticide = self._get_sesotho_translation(res_pesticide)
#                 res_steps = self._get_sesotho_translation(res_steps)

#             # 5. PERSONALIZED LOGIC (FIXED FOR SOIL MATCHING)
#             personalized_data = []
#             if is_personalized and target_profile and target_profile.PlantingDate:
#                 days_old = (date.today() - target_profile.PlantingDate).days
                
#                 # Fetch rules matching Disease and Age
#                 rules = PersonalizedRule.objects.filter(
#                     treatment_query, 
#                     MinDaysSincePlanting__lte=days_old, 
#                     MaxDaysSincePlanting__gte=days_old
#                 )
                
#                 # Apply Soil Filter with fallback to "Any Soil" (Empty/Null)
#                 if target_profile.SoilEnvironment:
#                     rules = rules.filter(
#                         Q(TriggerSoilType__iexact=target_profile.SoilEnvironment) | 
#                         Q(TriggerSoilType__isnull=True) | 
#                         Q(TriggerSoilType="")
#                     )
#                 else:
#                     rules = rules.filter(Q(TriggerSoilType__isnull=True) | Q(TriggerSoilType=""))

#                 for r in rules:
#                     advice = r.ExpertAdvice
#                     if lang == 'st': 
#                         advice = self._get_sesotho_translation(advice)
#                     personalized_data.append({"ExpertAdvice": advice})

#             return Response({
#                 'status': 'success',
#                 'results': {
#                     'disease': res_disease,
#                     'pesticide': res_pesticide,
#                     'dosage': res_dosage,
#                     'steps': res_steps
#                 },
#                 'personalized_rules': personalized_data,
#             })
            
#         except Exception as e:
#             return Response({'error': str(e)}, status=400)

# class FarmerHistoryView(APIView):
#     permission_classes = [IsAuthenticated]
#     def get(self, request):
#         plants = Plant.objects.filter(FarmerID=request.user).order_by('-DateCaptured')
#         history = []
#         for p in plants:
#             diag = Diagnosis.objects.filter(PlantID=p).first()
#             if diag:
#                 history.append({"plant_id": p.PlantID, "crop": p.CropType, "image": p.ImageFile, "disease": diag.DiseaseName, "date": p.DateCaptured.strftime("%d %b, %Y")})
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


from rest_framework import status
from rest_framework.response import Response
from rest_framework.decorators import api_view, permission_classes
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.authtoken.models import Token
from django.contrib.auth import authenticate
from django.db.models import Q
from datetime import date
import hashlib
import requests  # Required for LibreTranslate API calls

# Email Verification & Activation Imports
from django.contrib.sites.shortcuts import get_current_site
from django.utils.encoding import force_bytes, force_str
from django.utils.http import urlsafe_base64_encode, urlsafe_base64_decode
from django.core.mail import EmailMessage
from django.contrib.auth.tokens import default_token_generator
from django.shortcuts import render
from django.http import HttpResponse

from .models import (
    Farmer, Plant, Diagnosis, Treatment, 
    CropProfile, AppAlert, WeatherData, PersonalizedRule, KnowledgeBase,
    TranslationCache
)
from .serializers import CropProfileSerializer, AppAlertSerializer, WeatherDataSerializer

# --- 1. AUTHENTICATION & SECURITY MODULE ---

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
            location=data.get('location', ''),
            language_preferences=data.get('language_preferences', 'en')
        )
        user.is_active = False 
        user.save()
        send_activation_email(request, user)

        return Response({
            'status': 'success',
            'message': 'Verification email sent.',
            'email': user.email
        }, status=status.HTTP_201_CREATED)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

def send_activation_email(request, user):
    current_site = get_current_site(request)
    uid = urlsafe_base64_encode(force_bytes(user.pk))
    token = default_token_generator.make_token(user)
    activation_link = f"http://{current_site.domain}/api/activate/{uid}/{token}/"
    
    mail_subject = 'Activate your FarmAid Lesotho Account'
    message = f"Dumela {user.first_name},\n\nPlease click link to verify: {activation_link}"
    email = EmailMessage(mail_subject, message, to=[user.email])
    email.send()

@api_view(['POST'])
@permission_classes([AllowAny])
def resend_activation_email(request):
    email_addr = request.data.get('email')
    try:
        user = Farmer.objects.get(email=email_addr)
        if user.is_active:
            return Response({'error': 'Account already active.'}, status=400)
        send_activation_email(request, user)
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
    else:
        return HttpResponse("<h2>Activation link is invalid.</h2>", status=400)

@api_view(['POST'])
@permission_classes([AllowAny])
def login_farmer(request):
    email = request.data.get('email')
    password = request.data.get('password')
    user = authenticate(username=email, password=password)
    if user:
        if not user.is_active:
            return Response({'error': 'unverified'}, status=403)
        token, _ = Token.objects.get_or_create(user=user)
        return Response({
            'token': token.key,
            'farmerName': f"{user.first_name} {user.last_name}".strip(),
            'is_staff': user.is_staff 
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

# --- 2. PROFILE & WEATHER ---

class ProfileView(APIView):
    permission_classes = [IsAuthenticated]
    def get(self, request):
        u = request.user
        return Response({"first_name": u.first_name, "last_name": u.last_name, "email": u.email, "location": u.location, "phone_number": u.phone_number, "language_preferences": u.language_preferences})

    def patch(self, request):
        user = request.user
        for attr, value in request.data.items():
            if hasattr(user, attr): setattr(user, attr, value)
        user.save()
        return Response({"status": "success", "farmerName": f"{user.first_name} {user.last_name}"})

class LatestWeatherView(APIView):
    permission_classes = [AllowAny] 
    def get(self, request):
        latest = WeatherData.objects.order_by('-DateUpdated').first()
        return Response(WeatherDataSerializer(latest).data) if latest else Response({"error": "No data"}, status=404)

# --- 3. CROP PROFILES & ALERTS ---

class CropProfileView(APIView):
    permission_classes = [IsAuthenticated]
    def get(self, request):
        profiles = CropProfile.objects.filter(FarmerID=request.user, IsActive=True)
        return Response(CropProfileSerializer(profiles, many=True).data)
    def post(self, request):
        ser = CropProfileSerializer(data=request.data)
        if ser.is_valid():
            ser.save(FarmerID=request.user)
            return Response(ser.data, status=201)
        return Response(ser.errors, status=400)

class FarmerAlertsView(APIView):
    permission_classes = [IsAuthenticated]
    def get(self, request):
        user_dist = request.user.location or ""
        alerts = AppAlert.objects.filter(Q(FarmerID=request.user) | Q(Message__icontains=user_dist)).order_by('-DateCreated')
        return Response(AppAlertSerializer(alerts, many=True).data)
    def post(self, request):
        AppAlert.objects.filter(FarmerID=request.user, IsRead=False).update(IsRead=True)
        return Response({'status': 'success'})

# --- 4. AI SCAN & REPORTS ---
class SaveScanView(APIView):
    permission_classes = [IsAuthenticated]

    def _get_sesotho_translation(self, text):
        if not text or text == "N/A": return text
        t_hash = hashlib.sha256(text.strip().lower().encode()).hexdigest()
        
        cached = TranslationCache.objects.filter(text_hash=t_hash).first()
        if cached:
            return cached.sesotho_text
        
        try:
            url = "https://translate.terraprint.co/translate"
            res = requests.post(url, json={"q": text, "source": "en", "target": "st", "format": "text"}, timeout=10)
            if res.status_code == 200:
                translated = res.json().get('translatedText', text)
                TranslationCache.objects.create(text_hash=t_hash, english_text=text, sesotho_text=translated)
                return translated
        except:
            pass
        return text

    def post(self, request):
        try:
            user = request.user
            
            # --- FORCE SYNC: Listen to Flutter's current language ---
            # If the app sends 'language': 'st' in the POST body, update the database
            incoming_lang = request.data.get('language') or request.data.get('lang')
            if incoming_lang in ['st', 'en']:
                user.language_preferences = incoming_lang
                user.save(update_fields=['language_preferences'])
            
            lang = user.language_preferences

            # 1. Capture Data
            raw_label = request.data.get('diseaseName') or request.data.get('DiseaseName') or "Healthy"
            clean_label = raw_label.replace('___', ' ').replace('_', ' ').strip()
            image_url = request.data.get('imageUrl') or request.data.get('image_url') or request.data.get('ImageFile')
            confidence = request.data.get('confidence') or 0.0
            profile_id = request.data.get('profileId')

            # 2. Database Save
            target_profile = None
            if profile_id and str(profile_id).lower() != "null":
                target_profile = CropProfile.objects.filter(pk=profile_id, FarmerID=user).first()

            new_plant = Plant.objects.create(FarmerID=user, CropProfile=target_profile, ImageFile=image_url)
            Diagnosis.objects.create(PlantID=new_plant, DiseaseName=clean_label, ConfidenceLevel=float(confidence))

            # 3. Treatment Query
            treatment_query = Q(DiseaseName__iexact=clean_label) | Q(DiseaseName__iexact=raw_label)
            treat = Treatment.objects.filter(treatment_query).first()
            kb_entry = KnowledgeBase.objects.filter(treatment_query).first()

            res_disease = clean_label
            res_pesticide = treat.RecommendedPesticide if treat else "Consult local expert"
            res_dosage = treat.Dosage if treat else "N/A"
            res_steps = treat.ApplicationSteps if treat else (kb_entry.TreatmentInfo if kb_entry else "Isolate plant.")

            # 4. TRANSLATION (Triggered if DB says 'st')
            if lang == 'st':
                res_disease = self._get_sesotho_translation(res_disease)
                res_pesticide = self._get_sesotho_translation(res_pesticide)
                res_steps = self._get_sesotho_translation(res_steps)

            return Response({
                'status': 'success',
                'results': {
                    'disease': res_disease,
                    'pesticide': res_pesticide,
                    'dosage': res_dosage,
                    'steps': res_steps
                }
            })
            
        except Exception as e:
            return Response({'error': str(e)}, status=400)

class FarmerHistoryView(APIView):
    permission_classes = [IsAuthenticated]
    def get(self, request):
        plants = Plant.objects.filter(FarmerID=request.user).order_by('-DateCaptured')
        history = []
        for p in plants:
            diag = Diagnosis.objects.filter(PlantID=p).first()
            if diag:
                history.append({"plant_id": p.PlantID, "crop": p.CropType, "image": p.ImageFile, "disease": diag.DiseaseName, "date": p.DateCaptured.strftime("%d %b, %Y")})
        return Response(history)

class FarmerReportsView(APIView):
    permission_classes = [IsAuthenticated]
    def get(self, request):
        plants = Plant.objects.filter(FarmerID=request.user).order_by('-DateCaptured')
        report_data = []
        for p in plants:
            diag = Diagnosis.objects.filter(PlantID=p).first()
            if diag:
                treat = Treatment.objects.filter(DiseaseName__iexact=diag.DiseaseName).first()
                report_data.append({
                    "FarmerID_id": request.user.id,
                    "ReportDate": p.DateCaptured.isoformat(),
                    "DiagnosisSummary": diag.DiseaseName.replace('_', ' ').upper(),
                    "TreatmentSummary": treat.ApplicationSteps if treat else "Isolate plant immediately.",
                    "ImageURL": p.ImageFile
                })
        return Response(report_data)
