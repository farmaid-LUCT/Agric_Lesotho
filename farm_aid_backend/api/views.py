import os
import numpy as np
from PIL import Image
from io import BytesIO

from rest_framework import status
from rest_framework.response import Response
from rest_framework.decorators import api_view, permission_classes
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated, AllowAny
from datetime import date, timedelta
from rest_framework.authtoken.models import Token
from django.contrib.auth import authenticate
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError
from django.db.models import Q
from django.utils import timezone
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
    TranslationCache, MarketPrice, FarmerInsight, GrowthJournalEntry,
    RuleMatchingService,
)
from .serializers import CropProfileSerializer, AppAlertSerializer, WeatherDataSerializer

# ── Disease → possible causes lookup ─────────────────────────────────────────
DISEASE_CAUSES = {
    'early blight':         ['Alternaria solani fungal infection', 'High humidity and warm temperatures', 'Infected plant debris in soil', 'Overhead irrigation keeping leaves wet'],
    'late blight':          ['Phytophthora infestans water mould', 'Cool wet weather (15–20°C)', 'Poor air circulation between plants', 'Infected seed or transplants'],
    'powdery mildew':       ['Erysiphe/Leveillula fungal spores', 'Warm days and cool dry nights', 'Overcrowded plants with low airflow', 'Excessive nitrogen fertilisation'],
    'downy mildew':         ['Peronospora/Pseudoperonospora spores', 'High humidity and leaf wetness', 'Cool temperatures with morning dew', 'Infected transplant material'],
    'fusarium wilt':        ['Fusarium oxysporum soil fungus', 'Infected or poorly drained soil', 'Root damage from pests or cultivation', 'Infected transplant material'],
    'bacterial wilt':       ['Ralstonia solanacearum bacterium', 'Infected soil or irrigation water', 'Cucumber beetle or flea beetle feeding', 'High soil moisture and warm temperatures'],
    'leaf spot':            ['Cercospora or Septoria fungal infection', 'Prolonged leaf wetness', 'Poor crop rotation practices', 'Splashing rain or overhead irrigation'],
    'rust':                 ['Puccinia fungal spores spread by wind', 'Extended leaf wetness (>6 hours)', 'Cool temperatures 15–20°C', 'Infected volunteer plants nearby'],
    'mosaic virus':         ['Aphid or whitefly virus transmission', 'Infected seeds or transplants', 'Handling plants without washing hands', 'Contaminated tools or machinery'],
    'anthracnose':          ['Colletotrichum fungal infection', 'Warm humid conditions', 'Infected seeds or crop debris', 'Wounds from insects or hail'],
    'damping off':          ['Pythium or Rhizoctonia soil pathogens', 'Overwatering and poor drainage', 'Overcrowded seedlings', 'Contaminated growing medium'],
    'grey mould':           ['Botrytis cinerea fungal infection', 'High humidity above 90%', 'Wounded or dying plant tissue', 'Cool temperatures 15–20°C'],
    'healthy':              ['No disease detected — plant appears healthy', 'Continue regular scouting every 3–5 days', 'Maintain good hygiene and crop rotation'],
}

def _get_causes(disease_name: str) -> list:
    key = disease_name.lower().strip()
    for k, v in DISEASE_CAUSES.items():
        if k in key or key in k:
            return v
    return [
        'Fungal, bacterial or viral pathogen',
        'Environmental stress (heat, drought, waterlogging)',
        'Poor soil nutrition or pH imbalance',
        'Pest damage opening entry points for disease',
    ]


# ── 1. AUTHENTICATION ────────────────────────────────────────────────────────

