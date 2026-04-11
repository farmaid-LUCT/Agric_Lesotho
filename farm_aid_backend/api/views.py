# from rest_framework import status
# from rest_framework.response import Response
# from rest_framework.decorators import api_view, permission_classes
# from rest_framework.views import APIView
# from rest_framework.permissions import IsAuthenticated, AllowAny
# from datetime import date, timedelta
# from rest_framework.authtoken.models import Token
# from django.contrib.auth import authenticate
# from django.contrib.auth.password_validation import validate_password
# from django.core.exceptions import ValidationError as DjangoValidationError
# from django.db.models import Q
# from django.utils import timezone
# import hashlib

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
#     TranslationCache, MarketPrice, FarmerInsight, GrowthJournalEntry,
#     RuleMatchingService, CommunityPost, PostLike, CommunityComment,
# )
# from .serializers import CropProfileSerializer, AppAlertSerializer, WeatherDataSerializer


# # ── 1. AUTHENTICATION ────────────────────────────────────────────────────────

# @api_view(['POST'])
# @permission_classes([AllowAny])
# def register_farmer(request):
#     data = request.data
#     try:
#         # ── a. Duplicate email check ──────────────────────────────────────
#         if Farmer.objects.filter(email=data.get('email', '').lower()).exists():
#             return Response(
#                 {'error': 'Email already exists'},
#                 status=status.HTTP_400_BAD_REQUEST,
#             )

#         # ── b. Password strength validation ──────────────────────────────
#         # Runs ALL validators listed in AUTH_PASSWORD_VALIDATORS in settings.py
#         # including our custom PasswordStrengthValidator & NoCommonPasswordValidator
#         raw_password = data.get('password', '')
#         try:
#             validate_password(raw_password)
#         except DjangoValidationError as exc:
#             return Response(
#                 {
#                     'error':   'Password is too weak.',
#                     'details': list(exc.messages),   # e.g. ["Must contain uppercase", ...]
#                 },
#                 status=status.HTTP_400_BAD_REQUEST,
#             )

#         # ── c. Create user (inactive until email verified) ───────────────
#         user = Farmer.objects.create_user(
#             username=data.get('email'),
#             email=data.get('email'),
#             password=raw_password,
#             first_name=data.get('first_name', ''),
#             last_name=data.get('last_name', ''),
#             phone_number=data.get('phone_number', ''),
#             district=data.get('district', '') or data.get('location', ''),
#             language_preferences=data.get('language_preferences', 'en'),
#         )
#         user.is_active = False
#         user.save()
#         send_activation_email(request, user)
#         return Response({
#             'status':  'success',
#             'message': 'Verification email sent.',
#             'email':   user.email,
#         }, status=status.HTTP_201_CREATED)

#     except Exception as e:
#         return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# def send_activation_email(request, user):
#     current_site    = get_current_site(request)
#     uid             = urlsafe_base64_encode(force_bytes(user.pk))
#     token           = default_token_generator.make_token(user)
#     activation_link = f"http://{current_site.domain}/api/activate/{uid}/{token}/"
#     EmailMessage(
#         'Activate your FarmAid Lesotho Account',
#         f"Dumela {user.first_name},\n\nPlease click link to verify: {activation_link}",
#         to=[user.email],
#     ).send()


# @api_view(['POST'])
# @permission_classes([AllowAny])
# def resend_activation_email(request):
#     try:
#         user = Farmer.objects.get(email=request.data.get('email'))
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
#         uid  = force_str(urlsafe_base64_decode(uidb64))
#         user = Farmer.objects.get(pk=uid)
#     except (TypeError, ValueError, OverflowError, Farmer.DoesNotExist):
#         user = None

#     if user is not None and default_token_generator.check_token(user, token):
#         user.is_active = True
#         user.save()
#         return render(request, 'api/activation_success.html')
#     return HttpResponse("<h2>Activation link is invalid.</h2>", status=400)


# @api_view(['POST'])
# @permission_classes([AllowAny])
# def login_farmer(request):
#     user = authenticate(
#         username=request.data.get('email'),
#         password=request.data.get('password'),
#     )
#     if user:
#         if not user.is_active:
#             return Response({'error': 'unverified'}, status=403)
#         token, _ = Token.objects.get_or_create(user=user)
#         return Response({
#             'token':      token.key,
#             'farmerName': f"{user.first_name} {user.last_name}".strip(),
#             'is_staff':   user.is_staff,
#         })
#     return Response({'error': 'Invalid credentials'}, status=401)


# @api_view(['POST'])
# @permission_classes([IsAuthenticated])
# def change_password(request):
#     user = request.user

#     if not user.check_password(request.data.get('old_password', '')):
#         return Response({'error': 'Incorrect current password.'}, status=400)

#     new_pw = request.data.get('new_password', '')
#     try:
#         validate_password(new_pw, user=user)
#     except DjangoValidationError as exc:
#         return Response(
#             {'error': 'New password is too weak.', 'details': list(exc.messages)},
#             status=400,
#         )

#     user.set_password(new_pw)
#     user.save()
#     # Re-issue token so Flutter app stays logged in after password change
#     Token.objects.filter(user=user).delete()
#     new_token, _ = Token.objects.get_or_create(user=user)
#     return Response({
#         'status':  'success',
#         'message': 'Password updated!',
#         'token':   new_token.key,   # Flutter should store this new token
#     })


# # ── 2. GOOGLE SIGN-IN ─────────────────────────────────────────────────────────

# @api_view(['POST'])
# @permission_classes([AllowAny])
# def google_auth(request):
#     """
#     POST /api/auth/google/
#     Body: { "id_token": "<Google ID token from Flutter google_sign_in>" }

#     Flutter usage:
#       final googleUser = await GoogleSignIn().signIn();
#       final auth        = await googleUser!.authentication;
#       // POST auth.idToken to this endpoint → receive { token, farmerName, ... }

#     Requirements:
#       pip install google-auth
#       Set GOOGLE_CLIENT_ID in settings.py or as env variable.
#     """
#     from django.conf import settings as django_settings

