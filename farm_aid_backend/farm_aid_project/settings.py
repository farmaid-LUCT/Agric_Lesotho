

# import dj_database_url
# import os
# from pathlib import Path
# from celery.schedules import crontab
# from corsheaders.defaults import default_headers

# BASE_DIR = Path(__file__).resolve().parent.parent
# SECRET_KEY = os.environ.get('DJANGO_SECRET_KEY', 'u)w*v%19nm644-q@xn791_ac_@jyi_%%w(-*#cnd%0e)z*@8ib')

# DEBUG = os.environ.get('DEBUG', 'True') == 'True'

# # --- HOSTS ---
# ALLOWED_HOSTS = [
#     'farmaid-backend.onrender.com', 
#     'localhost:62803', 
#     '127.0.0.1', 
#     '10.0.2.2', 
#     '.onrender.com'
# ]

# # --- APPS ---
# INSTALLED_APPS = [
#     'jazzmin',  # Must be above admin
#     'django.contrib.admin',
#     'django.contrib.auth',
#     'django.contrib.contenttypes',
#     'django.contrib.sessions',
#     'django.contrib.messages',
#     'django.contrib.staticfiles', 
    
#     # 3rd Party
#     'rest_framework',
#     'rest_framework.authtoken',
#     'corsheaders', 
#     'django_celery_beat', 
    
#     # Your App
#     'api.apps.ApiConfig',
# ]

# # --- MIDDLEWARE ---
# MIDDLEWARE = [
#     'corsheaders.middleware.CorsMiddleware', 
#     'django.middleware.security.SecurityMiddleware',
#     'whitenoise.middleware.WhiteNoiseMiddleware', 
#     'django.contrib.sessions.middleware.SessionMiddleware',
#     'django.middleware.common.CommonMiddleware',
#     'django.middleware.csrf.CsrfViewMiddleware',
#     'django.contrib.auth.middleware.AuthenticationMiddleware',
#     'django.contrib.messages.middleware.MessageMiddleware',
#     'django.middleware.clickjacking.XFrameOptionsMiddleware',
# ]

# ROOT_URLCONF = 'farm_aid_project.urls'

# # --- TEMPLATES ---
# TEMPLATES = [
#     {
#         'BACKEND': 'django.template.backends.django.DjangoTemplates',
#         'DIRS': [os.path.join(BASE_DIR, 'templates')],
#         'APP_DIRS': True,
#         'OPTIONS': {
#             'context_processors': [
#                 'django.template.context_processors.debug',
#                 'django.template.context_processors.request',
#                 'django.contrib.auth.context_processors.auth',
#                 'django.contrib.messages.context_processors.messages',
#             ],
#         },
#     },
# ]

# WSGI_APPLICATION = 'farm_aid_project.wsgi.application'

# # --- DATABASE (Neon.tech) ---
# DATABASE_URL = os.environ.get('DATABASE_URL', 'postgresql://neondb_owner:npg_Z46qfbzXJSuj@ep-long-credit-ahfpyg3c-pooler.c-3.us-east-1.aws.neon.tech/neondb?sslmode=require')
# DATABASES = {
#     'default': dj_database_url.parse(DATABASE_URL)
# }

# # --- AUTHENTICATION ---
# AUTH_USER_MODEL = 'api.Farmer'

# REST_FRAMEWORK = {
#     'DEFAULT_AUTHENTICATION_CLASSES': [
#         'rest_framework.authentication.TokenAuthentication',
#         'rest_framework.authentication.SessionAuthentication', 
#     ],
# }

# # --- CORS & SECURITY ---
# CORS_ALLOW_CREDENTIALS = True
# # Added common dev ports for Flutter Web
# CORS_ALLOWED_ORIGIN_REGEXES = [
#     r"^http://localhost:\d+$",
#     r"^http://127.0.0.1:\d+$",
# ]
# CORS_ALLOWED_ORIGINS = [
#     "https://farmaid-backend.onrender.com",
#     "http://localhost:59464", # Added your specific port
# ]
# CSRF_TRUSTED_ORIGINS = [
#     "http://localhost:62803",
#     "http://127.0.0.1",
#     "https://farmaid-backend.onrender.com"
# ]

# # Explicitly allow Authorization header for token auth
# CORS_ALLOW_HEADERS = list(default_headers) + ['authorization']

