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
#         if Farmer.objects.filter(email=data.get('email', '').lower()).exists():
#             return Response(
#                 {'error': 'Email already exists'},
#                 status=status.HTTP_400_BAD_REQUEST,
#             )

#         raw_password = data.get('password', '')
#         try:
#             validate_password(raw_password)
#         except DjangoValidationError as exc:
#             return Response(
#                 {
#                     'error': 'Password is too weak.',
#                     'details': list(exc.messages),
#                 },
#                 status=status.HTTP_400_BAD_REQUEST,
#             )

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
#             'status': 'success',
#             'message': 'Verification email sent.',
#             'email': user.email,
#         }, status=status.HTTP_201_CREATED)

#     except Exception as e:
#         return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# def send_activation_email(request, user):
#     current_site = get_current_site(request)
#     uid = urlsafe_base64_encode(force_bytes(user.pk))
#     token = default_token_generator.make_token(user)
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
#         uid = force_str(urlsafe_base64_decode(uidb64))
#         user = Farmer.objects.get(pk=uid)
#     except (TypeError, ValueError, OverflowError, Farmer.DoesNotExist):
#         user = None

#     if user is not None and default_token_generator.check_token(user, token):
#         user.is_active = True
#         user.save()
#         return HttpResponse("""
#         <html>
#         <head><title>Account Activated</title></head>
#         <body style="font-family: Arial, sans-serif; text-align: center; padding: 50px;">
#             <h1 style="color: green;">✅ Account Activated!</h1>
#             <p>Your FarmAid account has been successfully activated.</p>
#             <p>You can now close this window and log in to the app.</p>
#             <a href="#" onclick="window.close(); return false;" style="color: green;">Close Window</a>
#         </body>
#         </html>
#         """)
#     return HttpResponse("""
#     <html>
#     <head><title>Activation Failed</title></head>
#     <body style="font-family: Arial, sans-serif; text-align: center; padding: 50px;">
#         <h1 style="color: red;">❌ Activation Failed</h1>
#         <p>The activation link is invalid or has expired.</p>
#         <p>Please request a new activation email from the FarmAid app.</p>
#     </body>
#     </html>
#     """, status=400)


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
#             'token': token.key,
#             'farmerName': f"{user.first_name} {user.last_name}".strip(),
#             'is_staff': user.is_staff,
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
#     Token.objects.filter(user=user).delete()
#     new_token, _ = Token.objects.get_or_create(user=user)
#     return Response({
#         'status': 'success',
#         'message': 'Password updated!',
#         'token': new_token.key,
#     })


# # ── 2. GOOGLE SIGN-IN ─────────────────────────────────────────────────────────

# @api_view(['POST'])
# @permission_classes([AllowAny])
# def google_auth(request):
#     from django.conf import settings
#     import logging
    
#     logger = logging.getLogger(__name__)
    
#     id_token_str = request.data.get('id_token', '').strip()
#     if not id_token_str:
#         return Response({'error': 'id_token is required.'}, status=400)

#     try:
#         from google.oauth2 import id_token as google_id_token
#         from google.auth.transport import requests as google_requests

#         # ✅ Get client ID from settings with fallback
#         client_id = getattr(settings, 'GOOGLE_CLIENT_ID', None)
        
#         # ✅ Log the client ID being used (for debugging)
#         logger.warning(f"[GoogleAuth] Using Client ID: {client_id}")
        
#         if not client_id:
#             return Response(
#                 {'error': 'GOOGLE_CLIENT_ID not configured in settings'},
#                 status=500,
#             )
        
#         # ✅ Verify the token with the specific client ID
#         id_info = google_id_token.verify_oauth2_token(
#             id_token_str,
#             google_requests.Request(),
#             client_id,
#         )
        
#         logger.warning(f"[GoogleAuth] Token verified successfully for: {id_info.get('email')}")
        
#     except ImportError:
#         return Response(
#             {'error': 'google-auth package not installed. Run: pip install google-auth'},
#             status=500,
#         )
#     except ValueError as exc:
#         # ✅ More detailed error logging
#         error_msg = str(exc)
#         logger.error(f"[GoogleAuth] Token validation error: {error_msg}")
#         return Response({'error': f'Invalid Google token: {error_msg}'}, status=401)

#     email = id_info.get('email', '').lower()
#     first_name = id_info.get('given_name', '')
#     last_name = id_info.get('family_name', '')
#     photo_url = id_info.get('picture', '')

#     if not email:
#         return Response({'error': 'Google account has no email address.'}, status=400)

#     user, created = Farmer.objects.get_or_create(
#         email=email,
#         defaults={
#             'username': email,
#             'first_name': first_name,
#             'last_name': last_name,
#             'is_active': True,
#         },
#     )

#     if created:
#         user.set_unusable_password()
#         if photo_url:
#             user.profile_photo_url = photo_url
#         user.save()
#     elif not user.is_active:
#         user.is_active = True
#         user.save()

#     token, _ = Token.objects.get_or_create(user=user)
#     return Response({
#         'token': token.key,
#         'farmerName': f"{user.first_name} {user.last_name}".strip() or email,
#         'is_staff': user.is_staff,
#         'email': user.email,
#         'created': created,
#     })


# # ── 3. PROFILE & WEATHER ─────────────────────────────────────────────────────

# class ProfileView(APIView):
#     permission_classes = [IsAuthenticated]

#     def get(self, request):
#         u = request.user
#         return Response({
#             'first_name': u.first_name,
#             'last_name': u.last_name,
#             'email': u.email,
#             'district': u.district,
#             'phone_number': u.phone_number,
#             'language_preferences': u.language_preferences,
#             'experience_level': u.experience_level,
#             'profile_photo_url': u.profile_photo_url,
#             'farm_size_hectares': u.farm_size_hectares if hasattr(u, 'farm_size_hectares') else None,
#             'onboarding_complete': u.onboarding_complete if hasattr(u, 'onboarding_complete') else False,
#         })

#     def patch(self, request):
#         user = request.user
#         for attr, value in request.data.items():
#             if hasattr(user, attr):
#                 setattr(user, attr, value)
#         user.save()
#         return Response({
#             'status': 'success',
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
#     permission_classes = [IsAuthenticated]

#     def get(self, request):
#         user = request.user
#         user_dist = (user.district or '').strip()
#         now = timezone.now()

#         qs = AppAlert.objects.filter(
#             Q(FarmerID=user)
#             | Q(district_target__iexact=user_dist)
#         ).exclude(
#             expires_at__lt=now
#         ).order_by('-DateCreated')

#         alert_type = request.query_params.get('type')
#         if alert_type:
#             qs = qs.filter(alert_type=alert_type)

#         return Response({
#             'count': qs.count(),
#             'unread_count': qs.filter(IsRead=False).count(),
#             'alerts': AppAlertSerializer(qs, many=True).data,
#         })

#     def post(self, request):
#         updated = AppAlert.objects.filter(
#             FarmerID=request.user, IsRead=False
#         ).update(IsRead=True)
#         return Response({'status': 'success', 'marked_read': updated})


# class AlertCountView(APIView):
#     permission_classes = [IsAuthenticated]

#     def get(self, request):
#         now = timezone.now()
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
#         """Get Sesotho translation from cache"""
#         if not disease_name:
#             return None
#         try:
#             cache = TranslationCache.objects.get(disease_name_en__iexact=disease_name)
#             translations = {
#                 'pesticide': cache.pesticide_st,
#                 'dosage': cache.dosage_st,
#                 'steps': cache.steps_st,
#             }
#             result = translations.get(field)
            
#             import logging
#             logger = logging.getLogger(__name__)
#             if result:
#                 logger.warning(f"[Sesotho] ✓ Found '{field}' for '{disease_name}': {result[:100]}...")
#             else:
#                 logger.warning(f"[Sesotho] ✗ No '{field}' found for '{disease_name}'")
            
#             return result
#         except TranslationCache.DoesNotExist:
#             import logging
#             logger = logging.getLogger(__name__)
#             logger.warning(f"[Sesotho] ✗ No translation cache entry for '{disease_name}'")
#             return None
#         except Exception as e:
#             import logging
#             logger = logging.getLogger(__name__)
#             logger.warning(f"[Sesotho] Error: {e}")
#             return None

#     def _get_highland_temp(self, altitude):
#         """Estimate temperature based on altitude in Lesotho"""
#         base_temp = 22
#         temp = base_temp - (altitude / 100 * 0.65)
#         return int(temp)

#     def _generate_personalized_advice(self, disease_name, farmer, crop_profile, gps_district, gps_lat, gps_lon, gps_alt):
#         """Generate personalized advice in English USING GPS coordinates"""
        
#         # Get farmer's data
#         experience_level = farmer.experience_level
#         district = gps_district or farmer.district or 'your area'
        
#         # Get crop profile data
#         crop_type = crop_profile.VegetableType if crop_profile else 'your crop'
#         soil_type = crop_profile.SoilEnvironment or 'your soil type'
#         irrigation = crop_profile.irrigation_method or 'your irrigation method'
#         planting_date = crop_profile.PlantingDate
#         plot_size = crop_profile.plot_size_hectares
        
#         # Calculate days since planting and growth stage
#         days_since_planting = 0
#         growth_stage = "Unknown"
#         if planting_date:
#             days_since_planting = (date.today() - planting_date).days
#             if days_since_planting < 14:
#                 growth_stage = "seedling"
#             elif days_since_planting < 45:
#                 growth_stage = "vegetative"
#             elif days_since_planting < 75:
#                 growth_stage = "flowering"
#             else:
#                 growth_stage = "fruiting/harvest"
        
#         # Determine altitude tier using GPS altitude
#         altitude_tier = "lowland"
#         altitude_display = None
#         if gps_alt is not None:
#             altitude_display = f"{int(gps_alt)}m"
#             if gps_alt < 1800:
#                 altitude_tier = "lowland"
#             elif gps_alt < 2200:
#                 altitude_tier = "midland"
#             elif gps_alt < 2800:
#                 altitude_tier = "highland"
#             else:
#                 altitude_tier = "alpine"
        
#         # Determine current season
#         current_month = date.today().month
#         if 5 <= current_month <= 9:
#             season = "dry"
#             season_advice = "During this dry season, fungal diseases spread less. Focus on proper irrigation and soil moisture management."
#         else:
#             season = "wet"
#             season_advice = "During this wet season, fungal diseases spread rapidly. Apply preventive fungicides and ensure good drainage."
        
#         # Lesotho-specific climate zones based on latitude/longitude
#         is_western = False
#         is_eastern = False
#         is_northern = False
#         is_southern = False
        
#         if gps_lat and gps_lon:
#             if gps_lon < 27.5:
#                 is_western = True
#             elif gps_lon > 28.5:
#                 is_eastern = True
            
#             if gps_lat > -29.0:
#                 is_northern = True
#             elif gps_lat < -30.0:
#                 is_southern = True
        
#         # Build personalized advice based on GPS and farmer's data
#         advice_parts = []
        
#         # 1. LOCATION-SPECIFIC OPENING
#         location_context = []
#         if gps_lat and gps_lon:
#             location_context.append(f"Your farm at coordinates {gps_lat:.4f}°S, {gps_lon:.4f}°E")
#             if altitude_display:
#                 location_context.append(f"at {altitude_display} elevation")
#             location_context.append(f"in {district} district")
#         else:
#             location_context.append(f"Your farm in {district} district")
        
#         advice_parts.append(f"{' '.join(location_context)} faces specific conditions for {disease_name.replace('_', ' ')}.")
        
#         # 2. ALTITUDE-BASED RECOMMENDATIONS
#         if gps_alt:
#             if altitude_tier == 'highland':
#                 temp = self._get_highland_temp(gps_alt)
#                 advice_parts.append(f"At {int(gps_alt)}m elevation, nights are cold ({temp}°C). This slows down pathogen development but also slows plant growth. Apply treatments early morning when temperatures rise above 10°C.")
                
#                 if 'blight' in disease_name.lower():
#                     advice_parts.append(f"Highland conditions favor late blight development. Increase copper spray frequency to every 5 days during wet periods.")
#                 elif 'mildew' in disease_name.lower():
#                     advice_parts.append(f"Highland humidity promotes powdery mildew. Ensure good air circulation by spacing plants wider (add 10-15cm to standard spacing).")
                    
#             elif altitude_tier == 'midland':
#                 advice_parts.append(f"Your midland altitude ({int(gps_alt)}m) provides good growing conditions. Standard treatment intervals work well here.")
                
#             elif altitude_tier == 'lowland':
#                 advice_parts.append(f"At {int(gps_alt)}m elevation, warmer temperatures accelerate disease spread. Reduce treatment intervals by 20-30% compared to highland recommendations.")
        
#         # 3. REGIONAL CLIMATE RECOMMENDATIONS
#         if is_western:
#             advice_parts.append("Western Lesotho (your area) receives less rainfall (600-800mm annually). During dry spells, focus on soil moisture conservation. Use mulch to retain soil moisture and reduce plant stress.")
#             if 'blight' in disease_name.lower():
#                 advice_parts.append("Despite lower rainfall in western Lesotho, morning dew can still promote blight. Apply fungicides early morning before dew forms.")
                
#         elif is_eastern:
#             advice_parts.append("Eastern Lesotho (your area) receives high rainfall (1000-1500mm annually). This high humidity creates perfect conditions for fungal diseases. Increase fungicide frequency and ensure excellent drainage.")
#             if 'mildew' in disease_name.lower():
#                 advice_parts.append("Your high-rainfall area is a hotspot for powdery mildew. Consider using systemic fungicides and improve air circulation through proper pruning.")
                
#         if is_northern:
#             advice_parts.append("Northern Lesotho (your area) has warmer temperatures, which can accelerate disease cycles. Monitor crops daily during peak growing season.")
#         elif is_southern:
#             advice_parts.append("Southern Lesotho (your area) experiences cooler temperatures. Diseases develop slower, but frost damage can weaken plants making them susceptible.")
        
#         # 4. SEASON-SPECIFIC ADVICE
#         advice_parts.append(season_advice)
        
#         # 5. DISEASE-SPECIFIC TREATMENT
#         disease_lower = disease_name.lower()
        
#         if 'blight' in disease_lower:
#             if altitude_tier == 'highland':
#                 advice_parts.append(f"BLIGHT TREATMENT for highlands: Apply copper hydroxide (250g/100L) every 5-7 days. In Mokhotlong/Thaba-Tseka highlands, late blight is the #1 potato disease.")
#             elif is_eastern:
#                 advice_parts.append(f"BLIGHT TREATMENT for eastern Lesotho: Due to your high rainfall area ({gps_lon:.1f}°E), apply metalaxyl-based fungicides preventively every 7 days during rainy season.")
#             else:
#                 advice_parts.append(f"BLIGHT TREATMENT: Apply copper-based fungicide every 7-10 days. Remove infected leaves immediately and destroy them away from your field.")
                
#         elif 'mildew' in disease_lower:
#             if is_eastern or altitude_tier == 'highland':
#                 advice_parts.append(f"MILDEW TREATMENT for your high-humidity location: Apply sulfur (200g/100L) weekly. Your area's morning fog creates ideal mildew conditions.")
#             else:
#                 advice_parts.append(f"MILDEW TREATMENT: Apply neem oil or sulfur weekly. Water plants at base, not overhead, to reduce leaf wetness.")
                
#         elif 'rust' in disease_lower:
#             if is_western:
#                 advice_parts.append(f"RUST TREATMENT for western Lesotho: Your drier conditions actually favor rust development. Apply azoxystrobin (100ml/100L) at first sign.")
#             else:
#                 advice_parts.append(f"RUST TREATMENT: Remove affected leaves. Apply fungicide containing azoxystrobin or tebuconazole.")
                
#         elif 'aphid' in disease_lower:
#             advice_parts.append(f"APHID CONTROL: Based on your location, release ladybugs (available from Lesotho Agricultural Supply) or spray neem oil (30ml/10L). Aphids thrive in Lesotho's spring (September-October).")
            
#         elif 'rot' in disease_lower:
#             if is_eastern:
#                 advice_parts.append(f"ROT TREATMENT for eastern Lesotho: Your high rainfall area requires raised beds (30cm high) for drainage. Apply copper-based fungicide as soil drench.")
#             else:
#                 advice_parts.append(f"ROT TREATMENT: Improve drainage immediately. Reduce watering. Apply copper-based fungicide.")
        
#         elif 'virus' in disease_lower:
#             advice_parts.append(f"VIRUS MANAGEMENT: Viruses have no cure. Remove infected plants immediately from {district}. Control insect vectors and use virus-free seeds. In Lesotho, tomato spotted wilt virus is common in lowlands.")
        
#         elif 'healthy' in disease_lower:
#             advice_parts.append(f"✅ Your {crop_type} appears healthy. Continue good agricultural practices in {district}.")
        
#         else:
#             advice_parts.append(f"For {disease_name} in {district}, consult your local agricultural extension officer for specific treatment.")
        