#     id_token_str = request.data.get('id_token', '').strip()
#     if not id_token_str:
#         return Response({'error': 'id_token is required.'}, status=400)

#     # ── Verify the token with Google ──────────────────────────────────────
#     try:
#         from google.oauth2 import id_token as google_id_token
#         from google.auth.transport import requests as google_requests

#         client_id = getattr(django_settings, 'GOOGLE_CLIENT_ID', '')
#         id_info   = google_id_token.verify_oauth2_token(
#             id_token_str,
#             google_requests.Request(),
#             client_id,
#         )
#     except ImportError:
#         return Response(
#             {'error': 'google-auth package not installed. Run: pip install google-auth'},
#             status=500,
#         )
#     except ValueError as exc:
#         return Response({'error': f'Invalid Google token: {exc}'}, status=401)

#     email      = id_info.get('email', '').lower()
#     first_name = id_info.get('given_name', '')
#     last_name  = id_info.get('family_name', '')
#     photo_url  = id_info.get('picture', '')

#     if not email:
#         return Response({'error': 'Google account has no email address.'}, status=400)

#     # ── Get or create the Farmer account ─────────────────────────────────
#     user, created = Farmer.objects.get_or_create(
#         email=email,
#         defaults={
#             'username':   email,
#             'first_name': first_name,
#             'last_name':  last_name,
#             'is_active':  True,   # Google already verified the email
#         },
#     )

#     if created:
#         user.set_unusable_password()   # Google-only login, no password needed
#         if photo_url:
#             user.profile_photo_url = photo_url
#         user.save()
#     elif not user.is_active:
#         user.is_active = True
#         user.save()

#     token, _ = Token.objects.get_or_create(user=user)
#     return Response({
#         'token':      token.key,
#         'farmerName': f"{user.first_name} {user.last_name}".strip() or email,
#         'is_staff':   user.is_staff,
#         'email':      user.email,
#         'created':    created,   # True = new account, False = existing account
#     })


# # ── 3. PROFILE & WEATHER ─────────────────────────────────────────────────────

# class ProfileView(APIView):
#     permission_classes = [IsAuthenticated]

#     def get(self, request):
#         u = request.user
#         return Response({
#             'first_name':           u.first_name,
#             'last_name':            u.last_name,
#             'email':                u.email,
#             'district':             u.district,
#             'phone_number':         u.phone_number,
#             'language_preferences': u.language_preferences,
#             'experience_level':     u.experience_level,
#             'profile_photo_url':    u.profile_photo_url,
#             'farm_size_hectares':   u.farm_size_hectares  if hasattr(u, 'farm_size_hectares')  else None,
#             'onboarding_complete':  u.onboarding_complete if hasattr(u, 'onboarding_complete') else False,
#         })

#     def patch(self, request):
#         user = request.user
#         for attr, value in request.data.items():
#             if hasattr(user, attr):
#                 setattr(user, attr, value)
#         user.save()
#         return Response({
#             'status':     'success',
#             'farmerName': f"{user.first_name} {user.last_name}",
#         })


# class LatestWeatherView(APIView):
#     permission_classes = [AllowAny]

#     def get(self, request):
#         latest = WeatherData.objects.order_by('-DateUpdated').first()
#         return (
#             Response(WeatherDataSerializer(latest).data)
#             if latest else Response({'error': 'No data'}, status=404)
#         )


# # ── 4. CROP PROFILES ─────────────────────────────────────────────────────────

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


# # ── 5. ALERTS ────────────────────────────────────────────────────────────────

# class FarmerAlertsView(APIView):
#     """
#     GET  /api/alerts/            → list all alerts (with unread count)
#     POST /api/alerts/mark-read/  → mark all unread alerts as read

#     Response shape change:
#       OLD: [ {...}, {...} ]              ← bare list
#       NEW: { count, unread_count, alerts: [...] }  ← dict with meta

#     Flutter: update your alerts page to read response['alerts'] instead of
#     treating the response as a list directly.
#     """
#     permission_classes = [IsAuthenticated]

#     def get(self, request):
#         user      = request.user
#         user_dist = (user.district or '').strip()
#         now       = timezone.now()

#         qs = AppAlert.objects.filter(
#             Q(FarmerID=user)
#             | Q(district_target__iexact=user_dist)
#         ).exclude(
#             expires_at__lt=now     # hide expired alerts
#         ).order_by('-DateCreated')

#         # Optional filter by type: GET /api/alerts/?type=weather
#         alert_type = request.query_params.get('type')
#         if alert_type:
#             qs = qs.filter(alert_type=alert_type)

#         return Response({
#             'count':        qs.count(),
#             'unread_count': qs.filter(IsRead=False).count(),
#             'alerts':       AppAlertSerializer(qs, many=True).data,
#         })

#     def post(self, request):
#         updated = AppAlert.objects.filter(
#             FarmerID=request.user, IsRead=False
#         ).update(IsRead=True)
#         return Response({'status': 'success', 'marked_read': updated})


# class AlertCountView(APIView):
#     """
#     GET /api/alerts/unread-count/
#     Lightweight endpoint — returns just the badge number.
#     Flutter bell icon polls this every 60 s without fetching full payloads.

#     Response: { "unread_count": 3 }
#     """
#     permission_classes = [IsAuthenticated]

#     def get(self, request):
#         now       = timezone.now()
#         user_dist = (request.user.district or '').strip()

#         count = AppAlert.objects.filter(
#             Q(FarmerID=request.user)
#             | Q(district_target__iexact=user_dist),
#             IsRead=False,
#         ).exclude(expires_at__lt=now).count()

#         return Response({'unread_count': count})


# # ── 6. AI SCAN & SAVE ────────────────────────────────────────────────────────

# class SaveScanView(APIView):
#     permission_classes = [IsAuthenticated]

#     def _get_sesotho(self, disease_name, field='pesticide'):
#         if not disease_name:
#             return None
#         try:
#             cache = TranslationCache.objects.get(disease_name_en__iexact=disease_name)
#             return {
#                 'pesticide': cache.pesticide_st,
#                 'dosage':    cache.dosage_st,
#                 'steps':     cache.steps_st,
#             }.get(field) or None
#         except TranslationCache.DoesNotExist:
#             return None
#         except Exception:
#             return None