# APPEND_SLASH = True # Set to True to prevent 404s with trailing slashes

# # --- EMAIL ---
# EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
# EMAIL_HOST = 'smtp.gmail.com'
# EMAIL_PORT = 587
# EMAIL_USE_TLS = True
# EMAIL_HOST_USER = 'ramokhelekeeke@gmail.com'
# EMAIL_HOST_PASSWORD = 'sxhgmmpsxhtzotyh' 
# DEFAULT_FROM_EMAIL = 'FarmAid Support <ramokhelekeeke@gmail.com>'

# # --- TIMEZONE ---
# LANGUAGE_CODE = 'en-us'
# TIME_ZONE = 'Africa/Maseru'
# USE_I18N = True
# USE_TZ = True

# # --- CELERY & REDIS ---
# CELERY_BROKER_URL = os.environ.get('REDIS_URL', 'redis://localhost:6379/0')
# CELERY_RESULT_BACKEND = os.environ.get('REDIS_URL', 'redis://localhost:6379/0')
# CELERY_ACCEPT_CONTENT = ['json']
# CELERY_TASK_SERIALIZER = 'json'
# CELERY_RESULT_SERIALIZER = 'json'
# CELERY_TIMEZONE = 'Africa/Maseru'
# CELERY_BEAT_SCHEDULER = 'django_celery_beat.schedulers:DatabaseScheduler'

# CELERY_BEAT_SCHEDULE = {
#     'fetch-weather-every-12-hours': {
#         'task': 'api.tasks.sync_weather_and_generate_alerts',
#         'schedule': crontab(minute=0, hour='*/12'),  
#     },
# }

# # --- STATIC & MEDIA ---
# STATIC_URL = 'static/'
# STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles') 
# STATICFILES_STORAGE = 'whitenoise.storage.CompressedStaticFilesStorage'

# MEDIA_URL = '/media/'
# MEDIA_ROOT = os.path.join(BASE_DIR, 'media')

# DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# # --- JAZZMIN SETTINGS ---
# JAZZMIN_SETTINGS = {
#     "site_title": "FarmAid Admin",
#     "site_header": "FarmAid",
#     "site_brand": "FarmAid Management",
#     "welcome_sign": "FarmAid Management System",
#     "copyright": "FarmAid Lesotho",
#     "topmenu_links": [
#         {"name": "Home",  "url": "admin:index", "permissions": ["auth.view_user"]},
#         {"name": "Activity Log", "model": "admin.LogEntry"},
#         {"name": "Sign Out", "url": "/admin/logout/", "icon": "fas fa-sign-out-alt"},
#     ],
#     "show_sidebar": True,
#     "navigation_expanded": True,
#     "icons": {
#         "admin.LogEntry": "fas fa-history",
#         "auth": "fas fa-users-cog",
#         "api.Farmer": "fas fa-user-tag",
#         "api.Plant": "fas fa-leaf",
#         "api.AppAlert": "fas fa-bell",
#         "api.PersonalizedRule": "fas fa-gavel",
#     },
# }

# JAZZMIN_UI_TWEAKS = {
#     "brand_colour": "navbar-success",
#     "accent": "accent-teal",
#     "navbar": "navbar-dark",
#     "navbar_fixed": True,
#     "sidebar_fixed": True,
#     "sidebar": "sidebar-dark-success",
#     "sidebar_nav_child_indent": True,
#     "sidebar_nav_flat_style": True,
#     "theme": "default",
# }

# LOGOUT_ON_GET = True
# LOGIN_URL = '/admin/login/'
# LOGIN_REDIRECT_URL = '/admin/'


import dj_database_url
import os
from pathlib import Path
from celery.schedules import crontab, solar   # ← added solar for sunrise events
from datetime import timedelta                 # ← added for beat schedule options
from corsheaders.defaults import default_headers

BASE_DIR = Path(__file__).resolve().parent.parent
SECRET_KEY = os.environ.get('DJANGO_SECRET_KEY', 'u)w*v%19nm644-q@xn791_ac_@jyi_%%w(-*#cnd%0e)z*@8ib')

DEBUG = os.environ.get('DEBUG', 'True') == 'True'

# --- HOSTS ---
ALLOWED_HOSTS = [
    'farmaid-backend.onrender.com',
    'localhost:62803',
    '127.0.0.1',
    '10.0.2.2',
    '.onrender.com'
]