#         # 6. SOIL-SPECIFIC ADVICE
#         if soil_type and soil_type != 'your soil type':
#             if 'clay' in soil_type.lower():
#                 advice_parts.append(f"Your {soil_type} soil in {district} needs raised beds for better drainage. Add river sand and compost to improve soil structure.")
#             elif 'sandy' in soil_type.lower():
#                 advice_parts.append(f"Your {soil_type} soil in {district} drains quickly. Add compost to retain moisture. In dry areas like western Lesotho, this is especially important.")
#             elif 'loam' in soil_type.lower():
#                 advice_parts.append(f"Your {soil_type} soil is ideal for {crop_type} in {district} conditions.")
        
#         # 7. IRRIGATION ADVICE
#         if irrigation and irrigation != 'your irrigation method':
#             if irrigation.lower() == 'drip':
#                 if is_western:
#                     advice_parts.append("Your drip irrigation is excellent for western Lesotho's drier conditions. Water early morning (6-8 AM) to minimize evaporation.")
#                 else:
#                     advice_parts.append("Your drip irrigation is ideal. Water early morning to allow leaves to dry.")
#             elif irrigation.lower() == 'overhead' or irrigation.lower() == 'sprinkler':
#                 if is_eastern or altitude_tier == 'highland':
#                     advice_parts.append("⚠️ In your high-rainfall/high-humidity area, overhead watering spreads diseases. Switch to drip irrigation or water only at soil level.")
#                 else:
#                     advice_parts.append("Switch to drip irrigation if possible. Overhead watering spreads many fungal diseases.")
        
#         # 8. GROWTH STAGE ADVICE
#         if growth_stage != "Unknown":
#             if growth_stage == "seedling":
#                 advice_parts.append(f"Your {crop_type} is in seedling stage. Young plants in {district} are vulnerable. Monitor daily for disease spread.")
#             elif growth_stage == "flowering":
#                 advice_parts.append(f"Your {crop_type} is flowering. Avoid spraying during peak flowering (9 AM - 3 PM) to protect bees. Spray early morning or late evening.")
#             elif growth_stage == "fruiting/harvest":
#                 advice_parts.append(f"Your {crop_type} is in fruiting stage. Follow pre-harvest interval on all pesticides - check label for days to wait after spraying before harvest.")
        
#         # 9. FARMER EXPERIENCE LEVEL
#         if experience_level == 'beginner':
#             advice_parts.append("👨‍🌾 Beginner tip: Start with a small test area first. Always wear gloves, mask, and protective clothing when spraying. Read all pesticide labels carefully.")
#         elif experience_level == 'expert':
#             advice_parts.append("🔬 Expert recommendation: Rotate between different fungicide groups (FRAC codes) to prevent resistance development.")
        
#         # 10. LOCAL RESOURCE RECOMMENDATIONS
#         if district and district != 'your area':
#             advice_parts.append(f"📍 Local resources in {district}: Contact your nearest agricultural extension officer for site-specific advice and free soil testing.")
        
#         # 11. DOSAGE CALCULATION
#         if plot_size and plot_size > 0:
#             water_liters = int(plot_size * 200)
#             buckets = int(water_liters / 10)
#             advice_parts.append(f"📐 For your {plot_size} hectare plot, mix the recommended product with {water_liters}L water (approx. {buckets} buckets of 10L).")
        
#         # Combine all advice with double newlines for paragraph separation
#         personalized_advice = "\n\n".join(advice_parts)
        
#         return {
#             'advice': personalized_advice,
#             'matched_on': {
#                 'district': district,
#                 'latitude': gps_lat,
#                 'longitude': gps_lon,
#                 'altitude_tier': altitude_tier,
#                 'altitude_m': gps_alt,
#                 'soil': soil_type,
#                 'irrigation': irrigation,
#                 'growth_stage': growth_stage,
#                 'season': season,
#                 'days_since_planting': days_since_planting,
#                 'region': 'western' if is_western else 'eastern' if is_eastern else 'central',
#             },
#             'farmer_level': experience_level,
#         }

#     def _generate_personalized_advice_sesotho(self, disease_name, farmer, crop_profile, gps_district, gps_lat, gps_lon, gps_alt):
#         """Generate personalized advice in Sesotho USING GPS coordinates"""
        
#         # Get farmer's data
#         experience_level = farmer.experience_level
#         district = gps_district or farmer.district or 'sebaka sa heno'
        
#         # Get crop profile data
#         crop_type = crop_profile.VegetableType if crop_profile else 'sejalo sa heno'
#         soil_type = crop_profile.SoilEnvironment or 'mobu oa heno'
#         irrigation = crop_profile.irrigation_method or 'mokhoa oa heno oa nosetso'
#         planting_date = crop_profile.PlantingDate
#         plot_size = crop_profile.plot_size_hectares
        
#         # Calculate days since planting and growth stage
#         days_since_planting = 0
#         growth_stage = "Unknown"
#         if planting_date:
#             days_since_planting = (date.today() - planting_date).days
#             if days_since_planting < 14:
#                 growth_stage = "seedling"
#             elif days_since_planting < 45:
#                 growth_stage = "vegetative"
#             elif days_since_planting < 75:
#                 growth_stage = "flowering"
#             else:
#                 growth_stage = "fruiting/harvest"
        
#         # Determine altitude tier using GPS altitude
#         altitude_tier = "lowland"
#         altitude_display = None
#         if gps_alt is not None:
#             altitude_display = f"{int(gps_alt)}m"
#             if gps_alt < 1800:
#                 altitude_tier = "lowland"
#             elif gps_alt < 2200:
#                 altitude_tier = "midland"
#             elif gps_alt < 2800:
#                 altitude_tier = "highland"
#             else:
#                 altitude_tier = "alpine"
        
#         # Determine current season
#         current_month = date.today().month
#         if 5 <= current_month <= 9:
#             season = "dry"
#             season_advice = "Nakong ena ea komello, mafu a fungal ha a hlaselle haholo. Tsepamisa mohopolo nosetsong e nepahetseng le taolong ea mongobo oa mobu."
#         else:
#             season = "wet"
#             season_advice = "Nakong ena ea lipula, mafu a fungal a hasana ka potlako. Sebelisa meriana ea thibelo 'me u netefatse hore metsi a phalla hantle."
        
#         # Lesotho-specific climate zones based on latitude/longitude
#         is_western = False
#         is_eastern = False
#         is_northern = False
#         is_southern = False
        
#         if gps_lat and gps_lon:
#             if gps_lon < 27.5:
#                 is_western = True
#             elif gps_lon > 28.5:
#                 is_eastern = True
            
#             if gps_lat > -29.0:
#                 is_northern = True
#             elif gps_lat < -30.0:
#                 is_southern = True
        
#         # Build personalized advice in Sesotho
#         advice_parts = []
        
#         # 1. LOCATION-SPECIFIC OPENING
#         location_context = []
#         if gps_lat and gps_lon:
#             location_context.append(f"Polasi ea hao e likhokahanong tsa {gps_lat:.4f}°S, {gps_lon:.4f}°E")
#             if altitude_display:
#                 location_context.append(f"bophahamong ba {altitude_display}")
#             location_context.append(f"seterekeng sa {district}")
#         else:
#             location_context.append(f"Polasi ea hao e seterekeng sa {district}")
        
#         advice_parts.append(f"{' '.join(location_context)} e tobane le maemo a khethehileng bakeng sa {disease_name.replace('_', ' ')}.")
        
#         # 2. ALTITUDE-BASED RECOMMENDATIONS
#         if gps_alt:
#             if altitude_tier == 'highland':
#                 temp = self._get_highland_temp(gps_alt)
#                 advice_parts.append(f"Bophahamong ba {int(gps_alt)}m, masiu a bata ({temp}°C). Sena se liehisa kholo ea likokoana-hloko empa se liehisa kholo ea semela. Sebelisa meriana hoseng haholo ha mocheso o phahama ho feta 10°C.")
                
#                 if 'blight' in disease_name.lower():
#                     advice_parts.append(f"Maemo a lithaba a thusa nts'etsopele ea 'bola ea morao'. Eketsa ho fafatsa ka koporo ho ea matsatsing a mang le a mang a 5 nakong ea lipula.")
#                 elif 'mildew' in disease_name.lower():
#                     advice_parts.append(f"Mongobo oa lithaba o khothalletsa 'phofshoana e tšoeu'. Netefatsa phepelo e ntle ea moea ka ho fapanya limela (eketsa 10-15cm ho sebaka se tloaelehileng).")
                    
#             elif altitude_tier == 'midland':
#                 advice_parts.append(f"Bophahamo ba heno ba bohareng ({int(gps_alt)}m) bo fana ka maemo a matle a kholo. Nako e tloaelehileng ea kalafo e sebetsa hantle mona.")
                
#             elif altitude_tier == 'lowland':
#                 advice_parts.append(f"Bophahamong ba {int(gps_alt)}m, mocheso o futhumetseng o potlakisa ho hasana ha mafu. Fokotsa nako ea kalafo ka 20-30% ha o bapisa le likhothaletso tsa lithaba.")
        
#         # 3. REGIONAL CLIMATE RECOMMENDATIONS
#         if is_western:
#             advice_parts.append("Bophirima ba Lesotho (sebaka sa heno) se fumana pula e fokolang (600-800mm ka selemo). Nakong ea komello, tsepamisa mohopolo ho baballeng mongobo oa mobu. Sebelisa boea ba limela ho boloka mongobo oa mobu le ho fokotsa khatello ea semela.")
#             if 'blight' in disease_name.lower():
#                 advice_parts.append("Leha pula e fokola bophirima ba Lesotho, phoka ea hoseng e ntse e ka hlohlelletsa 'bola ea morao'. Sebelisa meriana ea fungal hoseng haholo pele phoka e qhibidoha.")
                
#         elif is_eastern:
#             advice_parts.append("Bochabela ba Lesotho (sebaka sa heno) bo fumana pula e ngata (1000-1500mm ka selemo). Mongobo ona o mongata o baka maemo a loketseng mafu a fungal. Eketsa nako ea ho sebelisa meriana ea fungal 'me u netefatse hore metsi a phalla hantle.")
#             if 'mildew' in disease_name.lower():
#                 advice_parts.append("Sebaka sa heno sa pula e ngata ke sebaka se nang le 'phofshoana e tšoeu' haholo. Nahana ka ho sebelisa meriana ea fungal e tsamaeang ka har'a semela le ho ntlafatsa phepelo ea moea ka ho faola makala ka nepo.")
                
#         if is_northern:
#             advice_parts.append("Leboea la Lesotho (sebaka sa heno) le na le mocheso o futhumetseng, o ka potlakisang mehlolo ea mafu. Hlahloba limela letsatsi le letsatsi nakong ea kholo e phahameng.")
#         elif is_southern:
#             advice_parts.append("Boroa ba Lesotho (sebaka sa heno) bo na le mocheso o batang. Mafu a hola butle, empa tšenyo ea serame e ka fokolisa limela tsa heno.")
        
#         # 4. SEASON-SPECIFIC ADVICE
#         advice_parts.append(season_advice)
        
#         # 5. DISEASE-SPECIFIC TREATMENT
#         disease_lower = disease_name.lower()
        
#         if 'blight' in disease_lower:
#             if altitude_tier == 'highland':
#                 advice_parts.append(f"KALAFO EA BOLA EA MORAO bakeng sa lithaba: Sebelisa copper hydroxide (250g/100L) matsatsing a mang le a mang a 5-7. Lithabeng tsa Mokhotlong/Thaba-Tseka, 'bola ea morao' ke lefu la #1 la litapole.")
#             elif is_eastern:
#                 advice_parts.append(f"KALAFO EA BOLA EA MORAO bakeng sa bochabela ba Lesotho: Ka lebaka la sebaka sa heno sa pula e ngata ({gps_lon:.1f}°E), sebelisa meriana ea fungal ea metalaxyl e thibelang matsatsing a mang le a mang a 7 nakong ea lipula.")
#             else:
#                 advice_parts.append(f"KALAFO EA BOLA EA MORAO: Sebelisa meriana ea fungal e thehiloeng ho koporo matsatsing a mang le a mang a 7-10. Tlosa makhasi a kulang hanghang 'me u a senye hole le tšimo ea hao.")
                
#         elif 'mildew' in disease_lower:
#             if is_eastern or altitude_tier == 'highland':
#                 advice_parts.append(f"KALAFO EA PHOFSHOANA E TŠOEU bakeng sa sebaka sa heno se nang le mongobo o mongata: Sebelisa sebabole (200g/100L) beke le beke. Phoka ea hoseng sebakeng sa heno e baka maemo a loketseng 'phofshoana e tšoeu'.")
#             else:
#                 advice_parts.append(f"KALAFO EA PHOFSHOANA E TŠOEU: Sebelisa oli ea neem kapa sebabole beke le beke. Nosetsa limela motso, eseng holimo, ho fokotsa mongobo oa makhasi.")
                
#         elif 'rust' in disease_lower:
#             if is_western:
#                 advice_parts.append(f"KALAFO EA KUTU bakeng sa bophirima ba Lesotho: Maemo a heno a omileng a thusa nts'etsopele ea kutu. Sebelisa azoxystrobin (100ml/100L) ha u qala ho bona matšoao.")
#             else:
#                 advice_parts.append(f"KALAFO EA KUTU: Tlosa makhasi a amehileng. Sebelisa meriana ea fungal e nang le azoxystrobin kapa tebuconazole.")
                
#         elif 'aphid' in disease_lower:
#             advice_parts.append(f"TAOLO EA LITSUTSU: Ho latela sebaka sa heno, lokolla likokoanyana tse thusang (ladybugs) tse fumanehang Lesotho Agricultural Supply kapa fafatsa ka oli ea neem (30ml/10L). Litsutsu li ata haholo nakong ea selemo sa Lesotho (September-Okastase).")
            
#         elif 'rot' in disease_lower:
#             if is_eastern:
#                 advice_parts.append(f"KALAFO EA HO BOLA bakeng sa bochabela ba Lesotho: Sebaka sa heno sa pula e ngata se hloka libethe tse phahamisitsoeng (30cm) bakeng sa ho phalla ha metsi. Sebelisa meriana ea fungal e thehiloeng ho koporo e kenngoa mobung.")
#             else:
#                 advice_parts.append(f"KALAFO EA HO BOLA: Ntlafatsa phallo ea metsi hanghang. Fokotsa ho nosetsa. Sebelisa meriana ea fungal e thehiloeng ho koporo.")
        
#         elif 'virus' in disease_lower:
#             advice_parts.append(f"TAOLO EA VAERASE: Vaerase ha e na pheko. Tlosa limela tse tšoaelitsoeng hanghang seterekeng sa {district}. Laola likokoanyana tse tsamaisang vaerase 'me u sebelise peo e se nang vaerase. Lesotho, vaerase ea tomato spotted wilt e tloaelehile libakeng tse tlase.")
        
#         elif 'healthy' in disease_lower:
#             advice_parts.append(f"✅ {crop_type} ea hao e bonahala e phetse hantle. Tsoela pele ka mekhoa e metle ea temo seterekeng sa {district}.")
        
#         else:
#             advice_parts.append(f"Bakeng sa {disease_name} seterekeng sa {district}, ikopanye le ofisiri ea temo ea sebaka sa heno bakeng sa kalafo e tobileng.")
        
#         # 6. SOIL-SPECIFIC ADVICE
#         if soil_type and soil_type != 'mobu oa heno':
#             if 'clay' in soil_type.lower():
#                 advice_parts.append(f"Mobu oa heno oa {soil_type} seterekeng sa {district} o hloka libethe tse phahamisitsoeng bakeng sa phallo e betere ea metsi. Eketsa lehlabathe la noka le manyolo a manyolo ho ntlafatsa sebopeho sa mobu.")
#             elif 'sandy' in soil_type.lower():
#                 advice_parts.append(f"Mobu oa heno oa {soil_type} seterekeng sa {district} o phalla kapele. Eketsa manyolo a manyolo ho boloka mongobo. Libakeng tse omeletseng joalo ka bophirima ba Lesotho, sena se bohlokoa haholo.")
#             elif 'loam' in soil_type.lower():
#                 advice_parts.append(f"Mobu oa heno oa {soil_type} o loketse {crop_type} maemong a setereke sa {district}.")
        
#         # 7. IRRIGATION ADVICE
#         if irrigation and irrigation != 'mokhoa oa heno oa nosetso':
#             if irrigation.lower() == 'drip':
#                 if is_western:
#                     advice_parts.append("Nosetso ea hao ea drip e ntle haholo bakeng sa maemo a omileng a bophirima ba Lesotho. Nosetsa hoseng haholo (6-8 AM) ho fokotsa mouoane.")
#                 else:
#                     advice_parts.append("Nosetso ea hao ea drip e nepahetse. Nosetsa hoseng haholo ho lumella makhasi ho omella.")
#             elif irrigation.lower() == 'overhead' or irrigation.lower() == 'sprinkler':
#                 if is_eastern or altitude_tier == 'highland':
#                     advice_parts.append("⚠️ Sebakeng sa heno sa pula e ngata / mongobo o mongata, nosetso ea holimo e hasanya mafu. Fetela ho nosetso ea drip kapa nosetsa feela boemong ba mobu.")
#                 else:
#                     advice_parts.append("Fetela ho nosetso ea drip ha ho khoneha. Nosetso ea holimo e hasanya mafu a mangata a fungal.")
        