#     def post(self, request):
#         try:
#             user = request.user

#             import logging
#             logger = logging.getLogger(__name__)
#             logger.warning(f"[SaveScan] incoming data: {dict(request.data)}")
#             logger.warning(f"[SaveScan] scan_mode={request.data.get('scan_mode')} profileId={request.data.get('profileId')} ProfileID={request.data.get('ProfileID')}")

#             incoming_lang = request.data.get('language') or request.data.get('lang')
#             if incoming_lang in ['st', 'en']:
#                 user.language_preferences = incoming_lang
#                 user.save(update_fields=['language_preferences'])
#             lang = user.language_preferences

#             raw_label   = (request.data.get('diseaseName')
#                            or request.data.get('DiseaseName')
#                            or 'Healthy')
#             clean_label = raw_label.replace('___', ' ').replace('_', ' ').strip()

#             image_url   = (request.data.get('imageUrl')
#                            or request.data.get('image_url')
#                            or request.data.get('ImageFile')
#                            or '')

#             confidence  = float(
#                 request.data.get('confidence')
#                 or request.data.get('ConfidenceLevel')
#                 or 0.0
#             )

#             profile_id   = (request.data.get('profileId')
#                             or request.data.get('ProfileID'))
#             gps_lat      = request.data.get('latitude')
#             gps_lon      = request.data.get('longitude')
#             gps_alt      = request.data.get('altitude')
#             gps_district = (request.data.get('gps_district')
#                             or request.data.get('district')
#                             or user.district
#                             or '')

#             scan_mode          = (request.data.get('scan_mode')
#                                   or request.data.get('scanMode')
#                                   or 'personalized').lower()
#             wants_personalized = scan_mode == 'personalized'

#             logger.warning(f"[SaveScan] wants_personalized={wants_personalized} scan_mode='{scan_mode}'")

#             target_profile = None
#             if profile_id and str(profile_id).lower() not in ('null', 'none', ''):
#                 target_profile = CropProfile.objects.filter(
#                     pk=profile_id, FarmerID=user
#                 ).first()

#             logger.warning(f"[SaveScan] profile_id='{profile_id}' target_profile={target_profile} wants_personalized={wants_personalized}")

#             crop_type = (target_profile.VegetableType
#                          if target_profile
#                          else request.data.get('cropType', 'Vegetable'))

#             new_plant = Plant.objects.create(
#                 FarmerID        = user,
#                 CropProfile     = target_profile,
#                 CropType        = crop_type,
#                 ImageFile       = image_url,
#                 latitude        = gps_lat,
#                 longitude       = gps_lon,
#                 altitude_meters = gps_alt,
#                 gps_district    = gps_district,
#             )

#             urgent = any(w in clean_label.lower()
#                          for w in ['blight', 'rot', 'wilt', 'mold', 'virus',
#                                    'bacteria', 'phytophthora', 'fusarium'])
#             follow_up_date = date.today() + timedelta(days=3 if urgent else 10)

#             diagnosis = Diagnosis.objects.create(
#                 PlantID         = new_plant,
#                 DiseaseName     = clean_label,
#                 ConfidenceLevel = confidence,
#                 follow_up_date  = follow_up_date,
#             )

#             tq       = Q(DiseaseName__iexact=clean_label) | Q(DiseaseName__iexact=raw_label)
#             treat    = Treatment.objects.filter(tq).first()
#             kb_entry = KnowledgeBase.objects.filter(tq).first()

#             res_pesticide = treat.RecommendedPesticide if treat else 'Consult local expert'
#             res_dosage    = treat.Dosage               if treat else 'N/A'
#             if treat and treat.ApplicationSteps:
#                 res_steps = treat.ApplicationSteps
#             elif kb_entry and kb_entry.TreatmentInfo:
#                 res_steps = kb_entry.TreatmentInfo
#             else:
#                 res_steps = 'Isolate plant immediately and consult your local agricultural officer.'

#             res_disease = clean_label

#             dosage_calc = {}
#             plot_ha     = target_profile.plot_size_hectares if target_profile else None
#             if treat and plot_ha:
#                 dosage_calc = treat.calculate_for_plot(plot_ha)

#             if lang == 'st':
#                 st_p = self._get_sesotho(clean_label, 'pesticide')
#                 st_d = self._get_sesotho(clean_label, 'dosage')
#                 st_s = self._get_sesotho(clean_label, 'steps')
#                 if st_p: res_pesticide = st_p
#                 if st_d: res_dosage    = st_d
#                 if st_s: res_steps     = st_s

#             personalized_advice = None
#             matched_context     = None
#             personalized_dosage = None

#             if wants_personalized and target_profile:
#                 try:
#                     weather     = WeatherData.objects.filter(
#                         district__iexact=gps_district
#                     ).order_by('-DateUpdated').first()
#                     rainfall_mm = weather.rainfall_last_7_days if weather else 0.0

#                     match = RuleMatchingService.get_best_match(
#                         disease_name    = clean_label,
#                         farmer          = user,
#                         crop_profile    = target_profile,
#                         gps_district    = gps_district,
#                         rainfall_mm     = rainfall_mm,
#                         altitude_meters = gps_alt,
#                     )
#                     if match.get('found'):
#                         personalized_advice = match['advice']
#                         matched_context     = match.get('matched_on')
#                         logger.warning(f"[SaveScan] ✅ Rule matched: rule_id={match.get('rule_id')} advice={personalized_advice[:60]}")
#                     else:
#                         logger.warning(f"[SaveScan] ❌ No rule matched for disease='{clean_label}' district='{gps_district}'")
#                 except Exception:
#                     pass

#                 if dosage_calc:
#                     personalized_dosage = {
#                         'product':       res_pesticide,
#                         'amount':        dosage_calc.get('product_display'),
#                         'water':         dosage_calc.get('water_display'),
#                         'unit':          dosage_calc.get('dosage_unit'),
#                         'plot_hectares': dosage_calc.get('plot_hectares'),
#                         'raw': {
#                             'product_amount': dosage_calc.get('product_amount'),
#                             'water_litres':   dosage_calc.get('water_litres'),
#                             'buckets_10l':    dosage_calc.get('buckets_10l'),
#                         },
#                     }

