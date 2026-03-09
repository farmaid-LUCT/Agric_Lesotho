from rest_framework import status

from rest_framework.response import Response

from rest_framework.decorators import api_view, permission_classes

from rest_framework.views import APIView

from rest_framework.permissions import IsAuthenticated, AllowAny
from datetime import date, timedelta  # Add timedelta here

from rest_framework.authtoken.models import Token

from django.contrib.auth import authenticate

from django.db.models import Q

from datetime import date

import hashlib



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

    TranslationCache, MarketPrice, FarmerInsight, GrowthJournalEntry

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

            district=data.get('district', '') or data.get('location', ''),

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

        return Response({

            "first_name": u.first_name, 

            "last_name": u.last_name, 

            "email": u.email, 

            "district": u.district, 

            "phone_number": u.phone_number, 

            "language_preferences": u.language_preferences

        })



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

        user_dist = request.user.district or ""

        alerts = AppAlert.objects.filter(Q(FarmerID=request.user) | Q(Message__icontains=user_dist)).order_by('-DateCreated')

        return Response(AppAlertSerializer(alerts, many=True).data)

    def post(self, request):

        AppAlert.objects.filter(FarmerID=request.user, IsRead=False).update(IsRead=True)

        return Response({'status': 'success'})



# --- 4. AI SCAN & REPORTS (MANUAL TRANSLATION LOGIC) ---

class SaveScanView(APIView):
    permission_classes = [IsAuthenticated]

    def _get_manual_sesotho(self, text):
        """
        Looks up Sesotho translation in the database.
        If not found, creates an entry for the Admin to translate later.
        """
        if not text or text == "N/A" or text == "Consult local expert": return text
        
        # Create a unique hash for this specific piece of text
        t_hash = hashlib.sha256(text.strip().lower().encode()).hexdigest()
        
        cached = TranslationCache.objects.filter(text_hash=t_hash).first()
        
        # If the Admin has filled in the Sesotho text, return it
        if cached and cached.sesotho_text:
            return cached.sesotho_text
        
        # If record doesn't exist, create it so Admin can see it in the Django Admin panel
        if not cached:
            TranslationCache.objects.create(
                text_hash=t_hash, 
                english_text=text, 
                sesotho_text="" # Leaves blank for Admin to fill
            )
        
        # Return original English as fallback until Admin translates it
        return text

    def post(self, request):
        try:
            user = request.user
            
            # Sync user language preference from Flutter request
            incoming_lang = request.data.get('language') or request.data.get('lang')
            if incoming_lang in ['st', 'en']:
                user.language_preferences = incoming_lang
                user.save(update_fields=['language_preferences'])
            
            lang = user.language_preferences

            # 1. Capture Data
            raw_label = request.data.get('diseaseName') or request.data.get('DiseaseName') or "Healthy"
            clean_label = raw_label.replace('___', ' ').replace('_', ' ').strip()
            image_url = request.data.get('imageUrl') or request.data.get('image_url') or request.data.get('ImageFile')
            confidence = request.data.get('confidence') or request.data.get('ConfidenceLevel') or 0.0
            profile_id = request.data.get('profileId') or request.data.get('ProfileID')
            # GPS — read all 4 fields from Flutter POST body
            gps_lat     = request.data.get('latitude')
            gps_lon     = request.data.get('longitude')
            gps_alt     = request.data.get('altitude')
            gps_district = request.data.get('gps_district') or request.data.get('district') or request.user.district

            # 2. Database Save (Plant & Diagnosis)
            target_profile = None
            if profile_id and str(profile_id).lower() not in ["null", "", "none"]:
                target_profile = CropProfile.objects.filter(pk=profile_id, FarmerID=user).first()

            new_plant = Plant.objects.create(
                FarmerID=user,
                CropProfile=target_profile,
                ImageFile=image_url,
                CropType=target_profile.VegetableType if target_profile else 'Vegetable',
                latitude=gps_lat,
                longitude=gps_lon,
                altitude_meters=gps_alt,
                gps_district=gps_district,
            )

            # FIXED: Assigned to 'diagnosis' variable
            diagnosis = Diagnosis.objects.create(
                PlantID=new_plant, 
                DiseaseName=clean_label, 
                ConfidenceLevel=float(confidence)
            )

            # 3. Treatment & KnowledgeBase Retrieval
            treatment_query = Q(DiseaseName__iexact=clean_label) | Q(DiseaseName__iexact=raw_label)
            treat = Treatment.objects.filter(treatment_query).first()
            kb_entry = KnowledgeBase.objects.filter(treatment_query).first()

            # --- Default English Values ---
            res_disease = clean_label
            res_pesticide = treat.RecommendedPesticide if treat else "Consult local expert"
            res_dosage = treat.Dosage if treat else "N/A"
            
            # Get steps from Treatment table, fallback to KnowledgeBase, fallback to generic advice
            if treat and treat.ApplicationSteps:
                res_steps = treat.ApplicationSteps
            elif kb_entry and kb_entry.TreatmentInfo:
                res_steps = kb_entry.TreatmentInfo
            else:
                res_steps = "Isolate plant immediately."

            # 4. APPLY MANUAL TRANSLATION (If user prefers Sesotho)
            if lang == 'st':
                res_disease = self._get_manual_sesotho(res_disease)
                res_pesticide = self._get_manual_sesotho(res_pesticide)
                res_dosage = self._get_manual_sesotho(res_dosage)
                res_steps = self._get_manual_sesotho(res_steps)

            # Calculate follow-up date
            # Urgent diseases (blight/rot/wilt) → check in 3 days, others → 10 days
            urgent = any(w in clean_label.lower() for w in ['blight', 'rot', 'wilt', 'mold'])
            follow_up_date = date.today() + timedelta(days=3 if urgent else 10)

            # Save follow_up_date on diagnosis record
            diagnosis.follow_up_date = follow_up_date
            diagnosis.save(update_fields=['follow_up_date'])

            return Response({
                'status':            'success',
                'id':                diagnosis.pk,           # Flutter reads → shows feedback card
                'follow_up_date':    follow_up_date.isoformat(),
                'crop_type':         target_profile.VegetableType if target_profile else None,
                'treatment_product': res_pesticide,
                'results': {
                    'disease':   res_disease,
                    'pesticide': res_pesticide,
                    'dosage':    res_dosage,
                    'steps':     res_steps,
                    'confidence': float(confidence) # Added to bridge UI
                }
            })
            
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)