@api_view(['POST'])
@permission_classes([AllowAny])
def register_farmer(request):
    data = request.data
    try:
        # ── a. Duplicate email check ──────────────────────────────────────
        if Farmer.objects.filter(email=data.get('email', '').lower()).exists():
            return Response(
                {'error': 'Email already exists'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # ── b. Password strength validation ──────────────────────────────
        # Runs ALL validators listed in AUTH_PASSWORD_VALIDATORS in settings.py
        # including our custom PasswordStrengthValidator & NoCommonPasswordValidator
        raw_password = data.get('password', '')
        try:
            validate_password(raw_password)
        except DjangoValidationError as exc:
            return Response(
                {
                    'error':   'Password is too weak.',
                    'details': list(exc.messages),   # e.g. ["Must contain uppercase", ...]
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        # ── c. Create user (inactive until email verified) ───────────────
        user = Farmer.objects.create_user(
            username=data.get('email'),
            email=data.get('email'),
            password=raw_password,
            first_name=data.get('first_name', ''),
            last_name=data.get('last_name', ''),
            phone_number=data.get('phone_number', ''),
            district=data.get('district', '') or data.get('location', ''),
            language_preferences=data.get('language_preferences', 'en'),
        )
        user.is_active = False
        user.save()

        # Send activation email — but NEVER let a mail failure crash registration.
        # If SMTP is misconfigured the account is still created; the user can
        # request a new link via /api/resend-activation/.
        email_sent = True
        try:
            send_activation_email(request, user)
        except Exception as mail_err:
            import logging
            logging.getLogger(__name__).error(
                f'[register] Activation email failed for {user.email}: {mail_err}'
            )
            email_sent = False

        return Response({
            'status':     'success',
            'message':    (
                'Verification email sent. Please check your inbox.'
                if email_sent else
                'Account created. Email delivery failed — use Resend Activation to try again.'
            ),
            'email':      user.email,
            'email_sent': email_sent,
        }, status=status.HTTP_201_CREATED)

    except Exception as e:
        import traceback
        import logging
        logging.getLogger(__name__).error(
            f'[register] Unexpected error: {traceback.format_exc()}'
        )
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


def send_activation_email(request, user):
    current_site    = get_current_site(request)
    uid             = urlsafe_base64_encode(force_bytes(user.pk))
    token           = default_token_generator.make_token(user)
    activation_link = f"https://farmaid-backend.onrender.com/api/activate/{uid}/{token}/"
    EmailMessage(
        'Activate your FarmAid Lesotho Account',
        f"Dumela {user.first_name},\n\nPlease click the link below to verify your account:\n\n"
        f"{activation_link}\n\n"
        f"If you did not create this account, ignore this email.\n\n"
        f"— The FarmAid Team",
        to=[user.email],
    ).send()


@api_view(['POST'])
@permission_classes([AllowAny])
def resend_activation_email(request):
    try:
        user = Farmer.objects.get(email=request.data.get('email'))
        if user.is_active:
            return Response({'error': 'Account already active.'}, status=400)
        try:
            send_activation_email(request, user)
            return Response({'message': 'New activation link sent!'})
        except Exception as mail_err:
            return Response(
                {'error': f'Email delivery failed: {mail_err}. Contact support.'},
                status=500,
            )
    except Farmer.DoesNotExist:
        return Response({'error': 'User not found.'}, status=404)


@api_view(['GET'])
@permission_classes([AllowAny])
def activate_account(request, uidb64, token):
    try:
        uid  = force_str(urlsafe_base64_decode(uidb64))
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
def login_farmer(request):
    user = authenticate(
        username=request.data.get('email'),
        password=request.data.get('password'),
    )
    if user:
        if not user.is_active:
            return Response({'error': 'unverified'}, status=403)
        token, _ = Token.objects.get_or_create(user=user)
        return Response({
            'token':      token.key,
            'farmerName': f"{user.first_name} {user.last_name}".strip(),
            'is_staff':   user.is_staff,
        })
    return Response({'error': 'Invalid credentials'}, status=401)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def change_password(request):
    user = request.user

    if not user.check_password(request.data.get('old_password', '')):
        return Response({'error': 'Incorrect current password.'}, status=400)

    new_pw = request.data.get('new_password', '')
    try:
        validate_password(new_pw, user=user)
    except DjangoValidationError as exc:
        return Response(
            {'error': 'New password is too weak.', 'details': list(exc.messages)},
            status=400,
        )

    user.set_password(new_pw)
    user.save()
    # Re-issue token so Flutter app stays logged in after password change
    Token.objects.filter(user=user).delete()
    new_token, _ = Token.objects.get_or_create(user=user)
    return Response({
        'status':  'success',
        'message': 'Password updated!',
        'token':   new_token.key,   # Flutter should store this new token
    })


# ── 2. GOOGLE SIGN-IN ─────────────────────────────────────────────────────────

@api_view(['POST'])
@permission_classes([AllowAny])
def google_auth(request):
    """
    POST /api/auth/google/
    Body: { "id_token": "<Google ID token from Flutter google_sign_in>" }

    Flutter usage:
      final googleUser = await GoogleSignIn().signIn();
      final auth        = await googleUser!.authentication;
      // POST auth.idToken to this endpoint → receive { token, farmerName, ... }

    Requirements:
      pip install google-auth
      Set GOOGLE_CLIENT_ID in settings.py or as env variable.
    """
    from django.conf import settings as django_settings

    id_token_str = request.data.get('id_token', '').strip()
    if not id_token_str:
        return Response({'error': 'id_token is required.'}, status=400)

    # ── Verify the token with Google ──────────────────────────────────────
    try:
        from google.oauth2 import id_token as google_id_token
        from google.auth.transport import requests as google_requests

        client_id = getattr(django_settings, 'GOOGLE_CLIENT_ID',
                            os.environ.get('GOOGLE_CLIENT_ID', ''))
        id_info   = google_id_token.verify_oauth2_token(
            id_token_str,
            google_requests.Request(),
            client_id,
        )
    except ImportError:
        return Response(
            {'error': 'google-auth package not installed. Run: pip install google-auth'},
            status=500,
        )
    except ValueError as exc:
        return Response({'error': f'Invalid Google token: {exc}'}, status=401)

    email      = id_info.get('email', '').lower()
    first_name = id_info.get('given_name', '')
    last_name  = id_info.get('family_name', '')
    photo_url  = id_info.get('picture', '')

    if not email:
        return Response({'error': 'Google account has no email address.'}, status=400)

    # ── Get or create the Farmer account ─────────────────────────────────
    user, created = Farmer.objects.get_or_create(
        email=email,
        defaults={
            'username':   email,
            'first_name': first_name,
            'last_name':  last_name,
            'is_active':  True,   # Google already verified the email
        },
    )

    if created:
        user.set_unusable_password()   # Google-only login, no password needed
        if photo_url:
            user.profile_photo_url = photo_url
        user.save()
    elif not user.is_active:
        user.is_active = True
        user.save()

    token, _ = Token.objects.get_or_create(user=user)
    return Response({
        'token':      token.key,
        'farmerName': f"{user.first_name} {user.last_name}".strip() or email,
        'is_staff':   user.is_staff,
        'email':      user.email,
        'created':    created,   # True = new account, False = existing account
    })


# ── 3. PROFILE & WEATHER ─────────────────────────────────────────────────────

class ProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        u = request.user
        return Response({
            'first_name':           u.first_name,
            'last_name':            u.last_name,
            'email':                u.email,
            'district':             u.district,
            'phone_number':         u.phone_number,
            'language_preferences': u.language_preferences,
            'experience_level':     u.experience_level,
            'profile_photo_url':    u.profile_photo_url,
            'farm_size_hectares':   u.farm_size_hectares  if hasattr(u, 'farm_size_hectares')  else None,
            'onboarding_complete':  u.onboarding_complete if hasattr(u, 'onboarding_complete') else False,
        })

    def patch(self, request):
        user = request.user
        for attr, value in request.data.items():
            if hasattr(user, attr):
                setattr(user, attr, value)
        user.save()
        return Response({
            'status':     'success',
            'farmerName': f"{user.first_name} {user.last_name}",
        })


class LatestWeatherView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        latest = WeatherData.objects.order_by('-DateUpdated').first()
        return (
            Response(WeatherDataSerializer(latest).data)
            if latest else Response({'error': 'No data'}, status=404)
        )


# ── 4. CROP PROFILES ─────────────────────────────────────────────────────────

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


# ── 5. ALERTS ────────────────────────────────────────────────────────────────

class FarmerAlertsView(APIView):
    """
    GET  /api/alerts/            → list all alerts (with unread count)
    POST /api/alerts/mark-read/  → mark all unread alerts as read

    Response shape:
      GET  → { count, unread_count, alerts: [...] }
      POST → { status, marked_read }

    Flutter: read response['alerts'] instead of treating the response as a
    list directly.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user      = request.user
        user_dist = (user.district or '').strip()
        now       = timezone.now()

        qs = AppAlert.objects.filter(
            Q(FarmerID=user)
            | Q(district_target__iexact=user_dist)
        ).exclude(
            expires_at__lt=now     # hide expired alerts
        ).order_by('-DateCreated')

        # Optional filter by type: GET /api/alerts/?type=weather
        alert_type = request.query_params.get('type')
        if alert_type:
            qs = qs.filter(alert_type=alert_type)

        return Response({
            'count':        qs.count(),
            'unread_count': qs.filter(IsRead=False).count(),
            'alerts':       AppAlertSerializer(qs, many=True).data,
        })

    def post(self, request):
        updated = AppAlert.objects.filter(
            FarmerID=request.user, IsRead=False
        ).update(IsRead=True)
        return Response({'status': 'success', 'marked_read': updated})


class AlertCountView(APIView):
    """
    GET /api/alerts/unread-count/
    Lightweight endpoint — returns just the badge number.
    Flutter bell icon polls this every 60 s without fetching full payloads.

    Response: { "unread_count": 3 }
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        now       = timezone.now()
        user_dist = (request.user.district or '').strip()

        count = AppAlert.objects.filter(
            Q(FarmerID=request.user)
            | Q(district_target__iexact=user_dist),
            IsRead=False,
        ).exclude(expires_at__lt=now).count()

        return Response({'unread_count': count})


# ── 6. WEB IMAGE SCAN (server-side TFLite for Flutter web) ───────────────────
#
# Flutter web cannot run TFLite WASM due to Chrome's SharedArrayBuffer
# restrictions. This endpoint accepts the raw image bytes, runs the
# model in Python (no WASM), and returns the result.
#
# Mobile (Android/iOS) never calls this — they use the on-device model.
# ─────────────────────────────────────────────────────────────────────────────

# Model is loaded once on first request and cached for all subsequent ones.
_tflite_interpreter = None
_tflite_labels      = []


def _get_tflite_interpreter():
    """
    Lazy-loads the TFLite interpreter once and caches it in memory.
    Expects model files at:
        <same folder as views.py>/models/farm_aid_model.tflite
        <same folder as views.py>/models/labels.txt
    """
    global _tflite_interpreter, _tflite_labels

    if _tflite_interpreter is not None:
        return _tflite_interpreter, _tflite_labels

    base_dir    = os.path.dirname(os.path.abspath(__file__))
    model_path  = os.path.join(base_dir, 'models', 'farm_aid_model.tflite')
    labels_path = os.path.join(base_dir, 'models', 'labels.txt')

    # tflite_runtime is smaller than full tensorflow — try it first
    try:
        import tflite_runtime.interpreter as tflite
        _tflite_interpreter = tflite.Interpreter(model_path=model_path)
    except ImportError:
        import tensorflow as tf
        _tflite_interpreter = tf.lite.Interpreter(model_path=model_path)

    _tflite_interpreter.allocate_tensors()

    with open(labels_path, 'r') as f:
        _tflite_labels = [line.strip() for line in f if line.strip()]

    print(f'✅ TFLite model loaded — {len(_tflite_labels)} labels')
    return _tflite_interpreter, _tflite_labels


class ScanImageView(APIView):
    """
    POST /api/scan-image/
    Accepts : multipart/form-data  →  field name: "image"  (jpg or png)
    Returns : { "label": str, "confidence": float, "is_rejected": bool }
    """
    permission_classes = [AllowAny]  # guest farmers can scan without logging in

    def post(self, request):
        if 'image' not in request.FILES:
            return Response(
                {'error': 'No image provided. Send as multipart field "image".'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            # ── 1. Preprocess ─────────────────────────────────────────────
            image_bytes = request.FILES['image'].read()
            image       = Image.open(BytesIO(image_bytes)).convert('RGB')
            image       = image.resize((224, 224), Image.LANCZOS)

            # Normalise to [0.0, 1.0] — same as the Flutter mobile preprocessing
            input_array = np.expand_dims(
                np.array(image, dtype=np.float32) / 255.0,
                axis=0,
            )  # shape: (1, 224, 224, 3)

            # ── 2. Inference ──────────────────────────────────────────────
            interpreter, labels = _get_tflite_interpreter()

            input_details  = interpreter.get_input_details()
            output_details = interpreter.get_output_details()

            interpreter.set_tensor(input_details[0]['index'], input_array)
            interpreter.invoke()

            output     = interpreter.get_tensor(output_details[0]['index'])[0]
            best_idx   = int(np.argmax(output))
            confidence = float(output[best_idx])
            label      = labels[best_idx] if best_idx < len(labels) else 'Unknown'

            # ── 3. Reject non-vegetable images ────────────────────────────
            reject_keywords = [
                'background', 'rejected', 'non_vegetable',
                'not_vegetable', 'other', 'unknown',
            ]
            is_rejected = (
                any(kw in label.lower() for kw in reject_keywords)
                or confidence < 0.35   # model is too uncertain
            )

            print(f'🌐 scan-image: {label} @ {confidence*100:.1f}%  rejected={is_rejected}')

            return Response({
                'label':       label,
                'confidence':  round(confidence, 4),
                'is_rejected': is_rejected,
            })

        except FileNotFoundError as e:
            return Response(
                {'error': (
                    f'Model file not found on server: {e}. '
                    'Create the folder api/models/ and place '
                    'farm_aid_model.tflite + labels.txt inside it.'
                )},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )
        except Exception as e:
            import traceback
            print(f'❌ scan-image error:\n{traceback.format_exc()}')
            return Response(
                {'error': str(e), 'trace': traceback.format_exc()},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )


# ── 7. AI SCAN & SAVE ────────────────────────────────────────────────────────

class SaveScanView(APIView):
    permission_classes = [IsAuthenticated]

    def _get_sesotho(self, disease_name, field='pesticide'):
        if not disease_name:
            return None
        try:
            cache = TranslationCache.objects.get(disease_name_en__iexact=disease_name)
            return {
                'pesticide': cache.pesticide_st,
                'dosage':    cache.dosage_st,
                'steps':     cache.steps_st,
            }.get(field) or None
        except TranslationCache.DoesNotExist:
            return None
        except Exception:
            return None

    def post(self, request):
        try:
            user = request.user

            import logging
            logger = logging.getLogger(__name__)
            logger.warning(f"[SaveScan] incoming data: {dict(request.data)}")
            logger.warning(f"[SaveScan] scan_mode={request.data.get('scan_mode')} profileId={request.data.get('profileId')} ProfileID={request.data.get('ProfileID')}")

            incoming_lang = request.data.get('language') or request.data.get('lang')
            if incoming_lang in ['st', 'en']:
                user.language_preferences = incoming_lang
                user.save(update_fields=['language_preferences'])
            lang = user.language_preferences

            raw_label   = (request.data.get('diseaseName')
                           or request.data.get('DiseaseName')
                           or 'Healthy')
            clean_label = raw_label.replace('___', ' ').replace('_', ' ').strip()

            image_url   = (request.data.get('imageUrl')
                           or request.data.get('image_url')
                           or request.data.get('ImageFile')
                           or '')

            confidence  = float(
                request.data.get('confidence')
                or request.data.get('ConfidenceLevel')
                or 0.0
            )

            profile_id   = (request.data.get('profileId')
                            or request.data.get('ProfileID'))
            gps_lat      = request.data.get('latitude')
            gps_lon      = request.data.get('longitude')
            gps_alt      = request.data.get('altitude')
            gps_district = (request.data.get('gps_district')
                            or request.data.get('district')
                            or user.district
                            or '')

            scan_mode          = (request.data.get('scan_mode')
                                  or request.data.get('scanMode')
                                  or 'personalized').lower()
            wants_personalized = scan_mode == 'personalized'

            logger.warning(f"[SaveScan] wants_personalized={wants_personalized} scan_mode='{scan_mode}'")

            target_profile = None
            if profile_id and str(profile_id).lower() not in ('null', 'none', ''):
                target_profile = CropProfile.objects.filter(
                    pk=profile_id, FarmerID=user
                ).first()

            logger.warning(f"[SaveScan] profile_id='{profile_id}' target_profile={target_profile} wants_personalized={wants_personalized}")

            crop_type = (target_profile.VegetableType
                         if target_profile
                         else request.data.get('cropType', 'Vegetable'))

            new_plant = Plant.objects.create(
                FarmerID        = user,
                CropProfile     = target_profile,
                CropType        = crop_type,
                ImageFile       = image_url,
                latitude        = gps_lat,
                longitude       = gps_lon,
                altitude_meters = gps_alt,
                gps_district    = gps_district,
            )

            urgent = any(w in clean_label.lower()
                         for w in ['blight', 'rot', 'wilt', 'mold', 'virus',
                                   'bacteria', 'phytophthora', 'fusarium'])
            follow_up_date = date.today() + timedelta(days=3 if urgent else 10)

            diagnosis = Diagnosis.objects.create(
                PlantID         = new_plant,
                DiseaseName     = clean_label,
                ConfidenceLevel = confidence,
                follow_up_date  = follow_up_date,
            )

            tq       = Q(DiseaseName__iexact=clean_label) | Q(DiseaseName__iexact=raw_label)
            treat    = Treatment.objects.filter(tq).first()
            kb_entry = KnowledgeBase.objects.filter(tq).first()

            res_pesticide = treat.RecommendedPesticide if treat else 'Consult local expert'
            res_dosage    = treat.Dosage               if treat else 'N/A'
            if treat and treat.ApplicationSteps:
                res_steps = treat.ApplicationSteps
            elif kb_entry and kb_entry.TreatmentInfo:
                res_steps = kb_entry.TreatmentInfo
            else:
                res_steps = 'Isolate plant immediately and consult your local agricultural officer.'

            res_disease = clean_label

            dosage_calc = {}
            plot_ha     = target_profile.plot_size_hectares if target_profile else None
            if treat and plot_ha:
                dosage_calc = treat.calculate_for_plot(plot_ha)

            if lang == 'st':
                st_p = self._get_sesotho(clean_label, 'pesticide')
                st_d = self._get_sesotho(clean_label, 'dosage')
                st_s = self._get_sesotho(clean_label, 'steps')
                if st_p: res_pesticide = st_p
                if st_d: res_dosage    = st_d
                if st_s: res_steps     = st_s

            personalized_advice = None
            matched_context     = None
            personalized_dosage = None

            if wants_personalized and target_profile:
                try:
                    weather     = WeatherData.objects.filter(
                        district__iexact=gps_district
                    ).order_by('-DateUpdated').first()
                    rainfall_mm = weather.rainfall_last_7_days if weather else 0.0

                    match = RuleMatchingService.get_best_match(
                        disease_name    = clean_label,
                        farmer          = user,
                        crop_profile    = target_profile,
                        gps_district    = gps_district,
                        rainfall_mm     = rainfall_mm,
                        altitude_meters = gps_alt,
                    )
                    if match.get('found'):
                        personalized_advice = match['advice']
                        matched_context     = match.get('matched_on')
                        logger.warning(f"[SaveScan] ✅ Rule matched: rule_id={match.get('rule_id')} advice={personalized_advice[:60]}")
                    else:
                        logger.warning(f"[SaveScan] ❌ No rule matched for disease='{clean_label}' district='{gps_district}'")
                except Exception:
                    pass

                if dosage_calc:
                    personalized_dosage = {
                        'product':       res_pesticide,
                        'amount':        dosage_calc.get('product_display'),
                        'water':         dosage_calc.get('water_display'),
                        'unit':          dosage_calc.get('dosage_unit'),
                        'plot_hectares': dosage_calc.get('plot_hectares'),
                        'raw': {
                            'product_amount': dosage_calc.get('product_amount'),
                            'water_litres':   dosage_calc.get('water_litres'),
                            'buckets_10l':    dosage_calc.get('buckets_10l'),
                        },
                    }

            personalized_block = None
            if wants_personalized and target_profile:
                personalized_block = {
                    'advice':       personalized_advice,
                    'dosage':       personalized_dosage,
                    'matched_on':   matched_context,
                    'farmer_level': user.experience_level,
                }

            return Response({
                'status':         'success',
                'id':             diagnosis.DiagnosisID,
                'follow_up_date': follow_up_date.isoformat(),
                'crop_type':      crop_type,
                'scan_mode':      scan_mode,
                '_debug': {
                    'received_scan_mode':          scan_mode,
                    'received_profile_id':          str(profile_id),
                    'wants_personalized':           wants_personalized,
                    'target_profile_found':         target_profile is not None,
                    'target_profile_id':            str(target_profile.ProfileID) if target_profile else None,
                    'rule_match_found':             bool(personalized_advice),
                    'personalized_advice_preview':  personalized_advice[:80] if personalized_advice else None,
                },
                'personalized':   personalized_block,
                'results': {
                    'disease':    res_disease,
                    'pesticide':  res_pesticide,
                    'dosage':     res_dosage,
                    'steps':      res_steps,
                    'confidence': confidence,
                    'possible_causes': _get_causes(clean_label),
                    'treatment_dose_display': dosage_calc.get('product_display') if dosage_calc and wants_personalized else None,
                    'water_volume_display':   dosage_calc.get('water_display')   if dosage_calc and wants_personalized else None,
                },
                'treatment_product':   res_pesticide,
                'personalized_advice': personalized_advice,
            })

        except Exception as e:
            import traceback
            return Response(
                {'error': str(e), 'detail': traceback.format_exc()},
                status=status.HTTP_400_BAD_REQUEST,
            )


# ── 8. HISTORY & REPORTS ─────────────────────────────────────────────────────

class FarmerHistoryView(APIView):
    """
    GET /api/farmer-history/
    Returns each scanned plant with its latest diagnosis.

    Optional query params:
      ?limit=N        — return only the N most recent records (default: all)
      ?disease=name   — filter by disease name (case-insensitive, partial match)
      ?crop=name      — filter by crop type
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        plants = Plant.objects.filter(FarmerID=request.user).order_by('-DateCaptured')

        # Optional crop filter
        crop_filter = request.query_params.get('crop')
        if crop_filter:
            plants = plants.filter(CropType__icontains=crop_filter)

        # Optional limit
        limit = request.query_params.get('limit')
        if limit:
            try:
                plants = plants[:int(limit)]
            except (ValueError, TypeError):
                pass

        history = []
        for p in plants:
            diag = Diagnosis.objects.filter(PlantID=p).order_by('-DateDiagnosed').first()
            if not diag:
                continue

            # Optional disease filter (applied after fetch to allow partial match)
            disease_filter = request.query_params.get('disease', '')
            if disease_filter and disease_filter.lower() not in diag.DiseaseName.lower():
                continue

            is_healthy  = diag.DiseaseName.lower() == 'healthy'
            risk_score  = 0.0 if is_healthy else float(diag.ConfidenceLevel or 0.0)

            history.append({
                'plant_id':         p.PlantID,
                'crop':             p.CropType,
                'image':            p.ImageFile,
                'disease':          diag.DiseaseName,
                'disease_display':  diag.DiseaseName.replace('_', ' ').title(),
                'confidence':       float(diag.ConfidenceLevel or 0.0),
                'risk':             risk_score,
                'is_healthy':       is_healthy,
                'severity':         diag.severity,
                'follow_up_date':   diag.follow_up_date.isoformat() if diag.follow_up_date else None,
                'feedback_given':   bool(diag.farmer_feedback),
                'date':             p.DateCaptured.strftime('%d %b, %Y'),
                'date_iso':         p.DateCaptured.isoformat(),
                'district':         p.gps_district or '',
                'latitude':         p.latitude,
                'longitude':        p.longitude,
                'diagnosis_id':     diag.DiagnosisID,
            })

        return Response(history)


class FarmerReportsView(APIView):
    """
    GET /api/farmer-reports/
    Returns enriched scan records used by the Insights & History screens.

    Each record includes:
      - ReportDate, DiagnosisSummary, Confidence, TreatmentSummary, ImageURL
      - risk  : 0.0 for healthy scans, ConfidenceLevel for diseased (used by trend chart)
      - date  : parsed DateTime object hint (ISO string) so Flutter can build the chart axis
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        plants      = Plant.objects.filter(FarmerID=request.user).order_by('-DateCaptured')
        report_data = []

        for p in plants:
            diag = Diagnosis.objects.filter(PlantID=p).order_by('-DateDiagnosed').first()
            if not diag:
                continue

            treat = Treatment.objects.filter(
                DiseaseName__iexact=diag.DiseaseName
            ).first()

            is_healthy = diag.DiseaseName.lower() == 'healthy'
            risk_score = 0.0 if is_healthy else float(diag.ConfidenceLevel or 0.0)

            treatment_text = 'No treatment needed — plant is healthy.'
            if not is_healthy:
                if treat and treat.ApplicationSteps:
                    treatment_text = treat.ApplicationSteps
                else:
                    treatment_text = 'Isolate plant immediately and consult your local agricultural officer.'

            report_data.append({
                'FarmerID_id':      request.user.id,
                'ReportDate':       p.DateCaptured.isoformat(),
                'DiagnosisSummary': diag.DiseaseName.replace('_', ' ').upper(),
                'Confidence':       float(diag.ConfidenceLevel or 0.0),
                'risk':             risk_score,          # ← used by TrendChart in Flutter
                'is_healthy':       is_healthy,
                'TreatmentSummary': treatment_text,
                'pesticide':        treat.RecommendedPesticide if treat else '',
                'dosage':           treat.Dosage if treat else '',
                'ImageURL':         p.ImageFile,
                'crop':             p.CropType,
                'district':         p.gps_district or '',
                'diagnosis_id':     diag.DiagnosisID,
                'severity':         diag.severity,
                'follow_up_date':   diag.follow_up_date.isoformat() if diag.follow_up_date else None,
                'feedback':         diag.farmer_feedback,
                'treatment_applied': diag.treatment_applied,
                'treatment_outcome': diag.treatment_outcome,
            })

        return Response(report_data)


# ── 9. MARKET PRICES ─────────────────────────────────────────────────────────

class MarketPricesView(APIView):
    """
    GET /api/market-prices/
    Optional query params:
      ?district=Maseru   — filter by district
      ?vegetable=tomato  — filter by vegetable name (partial, case-insensitive)
      ?limit=N           — cap results

    Returns prices sorted newest first with trend badge.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        prices = MarketPrice.objects.all().order_by('-date_recorded')

        district  = request.query_params.get('district')
        vegetable = request.query_params.get('vegetable')
        limit     = request.query_params.get('limit')

        if district:
            prices = prices.filter(district__iexact=district)
        if vegetable:
            prices = prices.filter(vegetable_name__icontains=vegetable)
        if limit:
            try:
                prices = prices[:int(limit)]
            except (ValueError, TypeError):
                pass

        data = []
        for p in prices:
            # Compute a simple week-over-week change label
            prev = (
                MarketPrice.objects
                .filter(
                    vegetable_name__iexact=p.vegetable_name,
                    market_name__iexact=p.market_name,
                    date_recorded__lt=p.date_recorded,
                )
                .order_by('-date_recorded')
                .first()
            )
            change_pct = None
            if prev and prev.price_per_kg:
                change_pct = round(
                    float((p.price_per_kg - prev.price_per_kg) / prev.price_per_kg * 100), 1
                )

            data.append({
                'id':             p.PriceID,
                'vegetable_name': p.vegetable_name,
                'market_name':    p.market_name,
                'district':       p.district,
                'price_per_kg':   float(p.price_per_kg),
                'currency':       p.currency,
                'date_recorded':  p.date_recorded.isoformat(),
                'price_trend':    p.price_trend,
                'change_pct':     change_pct,   # e.g. +5.2 or -3.1 or null
            })

        return Response(data)


# ── 10. DIAGNOSIS FEEDBACK ────────────────────────────────────────────────────

class DiagnosisFeedbackView(APIView):
    """
    GET   /api/diagnosis/<id>/feedback/  → retrieve current feedback for a diagnosis
    PATCH /api/diagnosis/<id>/feedback/  → submit or update feedback

    PATCH body (all fields optional):
      {
        "farmer_feedback":   "correct" | "incorrect" | "unsure",
        "severity":          "mild" | "moderate" | "severe",
        "treatment_applied": true | false,
        "treatment_outcome": "recovered" | "no_change" | "worsened"
      }
    """
    permission_classes = [IsAuthenticated]

    def _get_diagnosis(self, request, diagnosis_id):
        try:
            return Diagnosis.objects.get(
                DiagnosisID=diagnosis_id,
                PlantID__FarmerID=request.user,
            )
        except Diagnosis.DoesNotExist:
            return None

    def get(self, request, diagnosis_id):
        diag = self._get_diagnosis(request, diagnosis_id)
        if not diag:
            return Response({'error': 'Diagnosis not found'}, status=404)

        return Response({
            'diagnosis_id':     diag.DiagnosisID,
            'disease':          diag.DiseaseName,
            'confidence':       float(diag.ConfidenceLevel or 0.0),
            'farmer_feedback':  diag.farmer_feedback,
            'severity':         diag.severity,
            'treatment_applied': diag.treatment_applied,
            'treatment_outcome': diag.treatment_outcome,
            'follow_up_date':   diag.follow_up_date.isoformat() if diag.follow_up_date else None,
            'date_diagnosed':   diag.DateDiagnosed.isoformat(),
        })

    def patch(self, request, diagnosis_id):
        diag = self._get_diagnosis(request, diagnosis_id)
        if not diag:
            return Response({'error': 'Diagnosis not found'}, status=404)

        allowed = ('farmer_feedback', 'severity', 'treatment_applied', 'treatment_outcome')
        for field in allowed:
            val = request.data.get(field)
            if val is not None:
                setattr(diag, field, val)
        diag.save()

        return Response({
            'status':           'success',
            'message':          'Feedback recorded. Thank you!',
            'id':               diag.DiagnosisID,
            'farmer_feedback':  diag.farmer_feedback,
            'severity':         diag.severity,
            'treatment_applied': diag.treatment_applied,
            'treatment_outcome': diag.treatment_outcome,
        })


# ── 11. FARMER INSIGHTS ──────────────────────────────────────────────────────

class FarmerInsightView(APIView):
    """
    GET /api/farmer-insights/
    Returns aggregate statistics AND a time-series trend list for the chart.

    Response:
      total_scans, total_diseases_detected, total_healthy_scans,
      most_common_disease, most_scanned_crop, streak_healthy_days,
      last_updated,
      disease_breakdown: [ { disease, count, percentage } ]   ← pie chart
      trend:             [ { date, risk } ]                    ← line chart
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        from django.db.models import Count

        insight, _ = FarmerInsight.objects.get_or_create(FarmerID=request.user)

        plants      = Plant.objects.filter(FarmerID=request.user)
        total_scans = plants.count()
        diagnoses   = Diagnosis.objects.filter(PlantID__in=plants).select_related('PlantID')

        healthy_qs = diagnoses.filter(DiseaseName__iexact='healthy')
        healthy    = healthy_qs.count()
        diseased   = total_scans - healthy

        # ── Most common disease ───────────────────────────────────────────
        top = (
            diagnoses
            .exclude(DiseaseName__iexact='healthy')
            .values('DiseaseName')
            .annotate(c=Count('DiseaseName'))
            .order_by('-c')
            .first()
        )

        # ── Most scanned crop ─────────────────────────────────────────────
        top_crop = (
            plants
            .exclude(CropType='Vegetable')
            .values('CropType')
            .annotate(c=Count('CropType'))
            .order_by('-c')
            .first()
        )

        # ── Disease breakdown for pie chart ───────────────────────────────
        breakdown_qs = (
            diagnoses
            .values('DiseaseName')
            .annotate(count=Count('DiseaseName'))
            .order_by('-count')
        )
        disease_breakdown = []
        for row in breakdown_qs:
            pct = round(row['count'] / total_scans * 100, 1) if total_scans else 0.0
            disease_breakdown.append({
                'disease':    row['DiseaseName'].replace('_', ' ').title(),
                'count':      row['count'],
                'percentage': pct,
            })

        # ── Trend data for line chart (one point per scan, chronological) ─
        # risk = 0.0 for healthy, ConfidenceLevel for diseased
        trend_qs = (
            diagnoses
            .select_related('PlantID')
            .order_by('PlantID__DateCaptured')
        )
        trend = []
        for d in trend_qs:
            is_healthy = d.DiseaseName.lower() == 'healthy'
            risk       = 0.0 if is_healthy else float(d.ConfidenceLevel or 0.0)
            trend.append({
                'date': d.PlantID.DateCaptured.isoformat(),
                'risk': round(risk, 4),
            })

        # ── Persist summary to FarmerInsight model ────────────────────────
        insight.total_scans             = total_scans
        insight.total_diseases_detected = diseased
        insight.total_healthy_scans     = healthy
        insight.most_common_disease     = top['DiseaseName']   if top      else None
        insight.most_scanned_crop       = top_crop['CropType'] if top_crop else None
        insight.save()

        return Response({
            'total_scans':             total_scans,
            'total_diseases_detected': diseased,
            'total_healthy_scans':     healthy,
            'most_common_disease':     insight.most_common_disease,
            'most_scanned_crop':       insight.most_scanned_crop,
            'streak_healthy_days':     insight.streak_healthy_days,
            'last_updated':            insight.last_updated.isoformat(),
            'disease_breakdown':       disease_breakdown,
            'trend':                   trend,
        })


# ── 12. GROWTH JOURNAL ────────────────────────────────────────────────────────

class GrowthJournalView(APIView):
    """
    GET    /api/growth-journal/                 → list entries (optional ?crop_profile_id=)
    POST   /api/growth-journal/                 → create new entry
    PATCH  /api/growth-journal/<entry_id>/      → update an existing entry
    DELETE /api/growth-journal/<entry_id>/      → delete an entry
    """
    permission_classes = [IsAuthenticated]

    def _serialize(self, e):
        return {
            'id':              e.EntryID,
            'crop_profile_id': e.CropProfile.ProfileID,
            'crop_name':       e.CropProfile.VegetableType,
            'growth_stage':    e.CropProfile.growth_stage_label,
            'entry_date':      e.entry_date.isoformat(),
            'title':           e.title,
            'body':            e.body,
            'mood':            e.mood,
            'photo_url':       e.photo_url,
            'created_at':      e.DateCreated.isoformat(),
        }

    def get(self, request):
        profile_id = request.query_params.get('crop_profile_id')
        entries    = GrowthJournalEntry.objects.filter(FarmerID=request.user)
        if profile_id:
            entries = entries.filter(CropProfile__ProfileID=profile_id)
        return Response([self._serialize(e) for e in entries])

    def post(self, request):
        try:
            profile = CropProfile.objects.get(
                ProfileID=request.data.get('crop_profile_id'),
                FarmerID=request.user,
            )
        except CropProfile.DoesNotExist:
            return Response({'error': 'Crop profile not found'}, status=404)

        raw_date   = request.data.get('entry_date')
        entry_date = date.today()
        if raw_date:
            try:
                from datetime import datetime as dt
                entry_date = dt.fromisoformat(str(raw_date)).date()
            except (ValueError, TypeError):
                pass

        entry = GrowthJournalEntry.objects.create(
            FarmerID    = request.user,
            CropProfile = profile,
            title       = request.data.get('title', ''),
            body        = request.data.get('body', ''),
            mood        = request.data.get('mood', 'ok'),
            photo_url   = request.data.get('photo_url'),
            entry_date  = entry_date,
        )
        return Response({'status': 'success', 'id': entry.EntryID, 'entry': self._serialize(entry)}, status=201)

    def patch(self, request, entry_id=None):
        if entry_id is None:
            return Response({'error': 'entry_id required'}, status=400)
        try:
            entry = GrowthJournalEntry.objects.get(EntryID=entry_id, FarmerID=request.user)
        except GrowthJournalEntry.DoesNotExist:
            return Response({'error': 'Entry not found'}, status=404)

        for field in ('title', 'body', 'mood', 'photo_url'):
            val = request.data.get(field)
            if val is not None:
                setattr(entry, field, val)

        raw_date = request.data.get('entry_date')
        if raw_date:
            try:
                from datetime import datetime as dt
                entry.entry_date = dt.fromisoformat(str(raw_date)).date()
            except (ValueError, TypeError):
                pass

        entry.save()
        return Response({'status': 'updated', 'entry': self._serialize(entry)})

    def delete(self, request, entry_id=None):
        if entry_id is None:
            return Response({'error': 'entry_id required'}, status=400)
        try:
            entry = GrowthJournalEntry.objects.get(EntryID=entry_id, FarmerID=request.user)
            entry.delete()
            return Response({'status': 'deleted'})
        except GrowthJournalEntry.DoesNotExist:
            return Response({'error': 'Entry not found'}, status=404)


# ── PASSWORD RESET ──────────────────────────────────────────────────────────────
@api_view(['POST'])
@permission_classes([AllowAny])
def password_reset_request(request):
    """
    POST /api/auth/password-reset/
    Body: { "email": "farmer@example.com" }
    Sends a password-reset e-mail if the account exists.
    Always returns 200 to avoid user-enumeration.
    """
    email = request.data.get('email', '').strip().lower()
    if not email:
        return Response({'error': 'Email is required.'}, status=400)

    try:
        farmer = Farmer.objects.get(email__iexact=email)
    except Farmer.DoesNotExist:
        # Return 200 to avoid revealing whether the account exists
        return Response({'status': 'If that address is registered, a reset link has been sent.'})

    uid   = urlsafe_base64_encode(force_bytes(farmer.pk))
    token = default_token_generator.make_token(farmer)

    site = get_current_site(request)
    reset_link = f"https://{site.domain}/api/auth/password-reset/confirm/{uid}/{token}/"

    subject = 'FarmAid Lesotho — Password Reset'
    body = (
        f"Hi {farmer.first_name or farmer.username},\n\n"
        f"Click the link below to reset your FarmAid password:\n\n"
        f"{reset_link}\n\n"
        f"This link expires in 24 hours.\n\n"
        f"If you did not request a password reset, ignore this e-mail.\n\n"
        f"— The FarmAid Team"
    )
    try:
        mail = EmailMessage(subject=subject, body=body, to=[farmer.email])
        mail.send(fail_silently=True)
    except Exception:
        pass  # Log silently; don't expose mail errors to client

    return Response({'status': 'If that address is registered, a reset link has been sent.'})