# --- APPS ---
INSTALLED_APPS = [
    'jazzmin',  # Must be above admin
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'django.contrib.sites',               # NEW — required by allauth

    # 3rd Party
    'rest_framework',
    'rest_framework.authtoken',
    'corsheaders',
    'django_celery_beat',
    'django_celery_results',              # NEW — stores Celery task results in Neon DB
    'allauth',                            # NEW — social login framework
    'allauth.account',                    # NEW
    'allauth.socialaccount',              # NEW
    'allauth.socialaccount.providers.google',  # NEW — Google OAuth provider

    # Your App
    'api.apps.ApiConfig',
]

# --- MIDDLEWARE ---
MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
    'allauth.account.middleware.AccountMiddleware',  # NEW — required by allauth
]

ROOT_URLCONF = 'farm_aid_project.urls'

# --- TEMPLATES ---
TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [os.path.join(BASE_DIR, 'templates')],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'farm_aid_project.wsgi.application'

# --- DATABASE (Neon.tech) ---
DATABASE_URL = os.environ.get('DATABASE_URL', 'postgresql://neondb_owner:npg_Z46qfbzXJSuj@ep-long-credit-ahfpyg3c-pooler.c-3.us-east-1.aws.neon.tech/neondb?sslmode=require')
DATABASES = {
    'default': dj_database_url.parse(DATABASE_URL)
}

# --- AUTHENTICATION ---
AUTH_USER_MODEL = 'api.Farmer'

# NEW — Password strength validators
# Rejects weak passwords like "12345", "password", all-lowercase, no special chars
AUTH_PASSWORD_VALIDATORS = [
    {
        # Minimum 8 characters
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
        'OPTIONS': {'min_length': 8},
    },
    {
        # Rejects passwords similar to farmer's email or name
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        # Rejects Django's built-in list of 20,000 common passwords
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        # Rejects all-numeric passwords e.g. "12345678"
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
    {
        # Custom: rejects farming-context weak passwords (maseru, farmer, lesotho…)
        'NAME': 'api.validators.NoCommonPasswordValidator',
    },
    {
        # Custom: enforces uppercase + lowercase + digit + special character
        'NAME': 'api.validators.PasswordStrengthValidator',
    },
]

# NEW — Authentication backends (keeps token auth + adds Google Sign-In)
AUTHENTICATION_BACKENDS = [
    # Standard username/password — keeps your existing DRF token auth working
    'django.contrib.auth.backends.ModelBackend',
    # Allauth backend — required for Google Sign-In
    'allauth.account.auth_backends.AuthenticationBackend',
]

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.TokenAuthentication',
        'rest_framework.authentication.SessionAuthentication',
    ],
}

# NEW — Allauth configuration
# SITE_ID=1 requires the sites table to have a row with id=1.
# Run the setup command in SETUP STEPS below after migrating.
SITE_ID = 1

ACCOUNT_EMAIL_REQUIRED        = True
ACCOUNT_USERNAME_REQUIRED     = False
ACCOUNT_AUTHENTICATION_METHOD = 'email'
ACCOUNT_EMAIL_VERIFICATION    = 'none'   # FarmAid handles its own email verification

SOCIALACCOUNT_PROVIDERS = {
    'google': {
        'SCOPE': ['profile', 'email'],
        'AUTH_PARAMS': {'access_type': 'online'},
        'APP': {
            # ── Get these values from https://console.cloud.google.com ──
            # Steps:
            #   1. APIs & Services → Credentials → Create OAuth 2.0 Client ID
            #   2. Application type: Web application
            #   3. Add authorised redirect URI:
            #      https://farmaid-backend.onrender.com/accounts/google/login/callback/
            #   4. Copy Client ID and Secret into your Render environment variables
            'client_id': os.environ.get('GOOGLE_CLIENT_ID', ''),
            'secret':    os.environ.get('GOOGLE_CLIENT_SECRET', ''),
            'key':       '',
        },
    }
}