#             personalized_block = None
#             if wants_personalized and target_profile:
#                 personalized_block = {
#                     'advice':       personalized_advice,
#                     'dosage':       personalized_dosage,
#                     'matched_on':   matched_context,
#                     'farmer_level': user.experience_level,
#                 }

#             return Response({
#                 'status':         'success',
#                 'id':             diagnosis.DiagnosisID,
#                 'follow_up_date': follow_up_date.isoformat(),
#                 'crop_type':      crop_type,
#                 'scan_mode':      scan_mode,
#                 '_debug': {
#                     'received_scan_mode':          scan_mode,
#                     'received_profile_id':          str(profile_id),
#                     'wants_personalized':           wants_personalized,
#                     'target_profile_found':         target_profile is not None,
#                     'target_profile_id':            str(target_profile.ProfileID) if target_profile else None,
#                     'rule_match_found':             bool(personalized_advice),
#                     'personalized_advice_preview':  personalized_advice[:80] if personalized_advice else None,
#                 },
#                 'personalized':   personalized_block,
#                 'results': {
#                     'disease':    res_disease,
#                     'pesticide':  res_pesticide,
#                     'dosage':     res_dosage,
#                     'steps':      res_steps,
#                     'confidence': confidence,
#                     'treatment_dose_display': dosage_calc.get('product_display') if dosage_calc and wants_personalized else None,
#                     'water_volume_display':   dosage_calc.get('water_display')   if dosage_calc and wants_personalized else None,
#                 },
#                 'treatment_product':   res_pesticide,
#                 'personalized_advice': personalized_advice,
#             })

#         except Exception as e:
#             import traceback
#             return Response(
#                 {'error': str(e), 'detail': traceback.format_exc()},
#                 status=status.HTTP_400_BAD_REQUEST,
#             )


# # ── 7. HISTORY & REPORTS ─────────────────────────────────────────────────────

# class FarmerHistoryView(APIView):
#     permission_classes = [IsAuthenticated]

#     def get(self, request):
#         plants  = Plant.objects.filter(FarmerID=request.user).order_by('-DateCaptured')
#         history = []
#         for p in plants:
#             diag = Diagnosis.objects.filter(PlantID=p).first()
#             if diag:
#                 history.append({
#                     'plant_id': p.PlantID,
#                     'crop':     p.CropType,
#                     'image':    p.ImageFile,
#                     'disease':  diag.DiseaseName,
#                     'date':     p.DateCaptured.strftime('%d %b, %Y'),
#                 })
#         return Response(history)


# class FarmerReportsView(APIView):
#     permission_classes = [IsAuthenticated]

#     def get(self, request):
#         plants      = Plant.objects.filter(FarmerID=request.user).order_by('-DateCaptured')
#         report_data = []
#         for p in plants:
#             diag = Diagnosis.objects.filter(PlantID=p).first()
#             if diag:
#                 treat = Treatment.objects.filter(
#                     DiseaseName__iexact=diag.DiseaseName
#                 ).first()
#                 report_data.append({
#                     'FarmerID_id':      request.user.id,
#                     'ReportDate':       p.DateCaptured.isoformat(),
#                     'DiagnosisSummary': diag.DiseaseName.replace('_', ' ').upper(),
#                     'TreatmentSummary': (treat.ApplicationSteps
#                                          if treat else 'Isolate plant immediately.'),
#                     'ImageURL':         p.ImageFile,
#                 })
#         return Response(report_data)


# # ── 8. MARKET PRICES ─────────────────────────────────────────────────────────

# class MarketPricesView(APIView):
#     permission_classes = [IsAuthenticated]

#     def get(self, request):
#         district = request.query_params.get('district')
#         prices   = MarketPrice.objects.all().order_by('-date_recorded')
#         if district:
#             prices = prices.filter(district__iexact=district)
#         return Response([{
#             'id':             p.PriceID,
#             'vegetable_name': p.vegetable_name,
#             'market_name':    p.market_name,
#             'district':       p.district,
#             'price_per_kg':   float(p.price_per_kg),
#             'currency':       p.currency,
#             'date_recorded':  p.date_recorded.isoformat(),
#             'price_trend':    p.price_trend,
#         } for p in prices])


# # ── 9. DIAGNOSIS FEEDBACK ────────────────────────────────────────────────────

# class DiagnosisFeedbackView(APIView):
#     permission_classes = [IsAuthenticated]

#     def patch(self, request, diagnosis_id):
#         try:
#             diag = Diagnosis.objects.get(
#                 DiagnosisID=diagnosis_id,
#                 PlantID__FarmerID=request.user,
#             )
#         except Diagnosis.DoesNotExist:
#             return Response({'error': 'Diagnosis not found'}, status=404)

#         for field in ('farmer_feedback', 'severity', 'treatment_applied', 'treatment_outcome'):
#             val = request.data.get(field)
#             if val is not None:
#                 setattr(diag, field, val)
#         diag.save()

#         return Response({
#             'status':  'success',
#             'message': 'Feedback recorded. Thank you!',
#             'id':      diag.DiagnosisID,
#         })


# # ── 10. FARMER INSIGHTS ──────────────────────────────────────────────────────

# class FarmerInsightView(APIView):
#     permission_classes = [IsAuthenticated]

#     def get(self, request):
#         from django.db.models import Count
#         insight, _ = FarmerInsight.objects.get_or_create(FarmerID=request.user)

#         plants      = Plant.objects.filter(FarmerID=request.user)
#         total_scans = plants.count()
#         diagnoses   = Diagnosis.objects.filter(PlantID__in=plants)
#         healthy     = diagnoses.filter(DiseaseName__iexact='healthy').count()

#         top = (diagnoses
#                .exclude(DiseaseName__iexact='healthy')
#                .values('DiseaseName')
#                .annotate(c=Count('DiseaseName'))
#                .order_by('-c')
#                .first())