class FarmerHistoryView(APIView):

    permission_classes = [IsAuthenticated]

    def get(self, request):

        plants = Plant.objects.filter(FarmerID=request.user).order_by('-DateCaptured')

        history = []

        for p in plants:

            diag = Diagnosis.objects.filter(PlantID=p).first()

            if diag:

                history.append({

                    "plant_id": p.PlantID, 

                    "crop": p.CropType, 

                    "image": p.ImageFile, 

                    "disease": diag.DiseaseName, 

                    "date": p.DateCaptured.strftime("%d %b, %Y")

                })

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

# --- 5. MARKET PRICES ---

class MarketPricesView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        district = request.query_params.get('district')

        prices = MarketPrice.objects.all().order_by('-date_recorded')

        if district:
            prices = prices.filter(district__iexact=district)

        data = []
        for p in prices:
            data.append({
                'id':             p.PriceID,
                'vegetable_name': p.vegetable_name,
                'market_name':    p.market_name,
                'district':       p.district,
                'price_per_kg':   float(p.price_per_kg),
                'currency':       p.currency,
                'date_recorded':  p.date_recorded.isoformat(),
                'price_trend':    p.price_trend,
            })

        return Response(data)

# --- 6. DIAGNOSIS FEEDBACK ---

class DiagnosisFeedbackView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, diagnosis_id):
        try:
            diag = Diagnosis.objects.get(
                DiagnosisID=diagnosis_id,
                PlantID__FarmerID=request.user
            )
        except Diagnosis.DoesNotExist:
            return Response({'error': 'Diagnosis not found'}, status=404)

        # Update all feedback fields provided
        feedback         = request.data.get('farmer_feedback')
        severity         = request.data.get('severity')
        treatment_applied = request.data.get('treatment_applied')
        treatment_outcome = request.data.get('treatment_outcome')
        notes            = request.data.get('notes')

        if feedback         is not None: diag.farmer_feedback    = feedback
        if severity         is not None: diag.severity           = severity
        if treatment_applied is not None: diag.treatment_applied = treatment_applied
        if treatment_outcome is not None: diag.treatment_outcome = treatment_outcome

        diag.save()

        return Response({
            'status':  'success',
            'message': 'Feedback recorded. Thank you!',
            'id':       diag.DiagnosisID,
        })