#         # 8. GROWTH STAGE ADVICE
#         if growth_stage != "Unknown":
#             if growth_stage == "seedling":
#                 advice_parts.append(f"{crop_type} ea hao e boemong ba mahlomela. Limela tse nyane seterekeng sa {district} li kotsing. Hlahloba letsatsi le letsatsi bakeng sa ho hasana ha mafu.")
#             elif growth_stage == "flowering":
#                 advice_parts.append(f"{crop_type} ea hao e thunya. Qoba ho fafatsa nakong ea thunyo e phahameng (9 AM - 3 PM) ho sireletsa linotši. Fafatsa hoseng haholo kapa mantsiboea.")
#             elif growth_stage == "fruiting/harvest":
#                 advice_parts.append(f"{crop_type} ea hao e boemong ba litholoana. Latela nako ea pele ho kotulo ho meriana eohle ea likokonyana - sheba letšoao la matsatsi a ho emela kamora ho fafatsa pele ho kotulo.")
        
#         # 9. FARMER EXPERIENCE LEVEL
#         if experience_level == 'beginner':
#             advice_parts.append("👨‍🌾 Keletso ea moqali: Qala ka sebaka se senyenyane sa teko pele. Kamehla apara liatlana, mask, le liaparo tsa ho itšireletsa ha u fafatsa. Bala mangolo a meriana eohle ka hloko.")
#         elif experience_level == 'expert':
#             advice_parts.append("🔬 Khothaletso ea setsebi: Fapanyetsana pakeng tsa lihlopha tse fapaneng tsa meriana ea fungal (FRAC codes) ho thibela nts'etsopele ea khanyetso.")
        
#         # 10. LOCAL RESOURCE RECOMMENDATIONS
#         if district and district != 'sebaka sa heno':
#             advice_parts.append(f"📍 Lisebelisoa tsa sebaka sa heno seterekeng sa {district}: Ikopanye le ofisiri ea temo ea sebaka sa heno bakeng sa keletso e tobileng le tlhahlobo ea mobu ea mahala.")
        
#         # 11. DOSAGE CALCULATION
#         if plot_size and plot_size > 0:
#             water_liters = int(plot_size * 200)
#             buckets = int(water_liters / 10)
#             advice_parts.append(f"📐 Bakeng sa tšimo ea heno ea {plot_size} hectare, kopanya sehlahisoa se khothaletsoang le metsi a {water_liters}L (hoo e ka bang linkho tse {buckets} tsa 10L).")
        
#         # Combine all advice with double newlines for paragraph separation
#         personalized_advice = "\n\n".join(advice_parts)
        
#         return {
#             'advice': personalized_advice,
#             'matched_on': {
#                 'district': district,
#                 'latitude': gps_lat,
#                 'longitude': gps_lon,
#                 'altitude_tier': altitude_tier,
#                 'altitude_m': gps_alt,
#                 'soil': soil_type,
#                 'irrigation': irrigation,
#                 'growth_stage': growth_stage,
#                 'season': season,
#                 'days_since_planting': days_since_planting,
#                 'region': 'bophirima' if is_western else 'bochabela' if is_eastern else 'bohareng',
#             },
#             'farmer_level': experience_level,
#         }

#     def post(self, request):
#         try:
#             user = request.user

#             import logging
#             logger = logging.getLogger(__name__)
#             logger.warning(f"[SaveScan] ========== NEW SCAN REQUEST ==========")
#             logger.warning(f"[SaveScan] incoming data: {dict(request.data)}")

#             # Handle language preference
#             incoming_lang = request.data.get('language') or request.data.get('lang')
#             if incoming_lang in ['st', 'en']:
#                 user.language_preferences = incoming_lang
#                 user.save(update_fields=['language_preferences'])
#             lang = user.language_preferences
#             logger.warning(f"[SaveScan] 🌐 LANGUAGE PREFERENCE: '{lang}'")

#             # Get disease name from request
#             raw_label = (request.data.get('diseaseName')
#                         or request.data.get('DiseaseName')
#                         or 'Healthy')
#             clean_label = raw_label.replace('___', ' ').replace('_', ' ').strip()
#             logger.warning(f"[SaveScan] 🦠 Disease: '{clean_label}'")

#             image_url = (request.data.get('imageUrl')
#                         or request.data.get('image_url')
#                         or request.data.get('ImageFile')
#                         or '')

#             confidence = float(request.data.get('confidence')
#                               or request.data.get('ConfidenceLevel')
#                               or 0.0)

#             profile_id = (request.data.get('profileId')
#                          or request.data.get('ProfileID'))
            
#             # GPS DATA
#             gps_lat = request.data.get('latitude')
#             gps_lon = request.data.get('longitude')
#             gps_alt = request.data.get('altitude')
            
#             try:
#                 if gps_lat:
#                     gps_lat = float(gps_lat)
#                 if gps_lon:
#                     gps_lon = float(gps_lon)
#                 if gps_alt:
#                     gps_alt = float(gps_alt)
#             except (TypeError, ValueError):
#                 pass
            
#             gps_district = (request.data.get('gps_district')
#                            or request.data.get('district')
#                            or user.district
#                            or '')
            
#             logger.warning(f"[SaveScan] 📍 GPS: lat={gps_lat}, lon={gps_lon}, alt={gps_alt}, district={gps_district}")

#             scan_mode = (request.data.get('scan_mode')
#                         or request.data.get('scanMode')
#                         or 'general').lower()
#             wants_personalized = scan_mode == 'personalized'

#             logger.warning(f"[SaveScan] 📱 Mode: scan_mode='{scan_mode}', wants_personalized={wants_personalized}")

#             # Get crop profile
#             target_profile = None
#             if profile_id and str(profile_id).lower() not in ('null', 'none', ''):
#                 target_profile = CropProfile.objects.filter(
#                     pk=profile_id, FarmerID=user
#                 ).first()

#             crop_type = (target_profile.VegetableType
#                         if target_profile
#                         else request.data.get('cropType', 'Vegetable'))

#             # Save plant with GPS data
#             new_plant = Plant.objects.create(
#                 FarmerID=user,
#                 CropProfile=target_profile,
#                 CropType=crop_type,
#                 ImageFile=image_url,
#                 latitude=gps_lat,
#                 longitude=gps_lon,
#                 altitude_meters=gps_alt,
#                 gps_district=gps_district,
#             )
            
#             # Create diagnosis
#             urgent = any(w in clean_label.lower()
#                         for w in ['blight', 'rot', 'wilt', 'mold', 'virus',
#                                  'bacteria', 'phytophthora', 'fusarium'])
#             follow_up_date = date.today() + timedelta(days=3 if urgent else 10)

#             diagnosis = Diagnosis.objects.create(
#                 PlantID=new_plant,
#                 DiseaseName=clean_label,
#                 ConfidenceLevel=confidence,
#                 follow_up_date=follow_up_date,
#             )

#             # Get treatment from database
#             tq = Q(DiseaseName__iexact=clean_label) | Q(DiseaseName__iexact=raw_label)
#             treat = Treatment.objects.filter(tq).first()
#             kb_entry = KnowledgeBase.objects.filter(tq).first()

#             # Default values (English)
#             res_pesticide = treat.RecommendedPesticide if treat else 'Consult local expert'
#             res_dosage = treat.Dosage if treat else 'N/A'
            
#             if treat and treat.ApplicationSteps:
#                 res_steps = treat.ApplicationSteps
#             elif kb_entry and kb_entry.TreatmentInfo:
#                 res_steps = kb_entry.TreatmentInfo
#             else:
#                 res_steps = 'Isolate plant immediately and consult your local agricultural officer.'

#             res_disease = clean_label

#             # Calculate dosage for plot
#             dosage_calc = {}
#             plot_ha = target_profile.plot_size_hectares if target_profile else None
#             if treat and plot_ha:
#                 dosage_calc = treat.calculate_for_plot(plot_ha)

#             # ============================================================
#             # APPLY SESOTHO TRANSLATIONS IF LANGUAGE IS 'st'
#             # ============================================================
#             if lang == 'st':
#                 logger.warning(f"[SaveScan] 🎯 APPLYING SESOTHO TRANSLATION for disease: '{clean_label}'")
                
#                 st_pesticide = self._get_sesotho(clean_label, 'pesticide')
#                 st_dosage = self._get_sesotho(clean_label, 'dosage')
#                 st_steps = self._get_sesotho(clean_label, 'steps')
                
#                 if st_pesticide:
#                     res_pesticide = st_pesticide
#                     logger.warning(f"[SaveScan] ✅ Sesotho PESTICIDE applied")
#                 else:
#                     logger.warning(f"[SaveScan] ⚠️ No Sesotho pesticide found for '{clean_label}'")
                    
#                 if st_dosage:
#                     res_dosage = st_dosage
#                     logger.warning(f"[SaveScan] ✅ Sesotho DOSAGE applied")
#                 else:
#                     logger.warning(f"[SaveScan] ⚠️ No Sesotho dosage found for '{clean_label}'")
                    
#                 if st_steps:
#                     res_steps = st_steps
#                     logger.warning(f"[SaveScan] ✅ Sesotho STEPS applied")

#             # ============================================================
#             # PERSONALIZED MODE - Use appropriate language version
#             # ============================================================
#             personalized_advice = None
#             matched_context = None
#             personalized_dosage = None

#             if wants_personalized and target_profile:
#                 logger.warning(f"[SaveScan] 📝 Generating personalized advice...")
                
#                 # Choose the appropriate language version
#                 if lang == 'st':
#                     personalized = self._generate_personalized_advice_sesotho(
#                         disease_name=clean_label,
#                         farmer=user,
#                         crop_profile=target_profile,
#                         gps_district=gps_district,
#                         gps_lat=gps_lat,
#                         gps_lon=gps_lon,
#                         gps_alt=gps_alt,
#                     )
#                     logger.warning(f"[SaveScan] ✅ Generated personalized advice in SESOTHO")
#                 else:
#                     personalized = self._generate_personalized_advice(
#                         disease_name=clean_label,
#                         farmer=user,
#                         crop_profile=target_profile,
#                         gps_district=gps_district,
#                         gps_lat=gps_lat,
#                         gps_lon=gps_lon,
#                         gps_alt=gps_alt,
#                     )
#                     logger.warning(f"[SaveScan] ✅ Generated personalized advice in ENGLISH")
                
#                 personalized_advice = personalized['advice']
#                 matched_context = personalized['matched_on']
                
#                 if dosage_calc:
#                     personalized_dosage = {
#                         'product': res_pesticide,
#                         'amount': dosage_calc.get('product_display'),
#                         'water': dosage_calc.get('water_display'),
#                         'unit': dosage_calc.get('dosage_unit'),
#                         'plot_hectares': dosage_calc.get('plot_hectares'),
#                         'raw': {
#                             'product_amount': dosage_calc.get('product_amount'),
#                             'water_litres': dosage_calc.get('water_litres'),
#                             'buckets_10l': dosage_calc.get('buckets_10l'),
#                         },
#                     }

#             # Build personalized block
#             personalized_block = None
#             if wants_personalized and target_profile:
#                 personalized_block = {
#                     'advice': personalized_advice,
#                     'dosage': personalized_dosage,
#                     'matched_on': matched_context,
#                     'farmer_level': user.experience_level,
#                 }

#             # ============================================================
#             # PREPARE RESPONSE
#             # ============================================================
#             response_data = {
#                 'status': 'success',
#                 'id': diagnosis.DiagnosisID,
#                 'follow_up_date': follow_up_date.isoformat(),
#                 'crop_type': crop_type,
#                 'scan_mode': scan_mode,
#                 'language_used': lang,
#                 'gps_data': {
#                     'latitude': gps_lat,
#                     'longitude': gps_lon,
#                     'altitude': gps_alt,
#                     'district': gps_district,
#                 },
#                 '_debug': {
#                     'received_scan_mode': scan_mode,
#                     'wants_personalized': wants_personalized,
#                     'target_profile_found': target_profile is not None,
#                     'gps_received': gps_lat is not None,
#                     'language': lang,
#                     'sesotho_translations_available': {
#                         'pesticide': self._get_sesotho(clean_label, 'pesticide') is not None,
#                         'dosage': self._get_sesotho(clean_label, 'dosage') is not None,
#                         'steps': self._get_sesotho(clean_label, 'steps') is not None,
#                     } if lang == 'st' else None,
#                 },
#                 'personalized': personalized_block,
#                 'results': {
#                     'disease': res_disease,
#                     'pesticide': res_pesticide,
#                     'dosage': res_dosage,
#                     'steps': res_steps,
#                     'confidence': confidence,
#                     'treatment_dose_display': dosage_calc.get('product_display') if dosage_calc and wants_personalized else None,
#                     'water_volume_display': dosage_calc.get('water_display') if dosage_calc and wants_personalized else None,
#                 },
#                 'treatment_product': res_pesticide,
#                 'personalized_advice': personalized_advice if wants_personalized else None,
#             }

#             logger.warning(f"[SaveScan] 📤 RESPONSE SUMMARY:")
#             logger.warning(f"[SaveScan]   - Language: {lang}")
#             logger.warning(f"[SaveScan]   - Personalized advice length: {len(personalized_advice) if personalized_advice else 0} chars")
#             logger.warning(f"[SaveScan] ========== SCAN COMPLETE ==========")
            
#             return Response(response_data)

#         except Exception as e:
#             import traceback
#             logger = logging.getLogger(__name__)
#             logger.error(f"[SaveScan] ❌ ERROR: {str(e)}")
#             logger.error(traceback.format_exc())
#             return Response(
#                 {'error': str(e), 'detail': traceback.format_exc()},
#                 status=status.HTTP_400_BAD_REQUEST,
#             )


# # ── 7. HISTORY & REPORTS ─────────────────────────────────────────────────────

# class FarmerHistoryView(APIView):
#     permission_classes = [IsAuthenticated]

#     def get(self, request):
#         plants = Plant.objects.filter(FarmerID=request.user).order_by('-DateCaptured')
#         history = []
#         for p in plants:
#             diag = Diagnosis.objects.filter(PlantID=p).first()
#             if diag:
#                 history.append({
#                     'plant_id': p.PlantID,
#                     'crop': p.CropType,
#                     'image': p.ImageFile,
#                     'disease': diag.DiseaseName,
#                     'date': p.DateCaptured.strftime('%d %b, %Y'),
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
#                 treat = Treatment.objects.filter(
#                     DiseaseName__iexact=diag.DiseaseName
#                 ).first()
#                 report_data.append({
#                     'FarmerID_id': request.user.id,
#                     'ReportDate': p.DateCaptured.isoformat(),
#                     'DiagnosisSummary': diag.DiseaseName.replace('_', ' ').upper(),
#                     'TreatmentSummary': (treat.ApplicationSteps
#                                          if treat else 'Isolate plant immediately.'),
#                     'ImageURL': p.ImageFile,
#                 })
#         return Response(report_data)


# # ── 8. MARKET PRICES ─────────────────────────────────────────────────────────

# class MarketPricesView(APIView):
#     permission_classes = [IsAuthenticated]

#     def get(self, request):
#         district = request.query_params.get('district')
#         prices = MarketPrice.objects.all().order_by('-date_recorded')
#         if district:
#             prices = prices.filter(district__iexact=district)
#         return Response([{
#             'id': p.PriceID,
#             'vegetable_name': p.vegetable_name,
#             'market_name': p.market_name,
#             'district': p.district,
#             'price_per_kg': float(p.price_per_kg),
#             'currency': p.currency,
#             'date_recorded': p.date_recorded.isoformat(),
#             'price_trend': p.price_trend,
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
#             'status': 'success',
#             'message': 'Feedback recorded. Thank you!',
#             'id': diag.DiagnosisID,
#         })


# # ── 10. FARMER INSIGHTS ──────────────────────────────────────────────────────

# class FarmerInsightView(APIView):
#     permission_classes = [IsAuthenticated]

#     def get(self, request):
#         from django.db.models import Count
#         insight, _ = FarmerInsight.objects.get_or_create(FarmerID=request.user)

#         plants = Plant.objects.filter(FarmerID=request.user)
#         total_scans = plants.count()
#         diagnoses = Diagnosis.objects.filter(PlantID__in=plants)
#         healthy = diagnoses.filter(DiseaseName__iexact='healthy').count()

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

#         insight.total_scans = total_scans
#         insight.total_diseases_detected = total_scans - healthy
#         insight.total_healthy_scans = healthy
#         insight.most_common_disease = top['DiseaseName'] if top else None
#         insight.most_scanned_crop = top_crop['CropType'] if top_crop else None
#         insight.save()

#         return Response({
#             'total_scans': insight.total_scans,
#             'total_diseases_detected': insight.total_diseases_detected,
#             'total_healthy_scans': insight.total_healthy_scans,
#             'most_common_disease': insight.most_common_disease,
#             'most_scanned_crop': insight.most_scanned_crop,
#             'streak_healthy_days': insight.streak_healthy_days,
#             'last_updated': insight.last_updated.isoformat(),
#         })