# --- CORS & SECURITY ---
CORS_ALLOW_CREDENTIALS = True
CORS_ALLOWED_ORIGIN_REGEXES = [
    r"^http://localhost:\d+$",
    r"^http://127.0.0.1:\d+$",
]
CORS_ALLOWED_ORIGINS = [
    "https://farmaid-backend.onrender.com",
    "http://localhost:59464",
]
CSRF_TRUSTED_ORIGINS = [
    "http://localhost:62803",
    "http://127.0.0.1",
    "https://farmaid-backend.onrender.com"
]

CORS_ALLOW_HEADERS = list(default_headers) + ['authorization']
APPEND_SLASH = True

# --- EMAIL ---
EMAIL_BACKEND       = 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_HOST          = 'smtp.gmail.com'
EMAIL_PORT          = 587
EMAIL_USE_TLS       = True
EMAIL_HOST_USER     = os.environ.get('EMAIL_HOST_USER', 'ramokhelekeeke@gmail.com')
EMAIL_HOST_PASSWORD = os.environ.get('EMAIL_HOST_PASSWORD', 'sxhgmmpsxhtzotyh')
DEFAULT_FROM_EMAIL  = 'FarmAid Support <ramokhelekeeke@gmail.com>'

# --- TIMEZONE ---
LANGUAGE_CODE = 'en-us'
TIME_ZONE     = 'Africa/Maseru'
USE_I18N      = True
USE_TZ        = True

# --- CELERY & REDIS ---
CELERY_BROKER_URL        = os.environ.get('REDIS_URL', 'redis://localhost:6379/0')
CELERY_RESULT_BACKEND    = 'django-db'      # stores results in Neon DB (django_celery_results)
CELERY_CACHE_BACKEND     = 'default'
CELERY_ACCEPT_CONTENT    = ['json']
CELERY_TASK_SERIALIZER   = 'json'
CELERY_RESULT_SERIALIZER = 'json'
CELERY_TIMEZONE          = 'Africa/Maseru'
CELERY_ENABLE_UTC        = True

# DatabaseScheduler — lets you create/edit/pause schedules from Django admin
CELERY_BEAT_SCHEDULER = 'django_celery_beat.schedulers:DatabaseScheduler'

# Safety limits — prevents hung tasks from blocking workers
CELERY_TASK_SOFT_TIME_LIMIT = 120    # raises SoftTimeLimitExceeded after 2 min
CELERY_TASK_TIME_LIMIT      = 180    # hard kill after 3 min
CELERY_TASK_ACKS_LATE       = True   # re-queue task if worker crashes mid-run

# Named queues — separate weather, reminder and market workloads
CELERY_TASK_ROUTES = {
    'api.tasks.sync_weather_and_generate_alerts': {'queue': 'weather'},
    'api.tasks.send_followup_reminders':          {'queue': 'reminders'},
    'api.tasks.send_market_price_alerts':         {'queue': 'market'},
}

CELERY_BEAT_SCHEDULE = {

    # ── Weather sync every 12 hours (your original interval, kept) ────────
    'fetch-weather-every-12-hours': {
        'task':     'api.tasks.sync_weather_and_generate_alerts',
        'schedule': crontab(minute=0, hour='*/12'),
        'options':  {'expires': 3600},
    },

    # ── Solar event — sync at Maseru sunrise ──────────────────────────────
    # Requires: pip install ephem
    # Maseru coordinates: lat = -29.31, lon = 27.48
    # Uncomment after running:  pip install ephem
    # 'sunrise-weather-maseru': {
    #     'task':     'api.tasks.sync_weather_and_generate_alerts',
    #     'schedule': solar('sunrise', -29.31, 27.48),
    #     'options':  {'expires': 1800},
    # },

    # ── Follow-up crop reminders — 07:00 every morning ───────────────────
    'followup-reminders-daily': {
        'task':     'api.tasks.send_followup_reminders',
        'schedule': crontab(minute=0, hour=7),
    },

    # ── Market price alerts — 08:00 every morning ────────────────────────
    'market-alerts-daily': {
        'task':     'api.tasks.send_market_price_alerts',
        'schedule': crontab(minute=0, hour=8),
    },
}

# --- STATIC & MEDIA ---
STATIC_URL        = 'static/'
STATIC_ROOT       = os.path.join(BASE_DIR, 'staticfiles')
STATICFILES_STORAGE = 'whitenoise.storage.CompressedStaticFilesStorage'