#         top_crop = (plants
#                     .exclude(CropType='Vegetable')
#                     .values('CropType')
#                     .annotate(c=Count('CropType'))
#                     .order_by('-c')
#                     .first())

#         insight.total_scans             = total_scans
#         insight.total_diseases_detected = total_scans - healthy
#         insight.total_healthy_scans     = healthy
#         insight.most_common_disease     = top['DiseaseName']   if top      else None
#         insight.most_scanned_crop       = top_crop['CropType'] if top_crop else None
#         insight.save()

#         return Response({
#             'total_scans':             insight.total_scans,
#             'total_diseases_detected': insight.total_diseases_detected,
#             'total_healthy_scans':     insight.total_healthy_scans,
#             'most_common_disease':     insight.most_common_disease,
#             'most_scanned_crop':       insight.most_scanned_crop,
#             'streak_healthy_days':     insight.streak_healthy_days,
#             'last_updated':            insight.last_updated.isoformat(),
#         })


# # ── 11. GROWTH JOURNAL ───────────────────────────────────────────────────────

# class GrowthJournalView(APIView):
#     permission_classes = [IsAuthenticated]

#     def get(self, request):
#         profile_id = request.query_params.get('crop_profile_id')
#         entries    = GrowthJournalEntry.objects.filter(FarmerID=request.user)
#         if profile_id:
#             entries = entries.filter(CropProfile__ProfileID=profile_id)
#         return Response([{
#             'id':              e.EntryID,
#             'crop_profile_id': e.CropProfile.ProfileID,
#             'crop_name':       e.CropProfile.VegetableType,
#             'entry_date':      e.entry_date.isoformat(),
#             'title':           e.title,
#             'body':            e.body,
#             'mood':            e.mood,
#             'photo_url':       e.photo_url,
#             'created_at':      e.DateCreated.isoformat(),
#         } for e in entries])

#     def post(self, request):
#         try:
#             profile = CropProfile.objects.get(
#                 ProfileID=request.data.get('crop_profile_id'),
#                 FarmerID=request.user,
#             )
#         except CropProfile.DoesNotExist:
#             return Response({'error': 'Crop profile not found'}, status=404)

#         entry = GrowthJournalEntry.objects.create(
#             FarmerID    = request.user,
#             CropProfile = profile,
#             title       = request.data.get('title', ''),
#             body        = request.data.get('body', ''),
#             mood        = request.data.get('mood', 'ok'),
#             photo_url   = request.data.get('photo_url'),
#             entry_date  = request.data.get('entry_date', date.today()),
#         )
#         return Response({'status': 'success', 'id': entry.EntryID}, status=201)

#     def delete(self, request, entry_id=None):
#         if entry_id is None:
#             return Response({'error': 'entry_id required'}, status=400)
#         try:
#             entry = GrowthJournalEntry.objects.get(
#                 EntryID=entry_id, FarmerID=request.user,
#             )
#             entry.delete()
#             return Response({'status': 'deleted'})
#         except GrowthJournalEntry.DoesNotExist:
#             return Response({'error': 'Entry not found'}, status=404)


# # ── 12. COMMUNITY ────────────────────────────────────────────────────────────

# @api_view(['GET'])
# @permission_classes([IsAuthenticated])
# def get_community_posts(request):
#     """GET /api/community/posts/ - Get paginated community posts"""
#     try:
#         page = int(request.query_params.get('page', 1))
#         limit = int(request.query_params.get('limit', 20))
#         crop_type = request.query_params.get('crop_type')
        
#         queryset = CommunityPost.objects.select_related('farmer').all()
        
#         if crop_type:
#             queryset = queryset.filter(crop_type__iexact=crop_type)
        
#         total_posts = queryset.count()
#         total_pages = (total_posts + limit - 1) // limit
#         offset = (page - 1) * limit
        
#         posts = queryset[offset:offset + limit]
        
#         user = request.user
#         liked_post_ids = set(PostLike.objects.filter(
#             farmer=user, post__in=posts
#         ).values_list('post_id', flat=True))
        
#         data = []
#         for post in posts:
#             data.append({
#                 'id': post.id,
#                 'userId': post.farmer.id,
#                 'username': post.farmer.username,
#                 'userPhotoUrl': post.farmer.profile_photo_url,
#                 'content': post.content,
#                 'imageUrl': post.image_url,
#                 'likes': post.likes_count,
#                 'commentsCount': post.comments_count,
#                 'isLikedByUser': post.id in liked_post_ids,
#                 'createdAt': post.created_at.isoformat(),
#                 'postType': post.post_type,
#                 'cropType': post.crop_type,
#             })
        
#         return Response({
#             'posts': data,
#             'page': page,
#             'limit': limit,
#             'totalPages': total_pages,
#             'totalPosts': total_posts,
#         })
#     except Exception as e:
#         return Response({'error': str(e)}, status=500)


# @api_view(['POST'])
# @permission_classes([IsAuthenticated])
# def create_community_post(request):
#     """POST /api/community/posts/ - Create a new post"""
#     try:
#         content = request.data.get('content')
#         if not content:
#             return Response({'error': 'Content is required'}, status=400)
        
#         post = CommunityPost.objects.create(
#             farmer=request.user,
#             content=content,
#             image_url=request.data.get('imageUrl'),
#             post_type=request.data.get('post_type', 'general'),
#             crop_type=request.data.get('crop_type'),
#         )
        
#         return Response({
#             'id': post.id,
#             'userId': post.farmer.id,
#             'username': post.farmer.username,
#             'userPhotoUrl': post.farmer.profile_photo_url,
#             'content': post.content,
#             'imageUrl': post.image_url,
#             'likes': 0,
#             'commentsCount': 0,
#             'isLikedByUser': False,
#             'createdAt': post.created_at.isoformat(),
#             'postType': post.post_type,
#             'cropType': post.crop_type,
#         }, status=201)
#     except Exception as e:
#         return Response({'error': str(e)}, status=500)