# # ── 11. GROWTH JOURNAL ───────────────────────────────────────────────────────

# class GrowthJournalView(APIView):
#     permission_classes = [IsAuthenticated]

#     def get(self, request):
#         profile_id = request.query_params.get('crop_profile_id')
#         entries = GrowthJournalEntry.objects.filter(FarmerID=request.user)
#         if profile_id:
#             entries = entries.filter(CropProfile__ProfileID=profile_id)
#         return Response([{
#             'id': e.EntryID,
#             'crop_profile_id': e.CropProfile.ProfileID,
#             'crop_name': e.CropProfile.VegetableType,
#             'entry_date': e.entry_date.isoformat(),
#             'title': e.title,
#             'body': e.body,
#             'mood': e.mood,
#             'photo_url': e.photo_url,
#             'created_at': e.DateCreated.isoformat(),
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
#             FarmerID=request.user,
#             CropProfile=profile,
#             title=request.data.get('title', ''),
#             body=request.data.get('body', ''),
#             mood=request.data.get('mood', 'ok'),
#             photo_url=request.data.get('photo_url'),
#             entry_date=request.data.get('entry_date', date.today()),
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
#     try:
#         post = CommunityPost.objects.get(id=post_id, farmer=request.user)
#         post.delete()
#         return Response(status=204)
#     except CommunityPost.DoesNotExist:
#         return Response({'error': 'Post not found or you do not have permission'}, status=404)
#     except Exception as e:
#         return Response({'error': str(e)}, status=500)


# @api_view(['GET'])
# @permission_classes([IsAuthenticated])
# def get_community_comments(request, post_id):
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


# # ── 13. INSIGHTS & TRENDS FOR PLOTLY CHARTS ───────────────────────────────────

# class FarmerInsightsTrendsView(APIView):
#     permission_classes = [IsAuthenticated]
    
#     def get(self, request):
#         try:
#             import logging
#             logger = logging.getLogger(__name__)
            
#             user = request.user
#             today = timezone.now().date()
            
#             plants = Plant.objects.filter(FarmerID=user)
#             diagnoses = Diagnosis.objects.filter(PlantID__in=plants)
            
#             logger.warning(f"User: {user.username}, Plants: {plants.count()}, Diagnoses: {diagnoses.count()}")
            
#             total_scans = plants.count()
#             total_diseases = diagnoses.exclude(DiseaseName__iexact='healthy').count()
#             total_healthy = diagnoses.filter(DiseaseName__iexact='healthy').count()
            
#             from django.db.models.functions import TruncDate
#             from django.db.models import Count
            
#             last_30_days = today - timedelta(days=30)
            
#             trend_data = []
#             for i in range(29, -1, -1):
#                 date_key = (today - timedelta(days=i)).isoformat()
#                 trend_data.append({
#                     'date': date_key,
#                     'healthy': 0,
#                     'unhealthy': 0
#                 })
            
#             daily_healthy = diagnoses.filter(
#                 DateDiagnosed__date__gte=last_30_days,
#                 DiseaseName__iexact='healthy'
#             ).annotate(
#                 date=TruncDate('DateDiagnosed')
#             ).values('date').annotate(
#                 count=Count('DiagnosisID')
#             ).order_by('date')
            
#             for item in daily_healthy:
#                 if item['date']:
#                     date_key = item['date'].isoformat()
#                     for td in trend_data:
#                         if td['date'] == date_key:
#                             td['healthy'] = item['count']
#                             break
            
#             daily_diseased = diagnoses.filter(
#                 DateDiagnosed__date__gte=last_30_days
#             ).exclude(
#                 DiseaseName__iexact='healthy'
#             ).annotate(
#                 date=TruncDate('DateDiagnosed')
#             ).values('date').annotate(
#                 count=Count('DiagnosisID')
#             ).order_by('date')
            
#             for item in daily_diseased:
#                 if item['date']:
#                     date_key = item['date'].isoformat()
#                     for td in trend_data:
#                         if td['date'] == date_key:
#                             td['unhealthy'] = item['count']
#                             break
            
#             top_diseases = diagnoses.exclude(
#                 DiseaseName__iexact='healthy'
#             ).values('DiseaseName').annotate(
#                 count=Count('DiagnosisID')
#             ).order_by('-count')[:10]
            
#             top_diseases_list = []
#             for item in top_diseases:
#                 top_diseases_list.append({
#                     'name': item['DiseaseName'].replace('_', ' ').title(),
#                     'count': item['count']
#                 })
            
#             scans_by_crop = plants.values('CropType').annotate(
#                 count=Count('PlantID')
#             ).order_by('-count')[:10]
            
#             crops_list = []
#             for item in scans_by_crop:
#                 crops_list.append({
#                     'name': item['CropType'] or 'Unknown',
#                     'count': item['count']
#                 })
            
#             health_summary = {
#                 'total_scans': total_scans,
#                 'healthy': total_healthy,
#                 'diseased': total_diseases,
#                 'healthy_percentage': round((total_healthy / total_scans * 100), 1) if total_scans > 0 else 0,
#                 'diseased_percentage': round((total_diseases / total_scans * 100), 1) if total_scans > 0 else 0,
#             }
            
#             weekly_data = []
#             for i in range(5, -1, -1):
#                 week_start = today - timedelta(days=i*7)
#                 week_end = week_start + timedelta(days=6)
#                 week_scans = plants.filter(
#                     DateCaptured__date__gte=week_start,
#                     DateCaptured__date__lte=week_end
#                 ).count()
#                 weekly_data.append({
#                     'week_label': f"{week_start.strftime('%b %d')} - {week_end.strftime('%b %d')}",
#                     'scans': week_scans
#                 })
            
#             confidence_data = [
#                 {'range': '90-100%', 'count': diagnoses.filter(ConfidenceLevel__gte=0.9).count(), 'color': '#4CAF50'},
#                 {'range': '70-89%', 'count': diagnoses.filter(ConfidenceLevel__gte=0.7, ConfidenceLevel__lt=0.9).count(), 'color': '#8BC34A'},
#                 {'range': '50-69%', 'count': diagnoses.filter(ConfidenceLevel__gte=0.5, ConfidenceLevel__lt=0.7).count(), 'color': '#FFC107'},
#                 {'range': 'Below 50%', 'count': diagnoses.filter(ConfidenceLevel__lt=0.5).count(), 'color': '#FF9800'},
#             ]
            
#             diagnosed_with_feedback = diagnoses.filter(
#                 treatment_outcome__isnull=False
#             ).exclude(treatment_outcome='')
            
#             recovered = diagnosed_with_feedback.filter(treatment_outcome='recovered').count()
#             no_change = diagnosed_with_feedback.filter(treatment_outcome='no_change').count()
#             worsened = diagnosed_with_feedback.filter(treatment_outcome='worsened').count()
            
#             recovery_rate = 0
#             if diagnosed_with_feedback.count() > 0:
#                 recovery_rate = round((recovered / diagnosed_with_feedback.count()) * 100, 1)
            
#             recovery_data = [
#                 {'label': 'Recovered', 'value': recovered, 'color': '#4CAF50'},
#                 {'label': 'No Change', 'value': no_change, 'color': '#FFC107'},
#                 {'label': 'Worsened', 'value': worsened, 'color': '#F44336'}
#             ]
            
#             severity_data = diagnoses.filter(
#                 severity__isnull=False
#             ).exclude(severity='').values('severity').annotate(
#                 count=Count('DiagnosisID')
#             )
            
#             severity_map = {
#                 'mild': {'label': 'Mild', 'color': '#8BC34A'},
#                 'moderate': {'label': 'Moderate', 'color': '#FFC107'},
#                 'severe': {'label': 'Severe', 'color': '#F44336'}
#             }
            
#             severity_list = []
#             for item in severity_data:
#                 sev = item['severity']
#                 if sev in severity_map:
#                     severity_list.append({
#                         'label': severity_map[sev]['label'],
#                         'value': item['count'],
#                         'color': severity_map[sev]['color']
#                     })
            
#             district_data = diagnoses.filter(
#                 PlantID__gps_district__isnull=False
#             ).exclude(
#                 PlantID__gps_district=''
#             ).values('PlantID__gps_district').annotate(
#                 count=Count('DiagnosisID')
#             ).order_by('-count')[:10]
            
#             district_list = []
#             for item in district_data:
#                 district_list.append({
#                     'district': item['PlantID__gps_district'],
#                     'total': item['count']
#                 })
            
#             crop_health = []
#             for crop in scans_by_crop[:5]:
#                 crop_name = crop['CropType'] or 'Unknown'
#                 crop_plants = plants.filter(CropType=crop_name)
#                 crop_diagnoses = Diagnosis.objects.filter(PlantID__in=crop_plants)
#                 healthy_count = crop_diagnoses.filter(DiseaseName__iexact='healthy').count()
#                 diseased_count = crop_diagnoses.exclude(DiseaseName__iexact='healthy').count()
#                 total = healthy_count + diseased_count
#                 health_percentage = round((healthy_count / total * 100), 1) if total > 0 else 0
                
#                 crop_health.append({
#                     'crop': crop_name,
#                     'health_percentage': health_percentage
#                 })
            
#             from django.db.models.functions import ExtractMonth
            
#             seasonal_data = diagnoses.annotate(
#                 month=ExtractMonth('DateDiagnosed')
#             ).values('month').annotate(
#                 count=Count('DiagnosisID')
#             ).order_by('month')
            
#             month_names = {
#                 1: 'Jan', 2: 'Feb', 3: 'Mar', 4: 'Apr',
#                 5: 'May', 6: 'Jun', 7: 'Jul', 8: 'Aug',
#                 9: 'Sep', 10: 'Oct', 11: 'Nov', 12: 'Dec'
#             }
            
#             seasonal_counts = []
#             for item in seasonal_data:
#                 month_num = item['month']
#                 if month_num:
#                     seasonal_counts.append({
#                         'month': month_names.get(month_num, 'Unknown'),
#                         'count': item['count']
#                     })
            
#             response_data = {
#                 'statistics': {
#                     'total_scans': total_scans,
#                     'total_diseases': total_diseases,
#                     'total_healthy': total_healthy,
#                     'unique_crops': len(crops_list),
#                     'unique_diseases': len(top_diseases_list),
#                     'recovery_rate': recovery_rate,
#                     'healthy_percentage': health_summary['healthy_percentage'],
#                     'diseased_percentage': health_summary['diseased_percentage'],
#                 },
#                 'charts': {
#                     'trend_data': trend_data,
#                     'top_diseases': top_diseases_list,
#                     'scans_by_crop': crops_list,
#                     'health_summary': health_summary,
#                     'weekly_activity': weekly_data,
#                     'confidence_distribution': confidence_data,
#                     'recovery_data': recovery_data,
#                     'severity_distribution': severity_list,
#                     'district_distribution': district_list,
#                     'crop_health_summary': crop_health,
#                     'seasonal_patterns': seasonal_counts,
#                 }
#             }
            
#             logger.warning(f"Response generated successfully")
#             return Response(response_data)
            
#         except Exception as e:
#             import traceback
#             error_detail = traceback.format_exc()
#             print(f"ERROR in FarmerInsightsTrendsView: {str(e)}")
#             print(error_detail)
#             return Response(
#                 {'error': str(e), 'detail': error_detail},
#                 status=status.HTTP_500_INTERNAL_SERVER_ERROR
#             )


# # ── 14. ADMIN DASHBOARD LIST VIEWS ────────────────────────────────────────────

# class FarmerListView(APIView):
#     permission_classes = [IsAuthenticated]
    
#     def get(self, request):
#         if not request.user.is_staff:
#             return Response({'error': 'Admin access required'}, status=403)
        
#         farmers = Farmer.objects.all().values('id', 'username', 'email', 'first_name', 'last_name', 'district')
#         return Response(list(farmers))


# class TreatmentListView(APIView):
#     permission_classes = [IsAuthenticated]
    
#     def get(self, request):
#         if not request.user.is_staff:
#             return Response({'error': 'Admin access required'}, status=403)
        
#         treatments = Treatment.objects.all().values('TreatmentID', 'DiseaseName', 'RecommendedPesticide')
#         return Response(list(treatments))


# class KnowledgeBaseListView(APIView):
#     permission_classes = [IsAuthenticated]
    
#     def get(self, request):
#         if not request.user.is_staff:
#             return Response({'error': 'Admin access required'}, status=403)
        
#         entries = KnowledgeBase.objects.all().values('EntryID', 'DiseaseName')
#         return Response(list(entries))


# class DiagnosisListView(APIView):
#     permission_classes = [IsAuthenticated]
    
#     def get(self, request):
#         if not request.user.is_staff:
#             return Response({'error': 'Admin access required'}, status=403)
        
#         try:
#             diagnoses = Diagnosis.objects.all()
            
#             result = []
#             for d in diagnoses:
#                 result.append({
#                     'DiagnosisID': d.DiagnosisID,
#                     'DiseaseName': d.DiseaseName if d.DiseaseName else 'Unknown',
#                     'ConfidenceLevel': float(d.ConfidenceLevel) if d.ConfidenceLevel is not None else 0.0,
#                     'severity': d.severity if d.severity else 'Not specified',
#                     'treatment_outcome': d.treatment_outcome if d.treatment_outcome else 'Pending',
#                     'DateDiagnosed': d.DateDiagnosed.isoformat() if d.DateDiagnosed else None,
#                 })
            
#             return Response(result)
            
#         except Exception as e:
#             import traceback
#             print(f"DiagnosisListView error: {str(e)}")
#             print(traceback.format_exc())
#             return Response(
#                 {'error': f'Failed to load diagnoses: {str(e)}'},
#                 status=500
#             )


# class PlantListView(APIView):
#     permission_classes = [IsAuthenticated]
    
#     def get(self, request):
#         if not request.user.is_staff:
#             return Response({'error': 'Admin access required'}, status=403)
        