# --- 7. FARMER INSIGHTS ---

class FarmerInsightView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        insight, _ = FarmerInsight.objects.get_or_create(FarmerID=request.user)

        # Recalculate live stats from Plant/Diagnosis tables
        from django.db.models import Count
        plants = Plant.objects.filter(FarmerID=request.user)
        total_scans = plants.count()

        diagnoses = Diagnosis.objects.filter(PlantID__in=plants)
        healthy   = diagnoses.filter(DiseaseName__iexact='healthy').count()
        diseased  = total_scans - healthy

        # Most common disease
        top = (diagnoses
               .exclude(DiseaseName__iexact='healthy')
               .values('DiseaseName')
               .annotate(c=Count('DiseaseName'))
               .order_by('-c')
               .first())

        # Most scanned crop
        top_crop = (plants
                    .exclude(CropType='Vegetable')
                    .values('CropType')
                    .annotate(c=Count('CropType'))
                    .order_by('-c')
                    .first())

        # Update cached insight record
        insight.total_scans              = total_scans
        insight.total_diseases_detected  = diseased
        insight.total_healthy_scans      = healthy
        insight.most_common_disease      = top['DiseaseName']  if top      else None
        insight.most_scanned_crop        = top_crop['CropType'] if top_crop else None
        insight.save()

        return Response({
            'total_scans':             insight.total_scans,
            'total_diseases_detected': insight.total_diseases_detected,
            'total_healthy_scans':     insight.total_healthy_scans,
            'most_common_disease':     insight.most_common_disease,
            'most_scanned_crop':       insight.most_scanned_crop,
            'streak_healthy_days':     insight.streak_healthy_days,
            'last_updated':            insight.last_updated.isoformat(),
        })


# --- 8. GROWTH JOURNAL ---

class GrowthJournalView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        profile_id = request.query_params.get('crop_profile_id')
        entries = GrowthJournalEntry.objects.filter(FarmerID=request.user)
        if profile_id:
            entries = entries.filter(CropProfile__ProfileID=profile_id)

        data = []
        for e in entries:
            data.append({
                'id':          e.EntryID,
                'crop_profile_id': e.CropProfile.ProfileID,
                'crop_name':   e.CropProfile.VegetableType,
                'entry_date':  e.entry_date.isoformat(),
                'title':       e.title,
                'body':        e.body,
                'mood':        e.mood,
                'photo_url':   e.photo_url,
                'created_at':  e.DateCreated.isoformat(),
            })
        return Response(data)

    def post(self, request):
        profile_id = request.data.get('crop_profile_id')
        try:
            profile = CropProfile.objects.get(
                ProfileID=profile_id, FarmerID=request.user
            )
        except CropProfile.DoesNotExist:
            return Response({'error': 'Crop profile not found'}, status=404)

        entry = GrowthJournalEntry.objects.create(
            FarmerID    = request.user,
            CropProfile = profile,
            title       = request.data.get('title', ''),
            body        = request.data.get('body', ''),
            mood        = request.data.get('mood', 'ok'),
            photo_url   = request.data.get('photo_url'),
            entry_date  = request.data.get('entry_date', date.today()),
        )
        return Response({
            'status': 'success',
            'id':     entry.EntryID,
        }, status=201)

    def delete(self, request, entry_id=None):
        if entry_id is None:
            return Response({'error': 'entry_id required'}, status=400)
        try:
            entry = GrowthJournalEntry.objects.get(
                EntryID=entry_id, FarmerID=request.user
            )
            entry.delete()
            return Response({'status': 'deleted'})
        except GrowthJournalEntry.DoesNotExist:
            return Response({'error': 'Entry not found'}, status=404)