# @api_view(['POST'])
# @permission_classes([IsAuthenticated])
# def like_community_post(request, post_id):
#     """POST /api/community/posts/{id}/like/ - Like or unlike a post"""
#     try:
#         post = CommunityPost.objects.get(id=post_id)
#         like, created = PostLike.objects.get_or_create(post=post, farmer=request.user)
        
#         if not created:
#             like.delete()
#             post.likes_count = post.likes.count()
#             post.save()
#             return Response({'liked': False, 'likes_count': post.likes_count})
        
#         post.likes_count = post.likes.count()
#         post.save()
#         return Response({'liked': True, 'likes_count': post.likes_count})
#     except CommunityPost.DoesNotExist:
#         return Response({'error': 'Post not found'}, status=404)
#     except Exception as e:
#         return Response({'error': str(e)}, status=500)


# @api_view(['DELETE'])
# @permission_classes([IsAuthenticated])
# def delete_community_post(request, post_id):
#     """DELETE /api/community/posts/{id}/ - Delete a post (owner only)"""
#     try:
#         post = CommunityPost.objects.get(id=post_id, farmer=request.user)
#         post.delete()
#         return Response(status=204)
#     except CommunityPost.DoesNotExist:
#         return Response({'error': 'Post not found'}, status=404)
#     except Exception as e:
#         return Response({'error': str(e)}, status=500)


# @api_view(['GET'])
# @permission_classes([IsAuthenticated])
# def get_community_comments(request, post_id):
#     """GET /api/community/posts/{id}/comments/ - Get all comments for a post"""
#     try:
#         post = CommunityPost.objects.get(id=post_id)
#         comments = post.comments.select_related('farmer')
        
#         data = []
#         for comment in comments:
#             data.append({
#                 'id': comment.id,
#                 'postId': comment.post.id,
#                 'userId': comment.farmer.id,
#                 'username': comment.farmer.username,
#                 'userPhotoUrl': comment.farmer.profile_photo_url,
#                 'content': comment.content,
#                 'likes': 0,
#                 'createdAt': comment.created_at.isoformat(),
#             })
#         return Response(data)
#     except CommunityPost.DoesNotExist:
#         return Response({'error': 'Post not found'}, status=404)
#     except Exception as e:
#         return Response({'error': str(e)}, status=500)


# @api_view(['POST'])
# @permission_classes([IsAuthenticated])
# def add_community_comment(request, post_id):
#     """POST /api/community/posts/{id}/comments/ - Add a comment to a post"""
#     try:
#         post = CommunityPost.objects.get(id=post_id)
#         content = request.data.get('content')
        
#         if not content:
#             return Response({'error': 'Content is required'}, status=400)
        
#         comment = CommunityComment.objects.create(
#             post=post,
#             farmer=request.user,
#             content=content
#         )
        
#         post.comments_count = post.comments.count()
#         post.save()
        
#         return Response({
#             'id': comment.id,
#             'postId': comment.post.id,
#             'userId': comment.farmer.id,
#             'username': comment.farmer.username,
#             'userPhotoUrl': comment.farmer.profile_photo_url,
#             'content': comment.content,
#             'likes': 0,
#             'createdAt': comment.created_at.isoformat(),
#         }, status=201)
#     except CommunityPost.DoesNotExist:
#         return Response({'error': 'Post not found'}, status=404)
#     except Exception as e:
#         return Response({'error': str(e)}, status=500)