MEDIA_URL  = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# --- JAZZMIN SETTINGS ---
JAZZMIN_SETTINGS = {
    "site_title": "FarmAid Admin",
    "site_header": "FarmAid",
    "site_brand": "FarmAid Management",
    "welcome_sign": "FarmAid Management System",
    "copyright": "FarmAid Lesotho",
    "topmenu_links": [
        {"name": "Home",  "url": "admin:index", "permissions": ["auth.view_user"]},
        {"name": "Activity Log", "model": "admin.LogEntry"},
        {"name": "Sign Out", "url": "/admin/logout/", "icon": "fas fa-sign-out-alt"},
    ],
    "show_sidebar": True,
    "navigation_expanded": True,
    "icons": {
        "admin.LogEntry":        "fas fa-history",
        "auth":                  "fas fa-users-cog",
        "api.Farmer":            "fas fa-user-tag",
        "api.Plant":             "fas fa-leaf",
        "api.AppAlert":          "fas fa-bell",
        "api.PersonalizedRule":  "fas fa-gavel",
        "django_celery_beat.PeriodicTask": "fas fa-clock",      # NEW
        "django_celery_beat.CrontabSchedule": "fas fa-calendar", # NEW
        "django_celery_beat.IntervalSchedule": "fas fa-redo",    # NEW
        "django_celery_beat.SolarSchedule": "fas fa-sun",        # NEW
    },
}

JAZZMIN_UI_TWEAKS = {
    "brand_colour": "navbar-success",
    "accent": "accent-teal",
    "navbar": "navbar-dark",
    "navbar_fixed": True,
    "sidebar_fixed": True,
    "sidebar": "sidebar-dark-success",
    "sidebar_nav_child_indent": True,
    "sidebar_nav_flat_style": True,
    "theme": "default",
}

LOGOUT_ON_GET     = True
LOGIN_URL         = '/admin/login/'
LOGIN_REDIRECT_URL = '/admin/'


# =============================================================================
# SETUP STEPS — run these once after saving this file
# =============================================================================
#
# 1. Install new packages:
#    pip install django-allauth google-auth django-celery-results ephem
#
# 2. Run migrations (allauth + celery-results create new tables):
#    python manage.py migrate
#
# 3. Create the required Sites record (allauth needs SITE_ID=1 in the DB):
#    python manage.py shell -c "
#    from django.contrib.sites.models import Site
#    Site.objects.update_or_create(
#        id=1,
#        defaults={
#            'domain': 'farmaid-backend.onrender.com',
#            'name':   'FarmAid Lesotho'
#        }
#    )
#    print('Site created.')
#    "
#
# 4. Add to Render environment variables:
#    GOOGLE_CLIENT_ID      = <from Google Cloud Console>
#    GOOGLE_CLIENT_SECRET  = <from Google Cloud Console>
#    EMAIL_HOST_USER       = ramokhelekeeke@gmail.com
#    EMAIL_HOST_PASSWORD   = <your app password>
#
# 5. Add these 6 new files into your api/ folder:
#    api/validators.py
#    api/tasks.py          (replaces existing)
#    api/signals.py        (replaces existing)
#    api/views_auth_patch.py
#    api/views_alerts_patch.py
#
# 6. Edit farm_aid_project/urls.py — add:
#    from django.urls import path, include
#    urlpatterns += [
#        path('accounts/', include('allauth.urls')),   # Google OAuth callback
#    ]
#
# 7. Edit api/urls.py — add these imports and paths:
#    from .views_auth_patch  import google_auth, register_farmer, change_password
#    from .views_alerts_patch import FarmerAlertsView, AlertCountView
#
#    path('auth/google/',          google_auth,              name='google-auth'),
#    path('alerts/unread-count/',  AlertCountView.as_view(), name='alerts-unread-count'),
#
# 8. Start the Beat process on Render (THIS WAS THE MISSING PIECE):
#    Add a second Background Worker service on Render with this command:
#    celery -A farm_aid_project beat -l info \
#      --scheduler django_celery_beat.schedulers:DatabaseScheduler
#
#    Local development (3 terminals):
#      Terminal 1: redis-server
#      Terminal 2: celery -A farm_aid_project worker -l info -Q default,weather,reminders,market
#      Terminal 3: celery -A farm_aid_project beat -l info \
#                    --scheduler django_celery_beat.schedulers:DatabaseScheduler
# =============================================================================