#         plants = Plant.objects.all().values('PlantID', 'CropType', 'DateCaptured', 'gps_district')
#         return Response(list(plants))


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
from django.conf import settings

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
        if Farmer.objects.filter(email=data.get('email', '').lower()).exists():
            return Response(
                {'error': 'Email already exists'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        raw_password = data.get('password', '')
        try:
            validate_password(raw_password)
        except DjangoValidationError as exc:
            return Response(
                {
                    'error': 'Password is too weak.',
                    'details': list(exc.messages),
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

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
            'status': 'success',
            'message': 'Verification email sent.',
            'email': user.email,
        }, status=status.HTTP_201_CREATED)

    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# def send_activation_email(request, user):
#     """
#     Send activation email with HTML button and correct domain
#     """
#     uid = urlsafe_base64_encode(force_bytes(user.pk))
#     token = default_token_generator.make_token(user)
    
#     # Use the domain from settings (set on Render)
#     domain = getattr(settings, 'SITE_DOMAIN', 'farmaid-backend.onrender.com')
#     protocol = getattr(settings, 'SITE_PROTOCOL', 'https')
    
#     activation_link = f"{protocol}://{domain}/api/activate/{uid}/{token}/"
    
#     # HTML email with button
#     html_message = f"""
#     <!DOCTYPE html>
#     <html>
#     <head>
#         <meta charset="UTF-8">
#         <title>FarmAid Email Verification</title>
#         <style>
#             body {{
#                 font-family: Arial, sans-serif;
#                 line-height: 1.6;
#                 color: #333;
#                 background-color: #f4f4f4;
#                 margin: 0;
#                 padding: 0;
#             }}
#             .container {{
#                 max-width: 600px;
#                 margin: 20px auto;
#                 background-color: #ffffff;
#                 border-radius: 10px;
#                 overflow: hidden;
#                 box-shadow: 0 2px 10px rgba(0,0,0,0.1);
#             }}
#             .header {{
#                 background: linear-gradient(135deg, #2E7D32 0%, #1B5E20 100%);
#                 color: white;
#                 padding: 30px 20px;
#                 text-align: center;
#             }}
#             .header h1 {{
#                 margin: 0;
#                 font-size: 28px;
#             }}
#             .content {{
#                 padding: 30px;
#                 background-color: #ffffff;
#             }}
#             .greeting {{
#                 font-size: 18px;
#                 margin-bottom: 20px;
#             }}
#             .message {{
#                 margin-bottom: 20px;
#                 color: #555;
#             }}
#             .button-container {{
#                 text-align: center;
#                 margin: 30px 0;
#             }}
#             .button {{
#                 display: inline-block;
#                 padding: 14px 32px;
#                 background: linear-gradient(135deg, #2E7D32 0%, #1B5E20 100%);
#                 color: white !important;
#                 text-decoration: none;
#                 border-radius: 50px;
#                 font-weight: bold;
#                 font-size: 16px;
#                 transition: transform 0.2s ease, box-shadow 0.2s ease;
#                 box-shadow: 0 4px 10px rgba(46,125,50,0.3);
#             }}
#             .button:hover {{
#                 transform: translateY(-2px);
#                 box-shadow: 0 6px 15px rgba(46,125,50,0.4);
#             }}
#             .button:active {{
#                 transform: translateY(0);
#             }}
#             .link-text {{
#                 text-align: center;
#                 margin-top: 20px;
#                 padding-top: 20px;
#                 border-top: 1px solid #eee;
#             }}
#             .link-text p {{
#                 font-size: 12px;
#                 color: #999;
#                 word-break: break-all;
#             }}
#             .footer {{
#                 background-color: #f8f9fa;
#                 padding: 20px;
#                 text-align: center;
#                 font-size: 12px;
#                 color: #777;
#                 border-top: 1px solid #eee;
#             }}
#             .footer p {{
#                 margin: 5px 0;
#             }}
#             .expiry-note {{
#                 font-size: 12px;
#                 color: #888;
#                 text-align: center;
#                 margin-top: 20px;
#             }}
#         </style>
#     </head>
#     <body>
#         <div class="container">
#             <div class="header">
#                 <h1>🌱 FarmAid Lesotho</h1>
#                 <p>Grow Smarter. Feed the Nation.</p>
#             </div>
            
#             <div class="content">
#                 <div class="greeting">
#                     <strong>Dumela {user.first_name or user.email}!</strong>
#                 </div>
                
#                 <div class="message">
#                     <p>Thank you for registering with <strong>FarmAid Lesotho</strong>.</p>
#                     <p>Please verify your email address to activate your account and start using our services. You'll be able to:</p>
#                     <ul>
#                         <li>📸 Scan crops for disease detection</li>
#                         <li>📊 Track your farm analytics</li>
#                         <li>💬 Join the farming community</li>
#                         <li>📈 Get personalized recommendations</li>
#                     </ul>
#                 </div>
                
#                 <div class="button-container">
#                     <a href="{activation_link}" class="button">✅ Verify Email Address</a>
#                 </div>
                
#                 <div class="expiry-note">
#                     <p>⏰ This verification link will expire in <strong>24 hours</strong>.</p>
#                 </div>
                
#                 <div class="link-text">
#                     <p>If the button doesn't work, copy and paste this link into your browser:</p>
#                     <p><strong>{activation_link}</strong></p>
#                 </div>
                
#                 <div class="message">
#                     <p>If you did not create an account with FarmAid, please ignore this email.</p>
#                 </div>
#             </div>
            
#             <div class="footer">
#                 <p>&copy; 2025 FarmAid Lesotho. All rights reserved.</p>
#                 <p>🌍 Empowering Lesotho's farmers through technology</p>
#                 <p>📧 Contact us: support@farmaid.co.ls</p>
#             </div>
#         </div>
#     </body>
#     </html>
#     """
    
#     # Plain text fallback
#     plain_message = f"""
# Dumela {user.first_name or user.email}!

# Thank you for registering with FarmAid Lesotho.

# Please click the link below to verify your email address and activate your account:

# {activation_link}

# This verification link will expire in 24 hours.

# If you did not create an account with FarmAid, please ignore this email.

# Thank you for joining FarmAid Lesotho! 🌱

# ---
# FarmAid Lesotho | Grow Smarter. Feed the Nation.
# """
    
#     email = EmailMessage(
#         'Activate Your FarmAid Account',
#         plain_message,
#         to=[user.email],
#     )
#     email.send()
def send_activation_email(request, user):
    """
    Send activation email with prominent VERIFY button
    The button is the primary action, not the text link
    """
    uid = urlsafe_base64_encode(force_bytes(user.pk))
    token = default_token_generator.make_token(user)
    
    # Use the domain from settings (set on Render)
    domain = getattr(settings, 'SITE_DOMAIN', 'farmaid-backend.onrender.com')
    protocol = getattr(settings, 'SITE_PROTOCOL', 'https')
    
    activation_link = f"{protocol}://{domain}/api/activate/{uid}/{token}/"
    
    # HTML email with prominent button and hidden text link
    html_message = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <title>FarmAid Email Verification</title>
        <style>
            body {{
                font-family: Arial, sans-serif;
                line-height: 1.6;
                color: #333;
                background-color: #f4f4f4;
                margin: 0;
                padding: 0;
            }}
            .container {{
                max-width: 600px;
                margin: 20px auto;
                background-color: #ffffff;
                border-radius: 10px;
                overflow: hidden;
                box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            }}
            .header {{
                background: linear-gradient(135deg, #2E7D32 0%, #1B5E20 100%);
                color: white;
                padding: 30px 20px;
                text-align: center;
            }}
            .header h1 {{
                margin: 0;
                font-size: 28px;
            }}
            .content {{
                padding: 30px;
                background-color: #ffffff;
                text-align: center;
            }}
            .greeting {{
                font-size: 18px;
                margin-bottom: 20px;
                text-align: left;
            }}
            .message {{
                margin-bottom: 25px;
                color: #555;
                text-align: left;
            }}
            .button-container {{
                text-align: center;
                margin: 30px 0;
            }}
            .verify-button {{
                display: inline-block;
                padding: 16px 40px;
                background: linear-gradient(135deg, #2E7D32 0%, #1B5E20 100%);
                color: white !important;
                text-decoration: none;
                border-radius: 50px;
                font-weight: bold;
                font-size: 18px;
                transition: transform 0.2s ease, box-shadow 0.2s ease;
                box-shadow: 0 4px 10px rgba(46,125,50,0.3);
                cursor: pointer;
            }}
            .verify-button:hover {{
                transform: translateY(-2px);
                box-shadow: 0 6px 15px rgba(46,125,50,0.4);
            }}
            .verify-button:active {{
                transform: translateY(0);
            }}
            .expiry-note {{
                font-size: 12px;
                color: #888;
                text-align: center;
                margin: 20px 0;
                padding: 10px;
                background-color: #f8f9fa;
                border-radius: 5px;
            }}
            .link-collapse {{
                margin-top: 30px;
                padding-top: 20px;
                border-top: 1px solid #eee;
                text-align: center;
            }}
            .toggle-link {{
                color: #2E7D32;
                text-decoration: none;
                font-size: 12px;
                cursor: pointer;
            }}
            .hidden-link {{
                display: none;
                margin-top: 10px;
                padding: 10px;
                background-color: #f8f9fa;
                border-radius: 5px;
                word-break: break-all;
                font-size: 12px;
                color: #666;
            }}
            .footer {{
                background-color: #f8f9fa;
                padding: 20px;
                text-align: center;
                font-size: 12px;
                color: #777;
                border-top: 1px solid #eee;
            }}
            .footer p {{
                margin: 5px 0;
            }}
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🌱 FarmAid Lesotho</h1>
                <p>Grow Smarter. Feed the Nation.</p>
            </div>
            
            <div class="content">
                <div class="greeting">
                    <strong>Dumela {user.first_name or user.email}!</strong>
                </div>
                
                <div class="message">
                    <p>Thank you for registering with <strong>FarmAid Lesotho</strong>.</p>
                    <p>Click the button below to verify your email address and activate your account:</p>
                </div>
                
                <div class="button-container">
                    <a href="{activation_link}" class="verify-button">✅ VERIFY MY ACCOUNT</a>
                </div>
                
                <div class="expiry-note">
                    ⏰ This verification link will expire in <strong>24 hours</strong>
                </div>
                
                <details class="link-collapse">
                    <summary style="color: #2E7D32; font-size: 12px; cursor: pointer;">Show technical details</summary>
                    <div class="hidden-link" style="display: block; margin-top: 10px;">
                        <p style="margin: 0;">If the button doesn't work, copy and paste this link:</p>
                        <p style="word-break: break-all; font-size: 11px; color: #999; margin-top: 5px;">{activation_link}</p>
                    </div>
                </details>
                
                <div class="message" style="margin-top: 20px;">
                    <p>If you did not create an account with FarmAid, please ignore this email.</p>
                </div>
            </div>
            
            <div class="footer">
                <p>&copy; 2025 FarmAid Lesotho. All rights reserved.</p>
                <p>🌍 Empowering Lesotho's farmers through technology</p>
            </div>
        </div>
    </body>
    </html>
    """
    
    # Plain text fallback (kept simple)
    plain_message = f"""
Dumela {user.first_name or user.email}!

Thank you for registering with FarmAid Lesotho.

Click or copy this link to verify your email address:
{activation_link}

This verification link will expire in 24 hours.

If you did not create an account with FarmAid, please ignore this email.

Thank you for joining FarmAid Lesotho! 🌱
---
FarmAid Lesotho | Grow Smarter. Feed the Nation.
"""
    
    email = EmailMessage(
        'Activate Your FarmAid Account',
        plain_message,
        to=[user.email],
    )
    email.send(fail_silently=False)

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
        uid = force_str(urlsafe_base64_decode(uidb64))
        user = Farmer.objects.get(pk=uid)
    except (TypeError, ValueError, OverflowError, Farmer.DoesNotExist):
        user = None

    if user is not None and default_token_generator.check_token(user, token):
        user.is_active = True
        user.save()
        return HttpResponse("""
        <!DOCTYPE html>
        <html>
        <head>
            <title>Account Activated - FarmAid Lesotho</title>
            <style>
                body {
                    font-family: Arial, sans-serif;
                    text-align: center;
                    padding: 50px;
                    background: linear-gradient(135deg, #f4f4f4 0%, #e8f5e9 100%);
                }
                .container {
                    max-width: 500px;
                    margin: 0 auto;
                    background: white;
                    padding: 40px;
                    border-radius: 20px;
                    box-shadow: 0 10px 30px rgba(0,0,0,0.1);
                }
                h1 { color: #2E7D32; }
                .button {
                    display: inline-block;
                    padding: 12px 30px;
                    background: #2E7D32;
                    color: white;
                    text-decoration: none;
                    border-radius: 25px;
                    margin-top: 20px;
                }
                .button:hover { background: #1B5E20; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>✅ Account Activated!</h1>
                <p>Your FarmAid account has been successfully activated.</p>
                <p>You can now close this window and log in to the app.</p>
                <a href="#" onclick="window.close(); return false;" class="button">Close Window</a>
                <p style="margin-top: 30px; font-size: 12px; color: #888;">FarmAid Lesotho | Grow Smarter. Feed the Nation.</p>
            </div>
        </body>
        </html>
        """)
    return HttpResponse("""
    <!DOCTYPE html>
    <html>
    <head>
        <title>Activation Failed - FarmAid Lesotho</title>
        <style>
            body {
                font-family: Arial, sans-serif;
                text-align: center;
                padding: 50px;
                background: linear-gradient(135deg, #f4f4f4 0%, #ffebee 100%);
            }
            .container {
                max-width: 500px;
                margin: 0 auto;
                background: white;
                padding: 40px;
                border-radius: 20px;
                box-shadow: 0 10px 30px rgba(0,0,0,0.1);
            }
            h1 { color: #c62828; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>❌ Activation Failed</h1>
            <p>The activation link is invalid or has expired.</p>
            <p>Please request a new activation email from the FarmAid app.</p>
            <p style="margin-top: 30px; font-size: 12px; color: #888;">FarmAid Lesotho | Grow Smarter. Feed the Nation.</p>
        </div>
    </body>
    </html>
    """, status=400)


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
            'token': token.key,
            'farmerName': f"{user.first_name} {user.last_name}".strip(),
            'is_staff': user.is_staff,
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
        'status': 'success',
        'message': 'Password updated!',
        'token': new_token.key,
    })


# ── 2. GOOGLE SIGN-IN ─────────────────────────────────────────────────────────

@api_view(['POST'])
@permission_classes([AllowAny])
def google_auth(request):
    from django.conf import settings
    import logging
    
    logger = logging.getLogger(__name__)
    
    id_token_str = request.data.get('id_token', '').strip()
    if not id_token_str:
        return Response({'error': 'id_token is required.'}, status=400)

    try:
        from google.oauth2 import id_token as google_id_token
        from google.auth.transport import requests as google_requests

        client_id = getattr(settings, 'GOOGLE_CLIENT_ID', None)
        
        logger.warning(f"[GoogleAuth] Using Client ID: {client_id}")
        
        if not client_id:
            return Response(
                {'error': 'GOOGLE_CLIENT_ID not configured in settings'},
                status=500,
            )
        
        id_info = google_id_token.verify_oauth2_token(
            id_token_str,
            google_requests.Request(),
            client_id,
        )
        
        logger.warning(f"[GoogleAuth] Token verified successfully for: {id_info.get('email')}")
        
    except ImportError:
        return Response(
            {'error': 'google-auth package not installed. Run: pip install google-auth'},
            status=500,
        )
    except ValueError as exc:
        error_msg = str(exc)
        logger.error(f"[GoogleAuth] Token validation error: {error_msg}")
        return Response({'error': f'Invalid Google token: {error_msg}'}, status=401)

    email = id_info.get('email', '').lower()
    first_name = id_info.get('given_name', '')
    last_name = id_info.get('family_name', '')
    photo_url = id_info.get('picture', '')

    if not email:
        return Response({'error': 'Google account has no email address.'}, status=400)

    user, created = Farmer.objects.get_or_create(
        email=email,
        defaults={
            'username': email,
            'first_name': first_name,
            'last_name': last_name,
            'is_active': True,
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
        'token': token.key,
        'farmerName': f"{user.first_name} {user.last_name}".strip() or email,
        'is_staff': user.is_staff,
        'email': user.email,
        'created': created,
    })


# ── 3. PROFILE & WEATHER ─────────────────────────────────────────────────────

class ProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        u = request.user
        return Response({
            'first_name': u.first_name,
            'last_name': u.last_name,
            'email': u.email,
            'district': u.district,
            'phone_number': u.phone_number,
            'language_preferences': u.language_preferences,
            'experience_level': u.experience_level,
            'profile_photo_url': u.profile_photo_url,
            'farm_size_hectares': u.farm_size_hectares if hasattr(u, 'farm_size_hectares') else None,
            'onboarding_complete': u.onboarding_complete if hasattr(u, 'onboarding_complete') else False,
        })

    def patch(self, request):
        user = request.user
        for attr, value in request.data.items():
            if hasattr(user, attr):
                setattr(user, attr, value)
        user.save()
        return Response({
            'status': 'success',
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
        user = request.user
        user_dist = (user.district or '').strip()
        now = timezone.now()

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
            'count': qs.count(),
            'unread_count': qs.filter(IsRead=False).count(),
            'alerts': AppAlertSerializer(qs, many=True).data,
        })

    def post(self, request):
        updated = AppAlert.objects.filter(
            FarmerID=request.user, IsRead=False
        ).update(IsRead=True)
        return Response({'status': 'success', 'marked_read': updated})


class AlertCountView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        now = timezone.now()
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
        """Get Sesotho translation from cache"""
        if not disease_name:
            return None
        try:
            cache = TranslationCache.objects.get(disease_name_en__iexact=disease_name)
            translations = {
                'pesticide': cache.pesticide_st,
                'dosage': cache.dosage_st,
                'steps': cache.steps_st,
            }
            result = translations.get(field)
            
            import logging
            logger = logging.getLogger(__name__)
            if result:
                logger.warning(f"[Sesotho] ✓ Found '{field}' for '{disease_name}': {result[:100]}...")
            else:
                logger.warning(f"[Sesotho] ✗ No '{field}' found for '{disease_name}'")
            
            return result
        except TranslationCache.DoesNotExist:
            import logging
            logger = logging.getLogger(__name__)
            logger.warning(f"[Sesotho] ✗ No translation cache entry for '{disease_name}'")
            return None
        except Exception as e:
            import logging
            logger = logging.getLogger(__name__)
            logger.warning(f"[Sesotho] Error: {e}")
            return None

    def _get_highland_temp(self, altitude):
        """Estimate temperature based on altitude in Lesotho"""
        base_temp = 22
        temp = base_temp - (altitude / 100 * 0.65)
        return int(temp)

    def _generate_personalized_advice(self, disease_name, farmer, crop_profile, gps_district, gps_lat, gps_lon, gps_alt):
        """Generate personalized advice in English USING GPS coordinates"""
        
        # Get farmer's data
        experience_level = farmer.experience_level
        district = gps_district or farmer.district or 'your area'
        
        # Get crop profile data
        crop_type = crop_profile.VegetableType if crop_profile else 'your crop'
        soil_type = crop_profile.SoilEnvironment or 'your soil type'
        irrigation = crop_profile.irrigation_method or 'your irrigation method'
        planting_date = crop_profile.PlantingDate
        plot_size = crop_profile.plot_size_hectares
        
        # Calculate days since planting and growth stage
        days_since_planting = 0
        growth_stage = "Unknown"
        if planting_date:
            days_since_planting = (date.today() - planting_date).days
            if days_since_planting < 14:
                growth_stage = "seedling"
            elif days_since_planting < 45:
                growth_stage = "vegetative"
            elif days_since_planting < 75:
                growth_stage = "flowering"
            else:
                growth_stage = "fruiting/harvest"
        
        # Determine altitude tier using GPS altitude
        altitude_tier = "lowland"
        altitude_display = None
        if gps_alt is not None:
            altitude_display = f"{int(gps_alt)}m"
            if gps_alt < 1800:
                altitude_tier = "lowland"
            elif gps_alt < 2200:
                altitude_tier = "midland"
            elif gps_alt < 2800:
                altitude_tier = "highland"
            else:
                altitude_tier = "alpine"
        
        # Determine current season
        current_month = date.today().month
        if 5 <= current_month <= 9:
            season = "dry"
            season_advice = "During this dry season, fungal diseases spread less. Focus on proper irrigation and soil moisture management."
        else:
            season = "wet"
            season_advice = "During this wet season, fungal diseases spread rapidly. Apply preventive fungicides and ensure good drainage."
        
        # Lesotho-specific climate zones based on latitude/longitude
        is_western = False
        is_eastern = False
        is_northern = False
        is_southern = False
        
        if gps_lat and gps_lon:
            if gps_lon < 27.5:
                is_western = True
            elif gps_lon > 28.5:
                is_eastern = True
            
            if gps_lat > -29.0:
                is_northern = True
            elif gps_lat < -30.0:
                is_southern = True
        
        # Build personalized advice based on GPS and farmer's data
        advice_parts = []
        
        # 1. LOCATION-SPECIFIC OPENING
        location_context = []
        if gps_lat and gps_lon:
            location_context.append(f"Your farm at coordinates {gps_lat:.4f}°S, {gps_lon:.4f}°E")
            if altitude_display:
                location_context.append(f"at {altitude_display} elevation")
            location_context.append(f"in {district} district")
        else:
            location_context.append(f"Your farm in {district} district")
        
        advice_parts.append(f"{' '.join(location_context)} faces specific conditions for {disease_name.replace('_', ' ')}.")
        
        # 2. ALTITUDE-BASED RECOMMENDATIONS
        if gps_alt:
            if altitude_tier == 'highland':
                temp = self._get_highland_temp(gps_alt)
                advice_parts.append(f"At {int(gps_alt)}m elevation, nights are cold ({temp}°C). This slows down pathogen development but also slows plant growth. Apply treatments early morning when temperatures rise above 10°C.")
                
                if 'blight' in disease_name.lower():
                    advice_parts.append(f"Highland conditions favor late blight development. Increase copper spray frequency to every 5 days during wet periods.")
                elif 'mildew' in disease_name.lower():
                    advice_parts.append(f"Highland humidity promotes powdery mildew. Ensure good air circulation by spacing plants wider (add 10-15cm to standard spacing).")
                    
            elif altitude_tier == 'midland':
                advice_parts.append(f"Your midland altitude ({int(gps_alt)}m) provides good growing conditions. Standard treatment intervals work well here.")
                
            elif altitude_tier == 'lowland':
                advice_parts.append(f"At {int(gps_alt)}m elevation, warmer temperatures accelerate disease spread. Reduce treatment intervals by 20-30% compared to highland recommendations.")
        
        # 3. REGIONAL CLIMATE RECOMMENDATIONS
        if is_western:
            advice_parts.append("Western Lesotho (your area) receives less rainfall (600-800mm annually). During dry spells, focus on soil moisture conservation. Use mulch to retain soil moisture and reduce plant stress.")
            if 'blight' in disease_name.lower():
                advice_parts.append("Despite lower rainfall in western Lesotho, morning dew can still promote blight. Apply fungicides early morning before dew forms.")
                
        elif is_eastern:
            advice_parts.append("Eastern Lesotho (your area) receives high rainfall (1000-1500mm annually). This high humidity creates perfect conditions for fungal diseases. Increase fungicide frequency and ensure excellent drainage.")
            if 'mildew' in disease_name.lower():
                advice_parts.append("Your high-rainfall area is a hotspot for powdery mildew. Consider using systemic fungicides and improve air circulation through proper pruning.")
                
        if is_northern:
            advice_parts.append("Northern Lesotho (your area) has warmer temperatures, which can accelerate disease cycles. Monitor crops daily during peak growing season.")
        elif is_southern:
            advice_parts.append("Southern Lesotho (your area) experiences cooler temperatures. Diseases develop slower, but frost damage can weaken plants making them susceptible.")
        
        # 4. SEASON-SPECIFIC ADVICE
        advice_parts.append(season_advice)
        
        # 5. DISEASE-SPECIFIC TREATMENT
        disease_lower = disease_name.lower()
        
        if 'blight' in disease_lower:
            if altitude_tier == 'highland':
                advice_parts.append(f"BLIGHT TREATMENT for highlands: Apply copper hydroxide (250g/100L) every 5-7 days. In Mokhotlong/Thaba-Tseka highlands, late blight is the #1 potato disease.")
            elif is_eastern:
                advice_parts.append(f"BLIGHT TREATMENT for eastern Lesotho: Due to your high rainfall area ({gps_lon:.1f}°E), apply metalaxyl-based fungicides preventively every 7 days during rainy season.")
            else:
                advice_parts.append(f"BLIGHT TREATMENT: Apply copper-based fungicide every 7-10 days. Remove infected leaves immediately and destroy them away from your field.")
                
        elif 'mildew' in disease_lower:
            if is_eastern or altitude_tier == 'highland':
                advice_parts.append(f"MILDEW TREATMENT for your high-humidity location: Apply sulfur (200g/100L) weekly. Your area's morning fog creates ideal mildew conditions.")
            else:
                advice_parts.append(f"MILDEW TREATMENT: Apply neem oil or sulfur weekly. Water plants at base, not overhead, to reduce leaf wetness.")
                
        elif 'rust' in disease_lower:
            if is_western:
                advice_parts.append(f"RUST TREATMENT for western Lesotho: Your drier conditions actually favor rust development. Apply azoxystrobin (100ml/100L) at first sign.")
            else:
                advice_parts.append(f"RUST TREATMENT: Remove affected leaves. Apply fungicide containing azoxystrobin or tebuconazole.")
                
        elif 'aphid' in disease_lower:
            advice_parts.append(f"APHID CONTROL: Based on your location, release ladybugs (available from Lesotho Agricultural Supply) or spray neem oil (30ml/10L). Aphids thrive in Lesotho's spring (September-October).")
            
        elif 'rot' in disease_lower:
            if is_eastern:
                advice_parts.append(f"ROT TREATMENT for eastern Lesotho: Your high rainfall area requires raised beds (30cm high) for drainage. Apply copper-based fungicide as soil drench.")
            else:
                advice_parts.append(f"ROT TREATMENT: Improve drainage immediately. Reduce watering. Apply copper-based fungicide.")
        
        elif 'virus' in disease_lower:
            advice_parts.append(f"VIRUS MANAGEMENT: Viruses have no cure. Remove infected plants immediately from {district}. Control insect vectors and use virus-free seeds. In Lesotho, tomato spotted wilt virus is common in lowlands.")
        
        elif 'healthy' in disease_lower:
            advice_parts.append(f"✅ Your {crop_type} appears healthy. Continue good agricultural practices in {district}.")
        
        else:
            advice_parts.append(f"For {disease_name} in {district}, consult your local agricultural extension officer for specific treatment.")
        
        # 6. SOIL-SPECIFIC ADVICE
        if soil_type and soil_type != 'your soil type':
            if 'clay' in soil_type.lower():
                advice_parts.append(f"Your {soil_type} soil in {district} needs raised beds for better drainage. Add river sand and compost to improve soil structure.")
            elif 'sandy' in soil_type.lower():
                advice_parts.append(f"Your {soil_type} soil in {district} drains quickly. Add compost to retain moisture. In dry areas like western Lesotho, this is especially important.")
            elif 'loam' in soil_type.lower():
                advice_parts.append(f"Your {soil_type} soil is ideal for {crop_type} in {district} conditions.")
        
        # 7. IRRIGATION ADVICE
        if irrigation and irrigation != 'your irrigation method':
            if irrigation.lower() == 'drip':
                if is_western:
                    advice_parts.append("Your drip irrigation is excellent for western Lesotho's drier conditions. Water early morning (6-8 AM) to minimize evaporation.")
                else:
                    advice_parts.append("Your drip irrigation is ideal. Water early morning to allow leaves to dry.")
            elif irrigation.lower() == 'overhead' or irrigation.lower() == 'sprinkler':
                if is_eastern or altitude_tier == 'highland':
                    advice_parts.append("⚠️ In your high-rainfall/high-humidity area, overhead watering spreads diseases. Switch to drip irrigation or water only at soil level.")
                else:
                    advice_parts.append("Switch to drip irrigation if possible. Overhead watering spreads many fungal diseases.")
        
        # 8. GROWTH STAGE ADVICE
        if growth_stage != "Unknown":
            if growth_stage == "seedling":
                advice_parts.append(f"Your {crop_type} is in seedling stage. Young plants in {district} are vulnerable. Monitor daily for disease spread.")
            elif growth_stage == "flowering":
                advice_parts.append(f"Your {crop_type} is flowering. Avoid spraying during peak flowering (9 AM - 3 PM) to protect bees. Spray early morning or late evening.")
            elif growth_stage == "fruiting/harvest":
                advice_parts.append(f"Your {crop_type} is in fruiting stage. Follow pre-harvest interval on all pesticides - check label for days to wait after spraying before harvest.")
        
        # 9. FARMER EXPERIENCE LEVEL
        if experience_level == 'beginner':
            advice_parts.append("👨‍🌾 Beginner tip: Start with a small test area first. Always wear gloves, mask, and protective clothing when spraying. Read all pesticide labels carefully.")
        elif experience_level == 'expert':
            advice_parts.append("🔬 Expert recommendation: Rotate between different fungicide groups (FRAC codes) to prevent resistance development.")
        
        # 10. LOCAL RESOURCE RECOMMENDATIONS
        if district and district != 'your area':
            advice_parts.append(f"📍 Local resources in {district}: Contact your nearest agricultural extension officer for site-specific advice and free soil testing.")
        
        # 11. DOSAGE CALCULATION
        if plot_size and plot_size > 0:
            water_liters = int(plot_size * 200)
            buckets = int(water_liters / 10)
            advice_parts.append(f"📐 For your {plot_size} hectare plot, mix the recommended product with {water_liters}L water (approx. {buckets} buckets of 10L).")
        
        # Combine all advice with double newlines for paragraph separation
        personalized_advice = "\n\n".join(advice_parts)
        
        return {
            'advice': personalized_advice,
            'matched_on': {
                'district': district,
                'latitude': gps_lat,
                'longitude': gps_lon,
                'altitude_tier': altitude_tier,
                'altitude_m': gps_alt,
                'soil': soil_type,
                'irrigation': irrigation,
                'growth_stage': growth_stage,
                'season': season,
                'days_since_planting': days_since_planting,
                'region': 'western' if is_western else 'eastern' if is_eastern else 'central',
            },
            'farmer_level': experience_level,
        }

    def _generate_personalized_advice_sesotho(self, disease_name, farmer, crop_profile, gps_district, gps_lat, gps_lon, gps_alt):
        """Generate personalized advice in Sesotho USING GPS coordinates"""
        
        # Get farmer's data
        experience_level = farmer.experience_level
        district = gps_district or farmer.district or 'sebaka sa heno'
        
        # Get crop profile data
        crop_type = crop_profile.VegetableType if crop_profile else 'sejalo sa heno'
        soil_type = crop_profile.SoilEnvironment or 'mobu oa heno'
        irrigation = crop_profile.irrigation_method or 'mokhoa oa heno oa nosetso'
        planting_date = crop_profile.PlantingDate
        plot_size = crop_profile.plot_size_hectares
        
        # Calculate days since planting and growth stage
        days_since_planting = 0
        growth_stage = "Unknown"
        if planting_date:
            days_since_planting = (date.today() - planting_date).days
            if days_since_planting < 14:
                growth_stage = "seedling"
            elif days_since_planting < 45:
                growth_stage = "vegetative"
            elif days_since_planting < 75:
                growth_stage = "flowering"
            else:
                growth_stage = "fruiting/harvest"
        
        # Determine altitude tier using GPS altitude
        altitude_tier = "lowland"
        altitude_display = None
        if gps_alt is not None:
            altitude_display = f"{int(gps_alt)}m"
            if gps_alt < 1800:
                altitude_tier = "lowland"
            elif gps_alt < 2200:
                altitude_tier = "midland"
            elif gps_alt < 2800:
                altitude_tier = "highland"
            else:
                altitude_tier = "alpine"
        
        # Determine current season
        current_month = date.today().month
        if 5 <= current_month <= 9:
            season = "dry"
            season_advice = "Nakong ena ea komello, mafu a fungal ha a hlaselle haholo. Tsepamisa mohopolo nosetsong e nepahetseng le taolong ea mongobo oa mobu."
        else:
            season = "wet"
            season_advice = "Nakong ena ea lipula, mafu a fungal a hasana ka potlako. Sebelisa meriana ea thibelo 'me u netefatse hore metsi a phalla hantle."
        
        # Lesotho-specific climate zones based on latitude/longitude
        is_western = False
        is_eastern = False
        is_northern = False
        is_southern = False
        
        if gps_lat and gps_lon:
            if gps_lon < 27.5:
                is_western = True
            elif gps_lon > 28.5:
                is_eastern = True
            
            if gps_lat > -29.0:
                is_northern = True
            elif gps_lat < -30.0:
                is_southern = True
        
        # Build personalized advice in Sesotho
        advice_parts = []
        
        # 1. LOCATION-SPECIFIC OPENING
        location_context = []
        if gps_lat and gps_lon:
            location_context.append(f"Polasi ea hao e likhokahanong tsa {gps_lat:.4f}°S, {gps_lon:.4f}°E")
            if altitude_display:
                location_context.append(f"bophahamong ba {altitude_display}")
            location_context.append(f"seterekeng sa {district}")
        else:
            location_context.append(f"Polasi ea hao e seterekeng sa {district}")
        
        advice_parts.append(f"{' '.join(location_context)} e tobane le maemo a khethehileng bakeng sa {disease_name.replace('_', ' ')}.")
        
        # 2. ALTITUDE-BASED RECOMMENDATIONS
        if gps_alt:
            if altitude_tier == 'highland':
                temp = self._get_highland_temp(gps_alt)
                advice_parts.append(f"Bophahamong ba {int(gps_alt)}m, masiu a bata ({temp}°C). Sena se liehisa kholo ea likokoana-hloko empa se liehisa kholo ea semela. Sebelisa meriana hoseng haholo ha mocheso o phahama ho feta 10°C.")
                
                if 'blight' in disease_name.lower():
                    advice_parts.append(f"Maemo a lithaba a thusa nts'etsopele ea 'bola ea morao'. Eketsa ho fafatsa ka koporo ho ea matsatsing a mang le a mang a 5 nakong ea lipula.")
                elif 'mildew' in disease_name.lower():
                    advice_parts.append(f"Mongobo oa lithaba o khothalletsa 'phofshoana e tšoeu'. Netefatsa phepelo e ntle ea moea ka ho fapanya limela (eketsa 10-15cm ho sebaka se tloaelehileng).")
                    
            elif altitude_tier == 'midland':
                advice_parts.append(f"Bophahamo ba heno ba bohareng ({int(gps_alt)}m) bo fana ka maemo a matle a kholo. Nako e tloaelehileng ea kalafo e sebetsa hantle mona.")
                
            elif altitude_tier == 'lowland':
                advice_parts.append(f"Bophahamong ba {int(gps_alt)}m, mocheso o futhumetseng o potlakisa ho hasana ha mafu. Fokotsa nako ea kalafo ka 20-30% ha o bapisa le likhothaletso tsa lithaba.")
        
        # 3. REGIONAL CLIMATE RECOMMENDATIONS
        if is_western:
            advice_parts.append("Bophirima ba Lesotho (sebaka sa heno) se fumana pula e fokolang (600-800mm ka selemo). Nakong ea komello, tsepamisa mohopolo ho baballeng mongobo oa mobu. Sebelisa boea ba limela ho boloka mongobo oa mobu le ho fokotsa khatello ea semela.")
            if 'blight' in disease_name.lower():
                advice_parts.append("Leha pula e fokola bophirima ba Lesotho, phoka ea hoseng e ntse e ka hlohlelletsa 'bola ea morao'. Sebelisa meriana ea fungal hoseng haholo pele phoka e qhibidoha.")
                
        elif is_eastern:
            advice_parts.append("Bochabela ba Lesotho (sebaka sa heno) bo fumana pula e ngata (1000-1500mm ka selemo). Mongobo ona o mongata o baka maemo a loketseng mafu a fungal. Eketsa nako ea ho sebelisa meriana ea fungal 'me u netefatse hore metsi a phalla hantle.")
            if 'mildew' in disease_name.lower():
                advice_parts.append("Sebaka sa heno sa pula e ngata ke sebaka se nang le 'phofshoana e tšoeu' haholo. Nahana ka ho sebelisa meriana ea fungal e tsamaeang ka har'a semela le ho ntlafatsa phepelo ea moea ka ho faola makala ka nepo.")
                
        if is_northern:
            advice_parts.append("Leboea la Lesotho (sebaka sa heno) le na le mocheso o futhumetseng, o ka potlakisang mehlolo ea mafu. Hlahloba limela letsatsi le letsatsi nakong ea kholo e phahameng.")
        elif is_southern:
            advice_parts.append("Boroa ba Lesotho (sebaka sa heno) bo na le mocheso o batang. Mafu a hola butle, empa tšenyo ea serame e ka fokolisa limela tsa heno.")
        
        # 4. SEASON-SPECIFIC ADVICE
        advice_parts.append(season_advice)
        
        # 5. DISEASE-SPECIFIC TREATMENT
        disease_lower = disease_name.lower()
        
        if 'blight' in disease_lower:
            if altitude_tier == 'highland':
                advice_parts.append(f"KALAFO EA BOLA EA MORAO bakeng sa lithaba: Sebelisa copper hydroxide (250g/100L) matsatsing a mang le a mang a 5-7. Lithabeng tsa Mokhotlong/Thaba-Tseka, 'bola ea morao' ke lefu la #1 la litapole.")
            elif is_eastern:
                advice_parts.append(f"KALAFO EA BOLA EA MORAO bakeng sa bochabela ba Lesotho: Ka lebaka la sebaka sa heno sa pula e ngata ({gps_lon:.1f}°E), sebelisa meriana ea fungal ea metalaxyl e thibelang matsatsing a mang le a mang a 7 nakong ea lipula.")
            else:
                advice_parts.append(f"KALAFO EA BOLA EA MORAO: Sebelisa meriana ea fungal e thehiloeng ho koporo matsatsing a mang le a mang a 7-10. Tlosa makhasi a kulang hanghang 'me u a senye hole le tšimo ea hao.")
                
        elif 'mildew' in disease_lower:
            if is_eastern or altitude_tier == 'highland':
                advice_parts.append(f"KALAFO EA PHOFSHOANA E TŠOEU bakeng sa sebaka sa heno se nang le mongobo o mongata: Sebelisa sebabole (200g/100L) beke le beke. Phoka ea hoseng sebakeng sa heno e baka maemo a loketseng 'phofshoana e tšoeu'.")
            else:
                advice_parts.append(f"KALAFO EA PHOFSHOANA E TŠOEU: Sebelisa oli ea neem kapa sebabole beke le beke. Nosetsa limela motso, eseng holimo, ho fokotsa mongobo oa makhasi.")
                
        elif 'rust' in disease_lower:
            if is_western:
                advice_parts.append(f"KALAFO EA KUTU bakeng sa bophirima ba Lesotho: Maemo a heno a omileng a thusa nts'etsopele ea kutu. Sebelisa azoxystrobin (100ml/100L) ha u qala ho bona matšoao.")
            else:
                advice_parts.append(f"KALAFO EA KUTU: Tlosa makhasi a amehileng. Sebelisa meriana ea fungal e nang le azoxystrobin kapa tebuconazole.")
                
        elif 'aphid' in disease_lower:
            advice_parts.append(f"TAOLO EA LITSUTSU: Ho latela sebaka sa heno, lokolla likokoanyana tse thusang (ladybugs) tse fumanehang Lesotho Agricultural Supply kapa fafatsa ka oli ea neem (30ml/10L). Litsutsu li ata haholo nakong ea selemo sa Lesotho (September-Okastase).")
            
        elif 'rot' in disease_lower:
            if is_eastern:
                advice_parts.append(f"KALAFO EA HO BOLA bakeng sa bochabela ba Lesotho: Sebaka sa heno sa pula e ngata se hloka libethe tse phahamisitsoeng (30cm) bakeng sa ho phalla ha metsi. Sebelisa meriana ea fungal e thehiloeng ho koporo e kenngoa mobung.")
            else:
                advice_parts.append(f"KALAFO EA HO BOLA: Ntlafatsa phallo ea metsi hanghang. Fokotsa ho nosetsa. Sebelisa meriana ea fungal e thehiloeng ho koporo.")
        
        elif 'virus' in disease_lower:
            advice_parts.append(f"TAOLO EA VAERASE: Vaerase ha e na pheko. Tlosa limela tse tšoaelitsoeng hanghang seterekeng sa {district}. Laola likokoanyana tse tsamaisang vaerase 'me u sebelise peo e se nang vaerase. Lesotho, vaerase ea tomato spotted wilt e tloaelehile libakeng tse tlase.")
        
        elif 'healthy' in disease_lower:
            advice_parts.append(f"✅ {crop_type} ea hao e bonahala e phetse hantle. Tsoela pele ka mekhoa e metle ea temo seterekeng sa {district}.")
        
        else:
            advice_parts.append(f"Bakeng sa {disease_name} seterekeng sa {district}, ikopanye le ofisiri ea temo ea sebaka sa heno bakeng sa kalafo e tobileng.")
        
        # 6. SOIL-SPECIFIC ADVICE
        if soil_type and soil_type != 'mobu oa heno':
            if 'clay' in soil_type.lower():
                advice_parts.append(f"Mobu oa heno oa {soil_type} seterekeng sa {district} o hloka libethe tse phahamisitsoeng bakeng sa phallo e betere ea metsi. Eketsa lehlabathe la noka le manyolo a manyolo ho ntlafatsa sebopeho sa mobu.")
            elif 'sandy' in soil_type.lower():
                advice_parts.append(f"Mobu oa heno oa {soil_type} seterekeng sa {district} o phalla kapele. Eketsa manyolo a manyolo ho boloka mongobo. Libakeng tse omeletseng joalo ka bophirima ba Lesotho, sena se bohlokoa haholo.")
            elif 'loam' in soil_type.lower():
                advice_parts.append(f"Mobu oa heno oa {soil_type} o loketse {crop_type} maemong a setereke sa {district}.")
        
        # 7. IRRIGATION ADVICE
        if irrigation and irrigation != 'mokhoa oa heno oa nosetso':
            if irrigation.lower() == 'drip':
                if is_western:
                    advice_parts.append("Nosetso ea hao ea drip e ntle haholo bakeng sa maemo a omileng a bophirima ba Lesotho. Nosetsa hoseng haholo (6-8 AM) ho fokotsa mouoane.")
                else:
                    advice_parts.append("Nosetso ea hao ea drip e nepahetse. Nosetsa hoseng haholo ho lumella makhasi ho omella.")
            elif irrigation.lower() == 'overhead' or irrigation.lower() == 'sprinkler':
                if is_eastern or altitude_tier == 'highland':
                    advice_parts.append("⚠️ Sebakeng sa heno sa pula e ngata / mongobo o mongata, nosetso ea holimo e hasanya mafu. Fetela ho nosetso ea drip kapa nosetsa feela boemong ba mobu.")
                else:
                    advice_parts.append("Fetela ho nosetso ea drip ha ho khoneha. Nosetso ea holimo e hasanya mafu a mangata a fungal.")
        
        # 8. GROWTH STAGE ADVICE
        if growth_stage != "Unknown":
            if growth_stage == "seedling":
                advice_parts.append(f"{crop_type} ea hao e boemong ba mahlomela. Limela tse nyane seterekeng sa {district} li kotsing. Hlahloba letsatsi le letsatsi bakeng sa ho hasana ha mafu.")
            elif growth_stage == "flowering":
                advice_parts.append(f"{crop_type} ea hao e thunya. Qoba ho fafatsa nakong ea thunyo e phahameng (9 AM - 3 PM) ho sireletsa linotši. Fafatsa hoseng haholo kapa mantsiboea.")
            elif growth_stage == "fruiting/harvest":
                advice_parts.append(f"{crop_type} ea hao e boemong ba litholoana. Latela nako ea pele ho kotulo ho meriana eohle ea likokonyana - sheba letšoao la matsatsi a ho emela kamora ho fafatsa pele ho kotulo.")
        
        # 9. FARMER EXPERIENCE LEVEL
        if experience_level == 'beginner':
            advice_parts.append("👨‍🌾 Keletso ea moqali: Qala ka sebaka se senyenyane sa teko pele. Kamehla apara liatlana, mask, le liaparo tsa ho itšireletsa ha u fafatsa. Bala mangolo a meriana eohle ka hloko.")
        elif experience_level == 'expert':
            advice_parts.append("🔬 Khothaletso ea setsebi: Fapanyetsana pakeng tsa lihlopha tse fapaneng tsa meriana ea fungal (FRAC codes) ho thibela nts'etsopele ea khanyetso.")
        
        # 10. LOCAL RESOURCE RECOMMENDATIONS
        if district and district != 'sebaka sa heno':
            advice_parts.append(f"📍 Lisebelisoa tsa sebaka sa heno seterekeng sa {district}: Ikopanye le ofisiri ea temo ea sebaka sa heno bakeng sa keletso e tobileng le tlhahlobo ea mobu ea mahala.")
        
        # 11. DOSAGE CALCULATION
        if plot_size and plot_size > 0:
            water_liters = int(plot_size * 200)
            buckets = int(water_liters / 10)
            advice_parts.append(f"📐 Bakeng sa tšimo ea heno ea {plot_size} hectare, kopanya sehlahisoa se khothaletsoang le metsi a {water_liters}L (hoo e ka bang linkho tse {buckets} tsa 10L).")
        
        # Combine all advice with double newlines for paragraph separation
        personalized_advice = "\n\n".join(advice_parts)
        
        return {
            'advice': personalized_advice,
            'matched_on': {
                'district': district,
                'latitude': gps_lat,
                'longitude': gps_lon,
                'altitude_tier': altitude_tier,
                'altitude_m': gps_alt,
                'soil': soil_type,
                'irrigation': irrigation,
                'growth_stage': growth_stage,
                'season': season,
                'days_since_planting': days_since_planting,
                'region': 'bophirima' if is_western else 'bochabela' if is_eastern else 'bohareng',
            },
            'farmer_level': experience_level,
        }

    def post(self, request):
        try:
            user = request.user

            import logging
            logger = logging.getLogger(__name__)
            logger.warning(f"[SaveScan] ========== NEW SCAN REQUEST ==========")
            logger.warning(f"[SaveScan] incoming data: {dict(request.data)}")

            # Handle language preference
            incoming_lang = request.data.get('language') or request.data.get('lang')
            if incoming_lang in ['st', 'en']:
                user.language_preferences = incoming_lang
                user.save(update_fields=['language_preferences'])
            lang = user.language_preferences
            logger.warning(f"[SaveScan] 🌐 LANGUAGE PREFERENCE: '{lang}'")

            # Get disease name from request
            raw_label = (request.data.get('diseaseName')
                        or request.data.get('DiseaseName')
                        or 'Healthy')
            clean_label = raw_label.replace('___', ' ').replace('_', ' ').strip()
            logger.warning(f"[SaveScan] 🦠 Disease: '{clean_label}'")

            image_url = (request.data.get('imageUrl')
                        or request.data.get('image_url')
                        or request.data.get('ImageFile')
                        or '')

            confidence = float(request.data.get('confidence')
                              or request.data.get('ConfidenceLevel')
                              or 0.0)

            profile_id = (request.data.get('profileId')
                         or request.data.get('ProfileID'))
            
            # GPS DATA
            gps_lat = request.data.get('latitude')
            gps_lon = request.data.get('longitude')
            gps_alt = request.data.get('altitude')
            
            try:
                if gps_lat:
                    gps_lat = float(gps_lat)
                if gps_lon:
                    gps_lon = float(gps_lon)
                if gps_alt:
                    gps_alt = float(gps_alt)
            except (TypeError, ValueError):
                pass
            
            gps_district = (request.data.get('gps_district')
                           or request.data.get('district')
                           or user.district
                           or '')
            
            logger.warning(f"[SaveScan] 📍 GPS: lat={gps_lat}, lon={gps_lon}, alt={gps_alt}, district={gps_district}")

            scan_mode = (request.data.get('scan_mode')
                        or request.data.get('scanMode')
                        or 'general').lower()
            wants_personalized = scan_mode == 'personalized'

            logger.warning(f"[SaveScan] 📱 Mode: scan_mode='{scan_mode}', wants_personalized={wants_personalized}")

            # Get crop profile
            target_profile = None
            if profile_id and str(profile_id).lower() not in ('null', 'none', ''):
                target_profile = CropProfile.objects.filter(
                    pk=profile_id, FarmerID=user
                ).first()

            crop_type = (target_profile.VegetableType
                        if target_profile
                        else request.data.get('cropType', 'Vegetable'))

            # Save plant with GPS data
            new_plant = Plant.objects.create(
                FarmerID=user,
                CropProfile=target_profile,
                CropType=crop_type,
                ImageFile=image_url,
                latitude=gps_lat,
                longitude=gps_lon,
                altitude_meters=gps_alt,
                gps_district=gps_district,
            )
            
            # Create diagnosis
            urgent = any(w in clean_label.lower()
                        for w in ['blight', 'rot', 'wilt', 'mold', 'virus',
                                 'bacteria', 'phytophthora', 'fusarium'])
            follow_up_date = date.today() + timedelta(days=3 if urgent else 10)

            diagnosis = Diagnosis.objects.create(
                PlantID=new_plant,
                DiseaseName=clean_label,
                ConfidenceLevel=confidence,
                follow_up_date=follow_up_date,
            )

            # Get treatment from database
            tq = Q(DiseaseName__iexact=clean_label) | Q(DiseaseName__iexact=raw_label)
            treat = Treatment.objects.filter(tq).first()
            kb_entry = KnowledgeBase.objects.filter(tq).first()

            # Default values (English)
            res_pesticide = treat.RecommendedPesticide if treat else 'Consult local expert'
            res_dosage = treat.Dosage if treat else 'N/A'
            
            if treat and treat.ApplicationSteps:
                res_steps = treat.ApplicationSteps
            elif kb_entry and kb_entry.TreatmentInfo:
                res_steps = kb_entry.TreatmentInfo
            else:
                res_steps = 'Isolate plant immediately and consult your local agricultural officer.'

            res_disease = clean_label

            # Calculate dosage for plot
            dosage_calc = {}
            plot_ha = target_profile.plot_size_hectares if target_profile else None
            if treat and plot_ha:
                dosage_calc = treat.calculate_for_plot(plot_ha)

            # ============================================================
            # APPLY SESOTHO TRANSLATIONS IF LANGUAGE IS 'st'
            # ============================================================
            if lang == 'st':
                logger.warning(f"[SaveScan] 🎯 APPLYING SESOTHO TRANSLATION for disease: '{clean_label}'")
                
                st_pesticide = self._get_sesotho(clean_label, 'pesticide')
                st_dosage = self._get_sesotho(clean_label, 'dosage')
                st_steps = self._get_sesotho(clean_label, 'steps')
                
                if st_pesticide:
                    res_pesticide = st_pesticide
                    logger.warning(f"[SaveScan] ✅ Sesotho PESTICIDE applied")
                else:
                    logger.warning(f"[SaveScan] ⚠️ No Sesotho pesticide found for '{clean_label}'")
                    
                if st_dosage:
                    res_dosage = st_dosage
                    logger.warning(f"[SaveScan] ✅ Sesotho DOSAGE applied")
                else:
                    logger.warning(f"[SaveScan] ⚠️ No Sesotho dosage found for '{clean_label}'")
                    
                if st_steps:
                    res_steps = st_steps
                    logger.warning(f"[SaveScan] ✅ Sesotho STEPS applied")

            # ============================================================
            # PERSONALIZED MODE - Use appropriate language version
            # ============================================================
            personalized_advice = None
            matched_context = None
            personalized_dosage = None

            if wants_personalized and target_profile:
                logger.warning(f"[SaveScan] 📝 Generating personalized advice...")
                
                # Choose the appropriate language version
                if lang == 'st':
                    personalized = self._generate_personalized_advice_sesotho(
                        disease_name=clean_label,
                        farmer=user,
                        crop_profile=target_profile,
                        gps_district=gps_district,
                        gps_lat=gps_lat,
                        gps_lon=gps_lon,
                        gps_alt=gps_alt,
                    )
                    logger.warning(f"[SaveScan] ✅ Generated personalized advice in SESOTHO")
                else:
                    personalized = self._generate_personalized_advice(
                        disease_name=clean_label,
                        farmer=user,
                        crop_profile=target_profile,
                        gps_district=gps_district,
                        gps_lat=gps_lat,
                        gps_lon=gps_lon,
                        gps_alt=gps_alt,
                    )
                    logger.warning(f"[SaveScan] ✅ Generated personalized advice in ENGLISH")
                
                personalized_advice = personalized['advice']
                matched_context = personalized['matched_on']
                
                if dosage_calc:
                    personalized_dosage = {
                        'product': res_pesticide,
                        'amount': dosage_calc.get('product_display'),
                        'water': dosage_calc.get('water_display'),
                        'unit': dosage_calc.get('dosage_unit'),
                        'plot_hectares': dosage_calc.get('plot_hectares'),
                        'raw': {
                            'product_amount': dosage_calc.get('product_amount'),
                            'water_litres': dosage_calc.get('water_litres'),
                            'buckets_10l': dosage_calc.get('buckets_10l'),
                        },
                    }

            # Build personalized block
            personalized_block = None
            if wants_personalized and target_profile:
                personalized_block = {
                    'advice': personalized_advice,
                    'dosage': personalized_dosage,
                    'matched_on': matched_context,
                    'farmer_level': user.experience_level,
                }

            # ============================================================
            # PREPARE RESPONSE
            # ============================================================
            response_data = {
                'status': 'success',
                'id': diagnosis.DiagnosisID,
                'follow_up_date': follow_up_date.isoformat(),
                'crop_type': crop_type,
                'scan_mode': scan_mode,
                'language_used': lang,
                'gps_data': {
                    'latitude': gps_lat,
                    'longitude': gps_lon,
                    'altitude': gps_alt,
                    'district': gps_district,
                },
                '_debug': {
                    'received_scan_mode': scan_mode,
                    'wants_personalized': wants_personalized,
                    'target_profile_found': target_profile is not None,
                    'gps_received': gps_lat is not None,
                    'language': lang,
                    'sesotho_translations_available': {
                        'pesticide': self._get_sesotho(clean_label, 'pesticide') is not None,
                        'dosage': self._get_sesotho(clean_label, 'dosage') is not None,
                        'steps': self._get_sesotho(clean_label, 'steps') is not None,
                    } if lang == 'st' else None,
                },
                'personalized': personalized_block,
                'results': {
                    'disease': res_disease,
                    'pesticide': res_pesticide,
                    'dosage': res_dosage,
                    'steps': res_steps,
                    'confidence': confidence,
                    'treatment_dose_display': dosage_calc.get('product_display') if dosage_calc and wants_personalized else None,
                    'water_volume_display': dosage_calc.get('water_display') if dosage_calc and wants_personalized else None,
                },
                'treatment_product': res_pesticide,
                'personalized_advice': personalized_advice if wants_personalized else None,
            }

            logger.warning(f"[SaveScan] 📤 RESPONSE SUMMARY:")
            logger.warning(f"[SaveScan]   - Language: {lang}")
            logger.warning(f"[SaveScan]   - Personalized advice length: {len(personalized_advice) if personalized_advice else 0} chars")
            logger.warning(f"[SaveScan] ========== SCAN COMPLETE ==========")
            
            return Response(response_data)

        except Exception as e:
            import traceback
            logger = logging.getLogger(__name__)
            logger.error(f"[SaveScan] ❌ ERROR: {str(e)}")
            logger.error(traceback.format_exc())
            return Response(
                {'error': str(e), 'detail': traceback.format_exc()},
                status=status.HTTP_400_BAD_REQUEST,
            )


# ── 7. HISTORY & REPORTS ─────────────────────────────────────────────────────

class FarmerHistoryView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        plants = Plant.objects.filter(FarmerID=request.user).order_by('-DateCaptured')
        history = []
        for p in plants:
            diag = Diagnosis.objects.filter(PlantID=p).first()
            if diag:
                history.append({
                    'plant_id': p.PlantID,
                    'crop': p.CropType,
                    'image': p.ImageFile,
                    'disease': diag.DiseaseName,
                    'date': p.DateCaptured.strftime('%d %b, %Y'),
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
                treat = Treatment.objects.filter(
                    DiseaseName__iexact=diag.DiseaseName
                ).first()
                report_data.append({
                    'FarmerID_id': request.user.id,
                    'ReportDate': p.DateCaptured.isoformat(),
                    'DiagnosisSummary': diag.DiseaseName.replace('_', ' ').upper(),
                    'TreatmentSummary': (treat.ApplicationSteps
                                         if treat else 'Isolate plant immediately.'),
                    'ImageURL': p.ImageFile,
                })
        return Response(report_data)


# ── 8. MARKET PRICES ─────────────────────────────────────────────────────────

class MarketPricesView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        district = request.query_params.get('district')
        prices = MarketPrice.objects.all().order_by('-date_recorded')
        if district:
            prices = prices.filter(district__iexact=district)
        return Response([{
            'id': p.PriceID,
            'vegetable_name': p.vegetable_name,
            'market_name': p.market_name,
            'district': p.district,
            'price_per_kg': float(p.price_per_kg),
            'currency': p.currency,
            'date_recorded': p.date_recorded.isoformat(),
            'price_trend': p.price_trend,
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
            'status': 'success',
            'message': 'Feedback recorded. Thank you!',
            'id': diag.DiagnosisID,
        })


# ── 10. FARMER INSIGHTS ──────────────────────────────────────────────────────

class FarmerInsightView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        from django.db.models import Count
        insight, _ = FarmerInsight.objects.get_or_create(FarmerID=request.user)

        plants = Plant.objects.filter(FarmerID=request.user)
        total_scans = plants.count()
        diagnoses = Diagnosis.objects.filter(PlantID__in=plants)
        healthy = diagnoses.filter(DiseaseName__iexact='healthy').count()

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

        insight.total_scans = total_scans
        insight.total_diseases_detected = total_scans - healthy
        insight.total_healthy_scans = healthy
        insight.most_common_disease = top['DiseaseName'] if top else None
        insight.most_scanned_crop = top_crop['CropType'] if top_crop else None
        insight.save()

        return Response({
            'total_scans': insight.total_scans,
            'total_diseases_detected': insight.total_diseases_detected,
            'total_healthy_scans': insight.total_healthy_scans,
            'most_common_disease': insight.most_common_disease,
            'most_scanned_crop': insight.most_scanned_crop,
            'streak_healthy_days': insight.streak_healthy_days,
            'last_updated': insight.last_updated.isoformat(),
        })


# ── 11. GROWTH JOURNAL ───────────────────────────────────────────────────────

class GrowthJournalView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        profile_id = request.query_params.get('crop_profile_id')
        entries = GrowthJournalEntry.objects.filter(FarmerID=request.user)
        if profile_id:
            entries = entries.filter(CropProfile__ProfileID=profile_id)
        return Response([{
            'id': e.EntryID,
            'crop_profile_id': e.CropProfile.ProfileID,
            'crop_name': e.CropProfile.VegetableType,
            'entry_date': e.entry_date.isoformat(),
            'title': e.title,
            'body': e.body,
            'mood': e.mood,
            'photo_url': e.photo_url,
            'created_at': e.DateCreated.isoformat(),
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
            FarmerID=request.user,
            CropProfile=profile,
            title=request.data.get('title', ''),
            body=request.data.get('body', ''),
            mood=request.data.get('mood', 'ok'),
            photo_url=request.data.get('photo_url'),
            entry_date=request.data.get('entry_date', date.today()),
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
    try:
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


# ── 13. INSIGHTS & TRENDS FOR PLOTLY CHARTS ───────────────────────────────────

class FarmerInsightsTrendsView(APIView):
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        try:
            import logging
            logger = logging.getLogger(__name__)
            
            user = request.user
            today = timezone.now().date()
            
            plants = Plant.objects.filter(FarmerID=user)
            diagnoses = Diagnosis.objects.filter(PlantID__in=plants)
            
            logger.warning(f"User: {user.username}, Plants: {plants.count()}, Diagnoses: {diagnoses.count()}")
            
            total_scans = plants.count()
            total_diseases = diagnoses.exclude(DiseaseName__iexact='healthy').count()
            total_healthy = diagnoses.filter(DiseaseName__iexact='healthy').count()
            
            from django.db.models.functions import TruncDate
            from django.db.models import Count
            
            last_30_days = today - timedelta(days=30)
            
            trend_data = []
            for i in range(29, -1, -1):
                date_key = (today - timedelta(days=i)).isoformat()
                trend_data.append({
                    'date': date_key,
                    'healthy': 0,
                    'unhealthy': 0
                })
            
            daily_healthy = diagnoses.filter(
                DateDiagnosed__date__gte=last_30_days,
                DiseaseName__iexact='healthy'
            ).annotate(
                date=TruncDate('DateDiagnosed')
            ).values('date').annotate(
                count=Count('DiagnosisID')
            ).order_by('date')
            
            for item in daily_healthy:
                if item['date']:
                    date_key = item['date'].isoformat()
                    for td in trend_data:
                        if td['date'] == date_key:
                            td['healthy'] = item['count']
                            break
            
            daily_diseased = diagnoses.filter(
                DateDiagnosed__date__gte=last_30_days
            ).exclude(
                DiseaseName__iexact='healthy'
            ).annotate(
                date=TruncDate('DateDiagnosed')
            ).values('date').annotate(
                count=Count('DiagnosisID')
            ).order_by('date')
            
            for item in daily_diseased:
                if item['date']:
                    date_key = item['date'].isoformat()
                    for td in trend_data:
                        if td['date'] == date_key:
                            td['unhealthy'] = item['count']
                            break
            
            top_diseases = diagnoses.exclude(
                DiseaseName__iexact='healthy'
            ).values('DiseaseName').annotate(
                count=Count('DiagnosisID')
            ).order_by('-count')[:10]
            
            top_diseases_list = []
            for item in top_diseases:
                top_diseases_list.append({
                    'name': item['DiseaseName'].replace('_', ' ').title(),
                    'count': item['count']
                })
            
            scans_by_crop = plants.values('CropType').annotate(
                count=Count('PlantID')
            ).order_by('-count')[:10]
            
            crops_list = []
            for item in scans_by_crop:
                crops_list.append({
                    'name': item['CropType'] or 'Unknown',
                    'count': item['count']
                })
            
            health_summary = {
                'total_scans': total_scans,
                'healthy': total_healthy,
                'diseased': total_diseases,
                'healthy_percentage': round((total_healthy / total_scans * 100), 1) if total_scans > 0 else 0,
                'diseased_percentage': round((total_diseases / total_scans * 100), 1) if total_scans > 0 else 0,
            }
            
            weekly_data = []
            for i in range(5, -1, -1):
                week_start = today - timedelta(days=i*7)
                week_end = week_start + timedelta(days=6)
                week_scans = plants.filter(
                    DateCaptured__date__gte=week_start,
                    DateCaptured__date__lte=week_end
                ).count()
                weekly_data.append({
                    'week_label': f"{week_start.strftime('%b %d')} - {week_end.strftime('%b %d')}",
                    'scans': week_scans
                })
            
            confidence_data = [
                {'range': '90-100%', 'count': diagnoses.filter(ConfidenceLevel__gte=0.9).count(), 'color': '#4CAF50'},
                {'range': '70-89%', 'count': diagnoses.filter(ConfidenceLevel__gte=0.7, ConfidenceLevel__lt=0.9).count(), 'color': '#8BC34A'},
                {'range': '50-69%', 'count': diagnoses.filter(ConfidenceLevel__gte=0.5, ConfidenceLevel__lt=0.7).count(), 'color': '#FFC107'},
                {'range': 'Below 50%', 'count': diagnoses.filter(ConfidenceLevel__lt=0.5).count(), 'color': '#FF9800'},
            ]
            
            diagnosed_with_feedback = diagnoses.filter(
                treatment_outcome__isnull=False
            ).exclude(treatment_outcome='')
            
            recovered = diagnosed_with_feedback.filter(treatment_outcome='recovered').count()
            no_change = diagnosed_with_feedback.filter(treatment_outcome='no_change').count()
            worsened = diagnosed_with_feedback.filter(treatment_outcome='worsened').count()
            
            recovery_rate = 0
            if diagnosed_with_feedback.count() > 0:
                recovery_rate = round((recovered / diagnosed_with_feedback.count()) * 100, 1)
            
            recovery_data = [
                {'label': 'Recovered', 'value': recovered, 'color': '#4CAF50'},
                {'label': 'No Change', 'value': no_change, 'color': '#FFC107'},
                {'label': 'Worsened', 'value': worsened, 'color': '#F44336'}
            ]
            
            severity_data = diagnoses.filter(
                severity__isnull=False
            ).exclude(severity='').values('severity').annotate(
                count=Count('DiagnosisID')
            )
            
            severity_map = {
                'mild': {'label': 'Mild', 'color': '#8BC34A'},
                'moderate': {'label': 'Moderate', 'color': '#FFC107'},
                'severe': {'label': 'Severe', 'color': '#F44336'}
            }
            
            severity_list = []
            for item in severity_data:
                sev = item['severity']
                if sev in severity_map:
                    severity_list.append({
                        'label': severity_map[sev]['label'],
                        'value': item['count'],
                        'color': severity_map[sev]['color']
                    })
            
            district_data = diagnoses.filter(
                PlantID__gps_district__isnull=False
            ).exclude(
                PlantID__gps_district=''
            ).values('PlantID__gps_district').annotate(
                count=Count('DiagnosisID')
            ).order_by('-count')[:10]
            
            district_list = []
            for item in district_data:
                district_list.append({
                    'district': item['PlantID__gps_district'],
                    'total': item['count']
                })
            
            crop_health = []
            for crop in scans_by_crop[:5]:
                crop_name = crop['CropType'] or 'Unknown'
                crop_plants = plants.filter(CropType=crop_name)
                crop_diagnoses = Diagnosis.objects.filter(PlantID__in=crop_plants)
                healthy_count = crop_diagnoses.filter(DiseaseName__iexact='healthy').count()
                diseased_count = crop_diagnoses.exclude(DiseaseName__iexact='healthy').count()
                total = healthy_count + diseased_count
                health_percentage = round((healthy_count / total * 100), 1) if total > 0 else 0
                
                crop_health.append({
                    'crop': crop_name,
                    'health_percentage': health_percentage
                })
            
            from django.db.models.functions import ExtractMonth
            
            seasonal_data = diagnoses.annotate(
                month=ExtractMonth('DateDiagnosed')
            ).values('month').annotate(
                count=Count('DiagnosisID')
            ).order_by('month')
            
            month_names = {
                1: 'Jan', 2: 'Feb', 3: 'Mar', 4: 'Apr',
                5: 'May', 6: 'Jun', 7: 'Jul', 8: 'Aug',
                9: 'Sep', 10: 'Oct', 11: 'Nov', 12: 'Dec'
            }
            
            seasonal_counts = []
            for item in seasonal_data:
                month_num = item['month']
                if month_num:
                    seasonal_counts.append({
                        'month': month_names.get(month_num, 'Unknown'),
                        'count': item['count']
                    })
            
            response_data = {
                'statistics': {
                    'total_scans': total_scans,
                    'total_diseases': total_diseases,
                    'total_healthy': total_healthy,
                    'unique_crops': len(crops_list),
                    'unique_diseases': len(top_diseases_list),
                    'recovery_rate': recovery_rate,
                    'healthy_percentage': health_summary['healthy_percentage'],
                    'diseased_percentage': health_summary['diseased_percentage'],
                },
                'charts': {
                    'trend_data': trend_data,
                    'top_diseases': top_diseases_list,
                    'scans_by_crop': crops_list,
                    'health_summary': health_summary,
                    'weekly_activity': weekly_data,
                    'confidence_distribution': confidence_data,
                    'recovery_data': recovery_data,
                    'severity_distribution': severity_list,
                    'district_distribution': district_list,
                    'crop_health_summary': crop_health,
                    'seasonal_patterns': seasonal_counts,
                }
            }
            
            logger.warning(f"Response generated successfully")
            return Response(response_data)
            
        except Exception as e:
            import traceback
            error_detail = traceback.format_exc()
            print(f"ERROR in FarmerInsightsTrendsView: {str(e)}")
            print(error_detail)
            return Response(
                {'error': str(e), 'detail': error_detail},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


# ── 14. ADMIN DASHBOARD LIST VIEWS ────────────────────────────────────────────

class FarmerListView(APIView):
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        if not request.user.is_staff:
            return Response({'error': 'Admin access required'}, status=403)
        
        farmers = Farmer.objects.all().values('id', 'username', 'email', 'first_name', 'last_name', 'district')
        return Response(list(farmers))


class TreatmentListView(APIView):
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        if not request.user.is_staff:
            return Response({'error': 'Admin access required'}, status=403)
        
        treatments = Treatment.objects.all().values('TreatmentID', 'DiseaseName', 'RecommendedPesticide')
        return Response(list(treatments))


class KnowledgeBaseListView(APIView):
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        if not request.user.is_staff:
            return Response({'error': 'Admin access required'}, status=403)
        
        entries = KnowledgeBase.objects.all().values('EntryID', 'DiseaseName')
        return Response(list(entries))


class DiagnosisListView(APIView):
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        if not request.user.is_staff:
            return Response({'error': 'Admin access required'}, status=403)
        
        try:
            diagnoses = Diagnosis.objects.all()
            
            result = []
            for d in diagnoses:
                result.append({
                    'DiagnosisID': d.DiagnosisID,
                    'DiseaseName': d.DiseaseName if d.DiseaseName else 'Unknown',
                    'ConfidenceLevel': float(d.ConfidenceLevel) if d.ConfidenceLevel is not None else 0.0,
                    'severity': d.severity if d.severity else 'Not specified',
                    'treatment_outcome': d.treatment_outcome if d.treatment_outcome else 'Pending',
                    'DateDiagnosed': d.DateDiagnosed.isoformat() if d.DateDiagnosed else None,
                })
            
            return Response(result)
            
        except Exception as e:
            import traceback
            print(f"DiagnosisListView error: {str(e)}")
            print(traceback.format_exc())
            return Response(
                {'error': f'Failed to load diagnoses: {str(e)}'},
                status=500
            )


class PlantListView(APIView):
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        if not request.user.is_staff:
            return Response({'error': 'Admin access required'}, status=403)
        
        plants = Plant.objects.all().values('PlantID', 'CropType', 'DateCaptured', 'gps_district')
        return Response(list(plants))