# @api_view(['GET'])
# @permission_classes([IsAuthenticated])
# def get_community_profile(request):
#     """GET /api/community/profile/ - Get current user's profile for community"""
#     try:
#         farmer = request.user
#         return Response({
#             'id': farmer.id,
#             'username': farmer.username,
#             'first_name': farmer.first_name,
#             'last_name': farmer.last_name,
#             'email': farmer.email,
#             'district': farmer.district,
#             'profile_photo_url': farmer.profile_photo_url,
#             'experience_level': farmer.experience_level,
#         })
#     except Exception as e:
#         return Response({'error': str(e)}, status=500)



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
    RuleMatchingService, CommunityPost, PostLike, CommunityComment,
)
from .serializers import CropProfileSerializer, AppAlertSerializer, WeatherDataSerializer


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
        raw_password = data.get('password', '')
        try:
            validate_password(raw_password)
        except DjangoValidationError as exc:
            return Response(
                {
                    'error':   'Password is too weak.',
                    'details': list(exc.messages),
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
        send_activation_email(request, user)
        return Response({
            'status':  'success',
            'message': 'Verification email sent.',
            'email':   user.email,
        }, status=status.HTTP_201_CREATED)

    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


def send_activation_email(request, user):
    current_site    = get_current_site(request)
    uid             = urlsafe_base64_encode(force_bytes(user.pk))
    token           = default_token_generator.make_token(user)
    activation_link = f"http://{current_site.domain}/api/activate/{uid}/{token}/"
    EmailMessage(
        'Activate your FarmAid Lesotho Account',
        f"Dumela {user.first_name},\n\nPlease click link to verify: {activation_link}",
        to=[user.email],
    ).send()


@api_view(['POST'])
@permission_classes([AllowAny])
def resend_activation_email(request):
    try:
        user = Farmer.objects.get(email=request.data.get('email'))
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
    Token.objects.filter(user=user).delete()
    new_token, _ = Token.objects.get_or_create(user=user)
    return Response({
        'status':  'success',
        'message': 'Password updated!',
        'token':   new_token.key,
    })


# ── 2. GOOGLE SIGN-IN ─────────────────────────────────────────────────────────

@api_view(['POST'])
@permission_classes([AllowAny])
def google_auth(request):
    from django.conf import settings as django_settings

    id_token_str = request.data.get('id_token', '').strip()
    if not id_token_str:
        return Response({'error': 'id_token is required.'}, status=400)

    try:
        from google.oauth2 import id_token as google_id_token
        from google.auth.transport import requests as google_requests

        client_id = getattr(django_settings, 'GOOGLE_CLIENT_ID', '')
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

    user, created = Farmer.objects.get_or_create(
        email=email,
        defaults={
            'username':   email,
            'first_name': first_name,
            'last_name':  last_name,
            'is_active':  True,
        },
    )

    if created:
        user.set_unusable_password()
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
        'created':    created,
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
            'farm_size_hectares':   u.farm_size_hectares if hasattr(u, 'farm_size_hectares') else None,
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
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user      = request.user
        user_dist = (user.district or '').strip()
        now       = timezone.now()

        qs = AppAlert.objects.filter(
            Q(FarmerID=user)
            | Q(district_target__iexact=user_dist)
        ).exclude(
            expires_at__lt=now
        ).order_by('-DateCreated')

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


# ── 6. AI SCAN & SAVE ────────────────────────────────────────────────────────

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
                    'treatment_dose_display': dosage_calc.get('product_display') if dosage_calc and wants_personalized else None,
                    'water_volume_display':   dosage_calc.get('water_display') if dosage_calc and wants_personalized else None,
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


# ── 7. HISTORY & REPORTS ─────────────────────────────────────────────────────

class FarmerHistoryView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        plants  = Plant.objects.filter(FarmerID=request.user).order_by('-DateCaptured')
        history = []
        for p in plants:
            diag = Diagnosis.objects.filter(PlantID=p).first()
            if diag:
                history.append({
                    'plant_id': p.PlantID,
                    'crop':     p.CropType,
                    'image':    p.ImageFile,
                    'disease':  diag.DiseaseName,
                    'date':     p.DateCaptured.strftime('%d %b, %Y'),
                })
        return Response(history)


class FarmerReportsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        plants      = Plant.objects.filter(FarmerID=request.user).order_by('-DateCaptured')
        report_data = []
        for p in plants:
            diag = Diagnosis.objects.filter(PlantID=p).first()
            if diag:
                treat = Treatment.objects.filter(
                    DiseaseName__iexact=diag.DiseaseName
                ).first()
                report_data.append({
                    'FarmerID_id':      request.user.id,
                    'ReportDate':       p.DateCaptured.isoformat(),
                    'DiagnosisSummary': diag.DiseaseName.replace('_', ' ').upper(),
                    'TreatmentSummary': (treat.ApplicationSteps
                                         if treat else 'Isolate plant immediately.'),
                    'ImageURL':         p.ImageFile,
                })
        return Response(report_data)


# ── 8. MARKET PRICES ─────────────────────────────────────────────────────────

class MarketPricesView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        district = request.query_params.get('district')
        prices   = MarketPrice.objects.all().order_by('-date_recorded')
        if district:
            prices = prices.filter(district__iexact=district)
        return Response([{
            'id':             p.PriceID,
            'vegetable_name': p.vegetable_name,
            'market_name':    p.market_name,
            'district':       p.district,
            'price_per_kg':   float(p.price_per_kg),
            'currency':       p.currency,
            'date_recorded':  p.date_recorded.isoformat(),
            'price_trend':    p.price_trend,
        } for p in prices])


# ── 9. DIAGNOSIS FEEDBACK ────────────────────────────────────────────────────

class DiagnosisFeedbackView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, diagnosis_id):
        try:
            diag = Diagnosis.objects.get(
                DiagnosisID=diagnosis_id,
                PlantID__FarmerID=request.user,
            )
        except Diagnosis.DoesNotExist:
            return Response({'error': 'Diagnosis not found'}, status=404)

        for field in ('farmer_feedback', 'severity', 'treatment_applied', 'treatment_outcome'):
            val = request.data.get(field)
            if val is not None:
                setattr(diag, field, val)
        diag.save()

        return Response({
            'status':  'success',
            'message': 'Feedback recorded. Thank you!',
            'id':      diag.DiagnosisID,
        })


# ── 10. FARMER INSIGHTS ──────────────────────────────────────────────────────

class FarmerInsightView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        from django.db.models import Count
        insight, _ = FarmerInsight.objects.get_or_create(FarmerID=request.user)

        plants      = Plant.objects.filter(FarmerID=request.user)
        total_scans = plants.count()
        diagnoses   = Diagnosis.objects.filter(PlantID__in=plants)
        healthy     = diagnoses.filter(DiseaseName__iexact='healthy').count()

        top = (diagnoses
               .exclude(DiseaseName__iexact='healthy')
               .values('DiseaseName')
               .annotate(c=Count('DiseaseName'))
               .order_by('-c')
               .first())

        top_crop = (plants
                    .exclude(CropType='Vegetable')
                    .values('CropType')
                    .annotate(c=Count('CropType'))
                    .order_by('-c')
                    .first())

        insight.total_scans             = total_scans
        insight.total_diseases_detected = total_scans - healthy
        insight.total_healthy_scans     = healthy
        insight.most_common_disease     = top['DiseaseName'] if top else None
        insight.most_scanned_crop       = top_crop['CropType'] if top_crop else None
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


# ── 11. GROWTH JOURNAL ───────────────────────────────────────────────────────

class GrowthJournalView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        profile_id = request.query_params.get('crop_profile_id')
        entries    = GrowthJournalEntry.objects.filter(FarmerID=request.user)
        if profile_id:
            entries = entries.filter(CropProfile__ProfileID=profile_id)
        return Response([{
            'id':              e.EntryID,
            'crop_profile_id': e.CropProfile.ProfileID,
            'crop_name':       e.CropProfile.VegetableType,
            'entry_date':      e.entry_date.isoformat(),
            'title':           e.title,
            'body':            e.body,
            'mood':            e.mood,
            'photo_url':       e.photo_url,
            'created_at':      e.DateCreated.isoformat(),
        } for e in entries])

    def post(self, request):
        try:
            profile = CropProfile.objects.get(
                ProfileID=request.data.get('crop_profile_id'),
                FarmerID=request.user,
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
        return Response({'status': 'success', 'id': entry.EntryID}, status=201)

    def delete(self, request, entry_id=None):
        if entry_id is None:
            return Response({'error': 'entry_id required'}, status=400)
        try:
            entry = GrowthJournalEntry.objects.get(
                EntryID=entry_id, FarmerID=request.user,
            )
            entry.delete()
            return Response({'status': 'deleted'})
        except GrowthJournalEntry.DoesNotExist:
            return Response({'error': 'Entry not found'}, status=404)


# ── 12. COMMUNITY ────────────────────────────────────────────────────────────

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_community_posts(request):
    """GET /api/community/posts/ - Get paginated community posts"""
    try:
        page = int(request.query_params.get('page', 1))
        limit = int(request.query_params.get('limit', 20))
        crop_type = request.query_params.get('crop_type')
        
        queryset = CommunityPost.objects.select_related('farmer').all()
        
        if crop_type:
            queryset = queryset.filter(crop_type__iexact=crop_type)
        
        total_posts = queryset.count()
        total_pages = (total_posts + limit - 1) // limit
        offset = (page - 1) * limit
        
        posts = queryset[offset:offset + limit]
        
        user = request.user
        liked_post_ids = set(PostLike.objects.filter(
            farmer=user, post__in=posts
        ).values_list('post_id', flat=True))
        
        data = []
        for post in posts:
            data.append({
                'id': post.id,
                'userId': post.farmer.id,
                'username': post.farmer.username,
                'userPhotoUrl': post.farmer.profile_photo_url,
                'content': post.content,
                'imageUrl': post.image_url,
                'likes': post.likes_count,
                'commentsCount': post.comments_count,
                'isLikedByUser': post.id in liked_post_ids,
                'createdAt': post.created_at.isoformat(),
                'postType': post.post_type,
                'cropType': post.crop_type,
            })
        
        return Response({
            'posts': data,
            'page': page,
            'limit': limit,
            'totalPages': total_pages,
            'totalPosts': total_posts,
        })
    except Exception as e:
        return Response({'error': str(e)}, status=500)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_community_post(request):
    """POST /api/community/posts/ - Create a new post"""
    try:
        content = request.data.get('content')
        if not content:
            return Response({'error': 'Content is required'}, status=400)
        
        post = CommunityPost.objects.create(
            farmer=request.user,
            content=content,
            image_url=request.data.get('imageUrl'),
            post_type=request.data.get('post_type', 'general'),
            crop_type=request.data.get('crop_type'),
        )
        
        return Response({
            'id': post.id,
            'userId': post.farmer.id,
            'username': post.farmer.username,
            'userPhotoUrl': post.farmer.profile_photo_url,
            'content': post.content,
            'imageUrl': post.image_url,
            'likes': 0,
            'commentsCount': 0,
            'isLikedByUser': False,
            'createdAt': post.created_at.isoformat(),
            'postType': post.post_type,
            'cropType': post.crop_type,
        }, status=201)
    except Exception as e:
        return Response({'error': str(e)}, status=500)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def like_community_post(request, post_id):
    """POST /api/community/posts/{id}/like/ - Like or unlike a post"""
    try:
        post = CommunityPost.objects.get(id=post_id)
        like, created = PostLike.objects.get_or_create(post=post, farmer=request.user)
        
        if not created:
            like.delete()
            post.likes_count = post.likes.count()
            post.save()
            return Response({'liked': False, 'likes_count': post.likes_count})
        
        post.likes_count = post.likes.count()
        post.save()
        return Response({'liked': True, 'likes_count': post.likes_count})
    except CommunityPost.DoesNotExist:
        return Response({'error': 'Post not found'}, status=404)
    except Exception as e:
        return Response({'error': str(e)}, status=500)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_community_post(request, post_id):
    """
    DELETE /api/community/posts/{id}/ - Delete a post (owner only)
    Security: Only the post owner can delete their own post
    """
    try:
        # SECURITY: Ensure only the post owner can delete
        post = CommunityPost.objects.get(id=post_id, farmer=request.user)
        post.delete()
        return Response(status=204)
    except CommunityPost.DoesNotExist:
        return Response({'error': 'Post not found or you do not have permission'}, status=404)
    except Exception as e:
        return Response({'error': str(e)}, status=500)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_community_comments(request, post_id):
    """GET /api/community/posts/{id}/comments/ - Get all comments for a post"""
    try:
        post = CommunityPost.objects.get(id=post_id)
        comments = post.comments.select_related('farmer')
        
        data = []
        for comment in comments:
            data.append({
                'id': comment.id,
                'postId': comment.post.id,
                'userId': comment.farmer.id,
                'username': comment.farmer.username,
                'userPhotoUrl': comment.farmer.profile_photo_url,
                'content': comment.content,
                'likes': 0,
                'createdAt': comment.created_at.isoformat(),
            })
        return Response(data)
    except CommunityPost.DoesNotExist:
        return Response({'error': 'Post not found'}, status=404)
    except Exception as e:
        return Response({'error': str(e)}, status=500)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def add_community_comment(request, post_id):
    """POST /api/community/posts/{id}/comments/ - Add a comment to a post"""
    try:
        post = CommunityPost.objects.get(id=post_id)
        content = request.data.get('content')
        
        if not content:
            return Response({'error': 'Content is required'}, status=400)
        
        comment = CommunityComment.objects.create(
            post=post,
            farmer=request.user,
            content=content
        )
        
        post.comments_count = post.comments.count()
        post.save()
        
        return Response({
            'id': comment.id,
            'postId': comment.post.id,
            'userId': comment.farmer.id,
            'username': comment.farmer.username,
            'userPhotoUrl': comment.farmer.profile_photo_url,
            'content': comment.content,
            'likes': 0,
            'createdAt': comment.created_at.isoformat(),
        }, status=201)
    except CommunityPost.DoesNotExist:
        return Response({'error': 'Post not found'}, status=404)
    except Exception as e:
        return Response({'error': str(e)}, status=500)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_community_profile(request):
    """GET /api/community/profile/ - Get current user's profile for community"""
    try:
        farmer = request.user
        return Response({
            'id': farmer.id,
            'username': farmer.username,
            'first_name': farmer.first_name,
            'last_name': farmer.last_name,
            'email': farmer.email,
            'district': farmer.district,
            'profile_photo_url': farmer.profile_photo_url,
            'experience_level': farmer.experience_level,
        })
    except Exception as e:
        return Response({'error': str(e)}, status=500)
