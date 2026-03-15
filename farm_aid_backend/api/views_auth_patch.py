"""
views_auth_patch.py — FarmAid Lesotho
========================================
DROP-IN REPLACEMENTS for the authentication views in views.py.

Changes:
  1. register_farmer  — runs Django password validators before creating user
  2. login_farmer     — unchanged (shown for reference)
  3. google_auth      — NEW: Google Sign-In via ID token (works with Flutter
                        google_sign_in package + allauth social account backend)

DEPENDENCIES:
  pip install django-allauth google-auth

INSTALLED_APPS (settings.py):
  'allauth',
  'allauth.account',
  'allauth.socialaccount',
  'allauth.socialaccount.providers.google',

AUTHENTICATION_BACKENDS (settings.py):
  [
    'django.contrib.auth.backends.ModelBackend',
    'allauth.account.auth_backends.AuthenticationBackend',
  ]

SOCIALACCOUNT_PROVIDERS (settings.py):
  {
    'google': {
        'SCOPE': ['profile', 'email'],
        'AUTH_PARAMS': {'access_type': 'online'},
        'APP': {
            'client_id': '<YOUR_GOOGLE_CLIENT_ID>',
            'secret':    '<YOUR_GOOGLE_CLIENT_SECRET>',
            'key':       '',
        },
    }
  }

urls.py additions:
  path('auth/google/',         google_auth,           name='google-auth'),
  path('accounts/', include('allauth.urls')),
"""

from rest_framework import status
from rest_framework.response import Response
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.authtoken.models import Token
from django.contrib.auth import authenticate
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError


# ── helpers ──────────────────────────────────────────────────────────────────

def _token_response(user):
    """Return the standard token payload."""
    token, _ = Token.objects.get_or_create(user=user)
    return {
        "token":      token.key,
        "farmerName": f"{user.first_name} {user.last_name}".strip() or user.email,
        "is_staff":   user.is_staff,
        "email":      user.email,
    }


# ── 1. REGISTER (with password strength validation) ──────────────────────────

@api_view(["POST"])
@permission_classes([AllowAny])
def register_farmer(request):
    """
    POST /api/register/
    Required fields: email, password, first_name, last_name
    Optional: phone_number, district, language_preferences
    """
    data = request.data

    # ── a. Duplicate email check ──────────────────────────────────────────
    from .models import Farmer
    if Farmer.objects.filter(email=data.get("email", "").lower()).exists():
        return Response({"error": "An account with this email already exists."},
                        status=status.HTTP_400_BAD_REQUEST)

    # ── b. Password strength validation ──────────────────────────────────
    raw_password = data.get("password", "")
    try:
        # validate_password runs ALL validators in AUTH_PASSWORD_VALIDATORS
        # including our custom NoCommonPasswordValidator + PasswordStrengthValidator
        validate_password(raw_password)
    except ValidationError as exc:
        # Return each validation message as a readable list
        return Response(
            {"error": "Password is too weak.", "details": list(exc.messages)},
            status=status.HTTP_400_BAD_REQUEST,
        )

    # ── c. Create user (inactive until email verified) ───────────────────
    try:
        user = Farmer.objects.create_user(
            username=data.get("email", "").lower(),
            email=data.get("email", "").lower(),
            password=raw_password,
            first_name=data.get("first_name", ""),
            last_name=data.get("last_name", ""),
            phone_number=data.get("phone_number", ""),
            district=data.get("district", "") or data.get("location", ""),
            language_preferences=data.get("language_preferences", "en"),
        )
        user.is_active = False
        user.save()

        # Send activation email (imported from original views.py)
        from .views import send_activation_email
        send_activation_email(request, user)

        return Response(
            {
                "status":  "success",
                "message": "Verification email sent. Please check your inbox.",
                "email":   user.email,
            },
            status=status.HTTP_201_CREATED,
        )
    except Exception as exc:
        return Response({"error": str(exc)},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ── 2. CHANGE PASSWORD (with strength validation) ────────────────────────────

@api_view(["POST"])
@permission_classes([IsAuthenticated])
def change_password(request):
    """
    POST /api/auth/change-password/
    Body: { old_password, new_password }
    """
    user = request.user
    if not user.check_password(request.data.get("old_password", "")):
        return Response({"error": "Incorrect current password."}, status=400)

    new_pw = request.data.get("new_password", "")
    try:
        validate_password(new_pw, user=user)
    except ValidationError as exc:
        return Response(
            {"error": "New password is too weak.", "details": list(exc.messages)},
            status=400,
        )

    user.set_password(new_pw)
    user.save()
    # Re-issue token so the Flutter app stays logged in
    Token.objects.filter(user=user).delete()
    token, _ = Token.objects.get_or_create(user=user)
    return Response({"status": "success", "message": "Password updated!", "token": token.key})


# ── 3. GOOGLE SIGN-IN ─────────────────────────────────────────────────────────

@api_view(["POST"])
@permission_classes([AllowAny])
def google_auth(request):
    """
    POST /api/auth/google/
    Body: { "id_token": "<Google ID token from Flutter google_sign_in>" }

    Flow:
      1. Verify the Google ID token with Google's API.
      2. Get or create a Farmer account linked to the Google email.
      3. Return a DRF Token (same format as normal login).

    Flutter usage:
      final googleUser = await GoogleSignIn().signIn();
      final auth = await googleUser.authentication;
      // Send auth.idToken to this endpoint
    """
    from google.oauth2 import id_token as google_id_token
    from google.auth.transport import requests as google_requests
    from .models import Farmer

    id_token_str = request.data.get("id_token", "")
    if not id_token_str:
        return Response({"error": "id_token is required."}, status=400)

    # ── Verify token with Google ──────────────────────────────────────────
    try:
        from django.conf import settings
        CLIENT_ID = (
            settings.SOCIALACCOUNT_PROVIDERS
            .get("google", {})
            .get("APP", {})
            .get("client_id", "")
        )
        id_info = google_id_token.verify_oauth2_token(
            id_token_str,
            google_requests.Request(),
            CLIENT_ID,
        )
    except ValueError as exc:
        return Response({"error": f"Invalid Google token: {exc}"}, status=401)

    email      = id_info.get("email", "").lower()
    first_name = id_info.get("given_name", "")
    last_name  = id_info.get("family_name", "")
    photo_url  = id_info.get("picture", "")

    if not email:
        return Response({"error": "Google account has no email address."}, status=400)

    # ── Get or create farmer ──────────────────────────────────────────────
    user, created = Farmer.objects.get_or_create(
        email=email,
        defaults={
            "username":   email,
            "first_name": first_name,
            "last_name":  last_name,
            "is_active":  True,   # Google already verified the email
        },
    )

    if created:
        # Set an unusable password — they log in via Google only
        user.set_unusable_password()
        if photo_url:
            user.profile_photo_url = photo_url
        user.save()
    elif not user.is_active:
        # Account existed but was deactivated — reactivate via Google
        user.is_active = True
        user.save()

    return Response(_token_response(user), status=200)
