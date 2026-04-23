# import dj_database_url
# import os
# from pathlib import Path
# from celery.schedules import crontab, solar
# from datetime import timedelta
# from corsheaders.defaults import default_headers

# BASE_DIR = Path(__file__).resolve().parent.parent
# SECRET_KEY = os.environ.get('DJANGO_SECRET_KEY', 'u)w*v%19nm644-q@xn791_ac_@jyi_%%w(-*#cnd%0e)z*@8ib')

# DEBUG = False

# # --- HOSTS ---
# ALLOWED_HOSTS = [
#     'farmaid-backend.onrender.com',
#     'localhost',
#     '127.0.0.1',
#     '10.0.2.2',
#     '.onrender.com',
#     '.render.com',
# ]

# # --- APPS ---
# INSTALLED_APPS = [
#     'jazzmin',
#     'django.contrib.admin',
#     'django.contrib.auth',
#     'django.contrib.contenttypes',
#     'django.contrib.sessions',
#     'django.contrib.messages',
#     'django.contrib.staticfiles',
#     'django.contrib.sites',

#     # 3rd Party
#     'rest_framework',
#     'rest_framework.authtoken',
#     'corsheaders',
#     'django_celery_beat',
#     'django_celery_results',
#     'allauth',
#     'allauth.account',
#     'allauth.socialaccount',
#     'allauth.socialaccount.providers.google',

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
#     'allauth.account.middleware.AccountMiddleware',
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
# DATABASE_URL = os.environ.get('DATABASE_URL', '')
# DATABASES = {
#     'default': dj_database_url.parse(DATABASE_URL)
# }

# # --- AUTHENTICATION ---
# AUTH_USER_MODEL = 'api.Farmer'

# AUTH_PASSWORD_VALIDATORS = [
#     {
#         'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
#         'OPTIONS': {'min_length': 8},
#     },
#     {
#         'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
#     },
#     {
#         'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
#     },
#     {
#         'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
#     },
#     {
#         'NAME': 'api.validators.NoCommonPasswordValidator',
#     },
#     {
#         'NAME': 'api.validators.PasswordStrengthValidator',
#     },
# ]

# AUTHENTICATION_BACKENDS = [
#     'django.contrib.auth.backends.ModelBackend',
#     'allauth.account.auth_backends.AuthenticationBackend',
# ]

# REST_FRAMEWORK = {
#     'DEFAULT_AUTHENTICATION_CLASSES': [
#         'rest_framework.authentication.TokenAuthentication',
#         'rest_framework.authentication.SessionAuthentication',
#     ],
# }

# # --- ALLAUTH CONFIGURATION ---
# SITE_ID = 1

# ACCOUNT_LOGIN_METHODS      = {'email'}
# ACCOUNT_SIGNUP_FIELDS      = ['email*', 'password1*', 'password2*']
# ACCOUNT_EMAIL_VERIFICATION = 'none'

# # ============================================================
# # GOOGLE OAUTH CONFIGURATION
# # ============================================================
# # IMPORTANT: GOOGLE_CLIENT_ID must be your WEB client ID from
# # Google Cloud Console → APIs & Services → Credentials →
# # "Web client (auto created by Google Service)"
# # It should look like: XXXXXXXXXX-xxxxxxxx.apps.googleusercontent.com
# # Add it as an environment variable on Render: GOOGLE_CLIENT_ID
# # ============================================================

# _GOOGLE_WEB_CLIENT_ID     = os.environ.get('GOOGLE_CLIENT_ID', '')
# _GOOGLE_WEB_CLIENT_SECRET = os.environ.get('GOOGLE_CLIENT_SECRET', '')

# # Used by allauth for social login
# SOCIALACCOUNT_PROVIDERS = {
#     'google': {
#         'SCOPE': ['profile', 'email'],
#         'AUTH_PARAMS': {'access_type': 'online'},
#         'APP': {
#             'client_id': _GOOGLE_WEB_CLIENT_ID,
#             'secret':    _GOOGLE_WEB_CLIENT_SECRET,
#             'key':       '',
#         },
#         # Allow token verification from both Web and Android client IDs
#         'OAUTH_PKCE_ENABLED': True,
#     }
# }

# # Used by your custom Google auth view (api/views.py)
# # Both names are provided so any view referencing either name will work
# GOOGLE_CLIENT_ID        = _GOOGLE_WEB_CLIENT_ID   # ← matches error "GOOGLE_CLIENT_ID not configured"
# GOOGLE_CLIENT_SECRET    = _GOOGLE_WEB_CLIENT_SECRET

# GOOGLE_OAUTH2_CLIENT_ID     = _GOOGLE_WEB_CLIENT_ID   # ← legacy name kept for compatibility
# GOOGLE_OAUTH2_CLIENT_SECRET = _GOOGLE_WEB_CLIENT_SECRET

# # List of allowed client IDs for token verification
# # Include both Web and Android client IDs so tokens from mobile are accepted
# GOOGLE_ALLOWED_CLIENT_IDS = [
#     _GOOGLE_WEB_CLIENT_ID,
#     # Android client ID — tokens issued to this audience are also valid
#     '40483998095-jtmsfnithmn4jr4r552mt5rqpvisn7qu.apps.googleusercontent.com',
# ]

# # --- CORS & SECURITY ---
# CORS_ALLOW_CREDENTIALS = True
# CORS_ALLOWED_ORIGIN_REGEXES = [
#     r"^http://localhost:\d+$",
#     r"^http://127\.0\.0\.1:\d+$",
#     r"^https?://.*\.onrender\.com$",
# ]
# CORS_ALLOWED_ORIGINS = [
#     "https://farmaid-backend.onrender.com",
#     "http://localhost:59464",
#     "http://localhost:8080",
#     "http://localhost:3000",
# ]
# CSRF_TRUSTED_ORIGINS = [
#     "http://localhost:62803",
#     "http://127.0.0.1",
#     "https://farmaid-backend.onrender.com",
# ]

# CORS_ALLOW_HEADERS = list(default_headers) + ['authorization', 'content-type', 'accept']
# APPEND_SLASH = True

# # ============================================================
# # EMAIL CONFIGURATION
# # ============================================================

# RENDER_EXTERNAL_URL = os.environ.get('RENDER_EXTERNAL_URL', 'https://farmaid-backend.onrender.com')
# RENDER_DOMAIN       = RENDER_EXTERNAL_URL.replace('https://', '').replace('http://', '')

# SITE_DOMAIN    = RENDER_DOMAIN
# SITE_PROTOCOL  = 'https'

# EMAIL_BACKEND       = 'django.core.mail.backends.smtp.EmailBackend'
# EMAIL_HOST          = 'smtp.gmail.com'
# EMAIL_PORT          = 587
# EMAIL_USE_TLS       = True
# EMAIL_HOST_USER     = os.environ.get('EMAIL_HOST_USER', 'ramokhelekeeke@gmail.com')
# EMAIL_HOST_PASSWORD = os.environ.get('EMAIL_HOST_PASSWORD', '')

# if EMAIL_HOST_USER:
#     DEFAULT_FROM_EMAIL = f'FarmAid Support <{EMAIL_HOST_USER}>'
#     SERVER_EMAIL       = DEFAULT_FROM_EMAIL
# else:
#     DEFAULT_FROM_EMAIL = 'noreply@farmaid.co.ls'
#     SERVER_EMAIL       = 'noreply@farmaid.co.ls'

# EMAIL_TIMEOUT = 30

# if RENDER_EXTERNAL_URL:
#     EMAIL_USE_TLS = True
#     EMAIL_PORT    = 587
#     if DEBUG:
#         EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'

# # --- TIMEZONE ---
# LANGUAGE_CODE = 'en-us'
# TIME_ZONE     = 'Africa/Maseru'
# USE_I18N      = True
# USE_TZ        = True

# # --- CELERY & REDIS ---
# CELERY_BROKER_URL        = os.environ.get('REDIS_URL', 'redis://localhost:6379/0')
# CELERY_RESULT_BACKEND    = 'django-db'
# CELERY_CACHE_BACKEND     = 'default'
# CELERY_ACCEPT_CONTENT    = ['json']
# CELERY_TASK_SERIALIZER   = 'json'
# CELERY_RESULT_SERIALIZER = 'json'
# CELERY_TIMEZONE          = 'Africa/Maseru'
# CELERY_ENABLE_UTC        = True

# CELERY_BEAT_SCHEDULER       = 'django_celery_beat.schedulers:DatabaseScheduler'
# CELERY_TASK_SOFT_TIME_LIMIT = 120
# CELERY_TASK_TIME_LIMIT      = 180
# CELERY_TASK_ACKS_LATE       = True

# CELERY_TASK_ROUTES = {
#     'api.tasks.sync_weather_and_generate_alerts': {'queue': 'weather'},
#     'api.tasks.send_followup_reminders':          {'queue': 'reminders'},
#     'api.tasks.send_market_price_alerts':         {'queue': 'market'},
# }

# CELERY_BEAT_SCHEDULE = {
#     'fetch-weather-every-12-hours': {
#         'task':     'api.tasks.sync_weather_and_generate_alerts',
#         'schedule': crontab(minute=0, hour='*/12'),
#         'options':  {'expires': 3600},
#     },
#     'followup-reminders-daily': {
#         'task':     'api.tasks.send_followup_reminders',
#         'schedule': crontab(minute=0, hour=7),
#     },
#     'market-alerts-daily': {
#         'task':     'api.tasks.send_market_price_alerts',
#         'schedule': crontab(minute=0, hour=8),
#     },
# }

# # --- STATIC & MEDIA ---
# STATIC_URL          = 'static/'
# STATIC_ROOT         = os.path.join(BASE_DIR, 'staticfiles')
# STATICFILES_STORAGE = 'whitenoise.storage.CompressedStaticFilesStorage'

# MEDIA_URL  = '/media/'
# MEDIA_ROOT = os.path.join(BASE_DIR, 'media')

# DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# # --- JAZZMIN SETTINGS ---
# JAZZMIN_SETTINGS = {
#     "site_title":   "FarmAid Admin",
#     "site_header":  "FarmAid",
#     "site_brand":   "FarmAid Management",
#     "welcome_sign": "FarmAid Management System",
#     "copyright":    "FarmAid Lesotho",

#     "topmenu_links": [
#         {
#             "name":        "Home",
#             "url":         "admin:index",
#             "permissions": ["auth.view_user"],
#         },
#         {
#             "name":  "Activity Log",
#             "model": "admin.LogEntry",
#         },
#         {
#             "name": "Sign Out",
#             "url":  "/admin/logout/",
#             "icon": "fas fa-sign-out-alt",
#         },
#     ],

#     "custom_links": {
#         "api": [
#             {
#                 "name":        "Knowledge Base",
#                 "url":         "admin:api_knowledgebase_changelist",
#                 "icon":        "fas fa-book-open",
#                 "permissions": ["api.view_knowledgebase"],
#             },
#             {
#                 "name":        "Translation Cache",
#                 "url":         "admin:api_translationcache_changelist",
#                 "icon":        "fas fa-language",
#                 "permissions": ["api.view_translationcache"],
#             },
#         ],
#     },

#     "show_sidebar":        True,
#     "navigation_expanded": True,

#     "icons": {
#         "admin.LogEntry":                      "fas fa-history",
#         "auth":                                "fas fa-users-cog",
#         "auth.Group":                          "fas fa-users",
#         "api.Farmer":                          "fas fa-user-tag",
#         "api.CropProfile":                     "fas fa-seedling",
#         "api.Plant":                           "fas fa-leaf",
#         "api.Diagnosis":                       "fas fa-stethoscope",
#         "api.Treatment":                       "fas fa-prescription-bottle-alt",
#         "api.AppAlert":                        "fas fa-bell",
#         "api.WeatherData":                     "fas fa-cloud-sun-rain",
#         "api.KnowledgeBase":                   "fas fa-book-open",
#         "api.AIModel":                         "fas fa-robot",
#         "api.TranslationCache":                "fas fa-language",
#         "api.FarmerInsight":                   "fas fa-chart-pie",
#         "api.GrowthJournalEntry":              "fas fa-journal-whills",
#         "django_celery_beat.PeriodicTask":     "fas fa-clock",
#         "django_celery_beat.CrontabSchedule":  "fas fa-calendar",
#         "django_celery_beat.IntervalSchedule": "fas fa-redo",
#         "django_celery_beat.SolarSchedule":    "fas fa-sun",
#         "django_celery_beat.ClockedSchedule":  "fas fa-hourglass",
#         "django_celery_results.TaskResult":    "fas fa-tasks",
#         "django_celery_results.GroupResult":   "fas fa-layer-group",
#         "account.EmailAddress":                "fas fa-envelope",
#         "socialaccount.SocialApp":             "fas fa-plug",
#         "socialaccount.SocialToken":           "fas fa-key",
#         "socialaccount.SocialAccount":         "fas fa-user-circle",
#     },

#     "order_with_respect_to": [
#         "api",
#         "api.Farmer",
#         "api.CropProfile",
#         "api.Plant",
#         "api.Diagnosis",
#         "api.Treatment",
#         "api.AppAlert",
#         "api.WeatherData",
#         "api.KnowledgeBase",
#         "api.TranslationCache",
#         "api.FarmerInsight",
#         "api.GrowthJournalEntry",
#         "django_celery_beat",
#         "django_celery_results",
#         "auth",
#         "account",
#         "socialaccount",
#     ],

#     "hide_apps":   [],
#     "hide_models": [],
# }

# JAZZMIN_UI_TWEAKS = {
#     "brand_colour":             "navbar-success",
#     "accent":                   "accent-teal",
#     "navbar":                   "navbar-dark",
#     "navbar_fixed":             True,
#     "sidebar_fixed":            True,
#     "sidebar":                  "sidebar-dark-success",
#     "sidebar_nav_child_indent": True,
#     "sidebar_nav_flat_style":   True,
#     "theme":                    "default",
# }

# LOGOUT_ON_GET      = True
# LOGIN_URL          = '/admin/login/'
# LOGIN_REDIRECT_URL = '/admin/'


import dj_database_url
import os
from pathlib import Path
from celery.schedules import crontab, solar
from datetime import timedelta
from corsheaders.defaults import default_headers

BASE_DIR = Path(__file__).resolve().parent.parent
SECRET_KEY = os.environ.get('DJANGO_SECRET_KEY', 'u)w*v%19nm644-q@xn791_ac_@jyi_%%w(-*#cnd%0e)z*@8ib')

DEBUG = False

# --- HOSTS ---
ALLOWED_HOSTS = [
    'farmaid-backend.onrender.com',
    'localhost',
    '127.0.0.1',
    '10.0.2.2',
    '.onrender.com',
    '.render.com',
]

# --- APPS ---
INSTALLED_APPS = [
    'jazzmin',
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'django.contrib.sites',

    # 3rd Party
    'rest_framework',
    'rest_framework.authtoken',
    'corsheaders',
    'django_celery_beat',
    'django_celery_results',
    'allauth',
    'allauth.account',
    'allauth.socialaccount',
    'allauth.socialaccount.providers.google',

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
    'allauth.account.middleware.AccountMiddleware',
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
DATABASE_URL = os.environ.get('DATABASE_URL', '')
DATABASES = {
    'default': dj_database_url.parse(DATABASE_URL)
}

# --- AUTHENTICATION ---
AUTH_USER_MODEL = 'api.Farmer'

AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
        'OPTIONS': {'min_length': 8},
    },
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
    {
        'NAME': 'api.validators.NoCommonPasswordValidator',
    },
    {
        'NAME': 'api.validators.PasswordStrengthValidator',
    },
]

AUTHENTICATION_BACKENDS = [
    'django.contrib.auth.backends.ModelBackend',
    'allauth.account.auth_backends.AuthenticationBackend',
]

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.TokenAuthentication',
        'rest_framework.authentication.SessionAuthentication',
    ],
}

# --- ALLAUTH CONFIGURATION ---
SITE_ID = 1

ACCOUNT_LOGIN_METHODS      = {'email'}
ACCOUNT_SIGNUP_FIELDS      = ['email*', 'password1*', 'password2*']
ACCOUNT_EMAIL_VERIFICATION = 'none'

# ============================================================
# GOOGLE OAUTH CONFIGURATION
# ============================================================

_GOOGLE_WEB_CLIENT_ID     = os.environ.get('GOOGLE_CLIENT_ID', '')
_GOOGLE_WEB_CLIENT_SECRET = os.environ.get('GOOGLE_CLIENT_SECRET', '')

SOCIALACCOUNT_PROVIDERS = {
    'google': {
        'SCOPE': ['profile', 'email'],
        'AUTH_PARAMS': {'access_type': 'online'},
        'APP': {
            'client_id': _GOOGLE_WEB_CLIENT_ID,
            'secret':    _GOOGLE_WEB_CLIENT_SECRET,
            'key':       '',
        },
        'OAUTH_PKCE_ENABLED': True,
    }
}

GOOGLE_CLIENT_ID        = _GOOGLE_WEB_CLIENT_ID
GOOGLE_CLIENT_SECRET    = _GOOGLE_WEB_CLIENT_SECRET
GOOGLE_OAUTH2_CLIENT_ID     = _GOOGLE_WEB_CLIENT_ID
GOOGLE_OAUTH2_CLIENT_SECRET = _GOOGLE_WEB_CLIENT_SECRET

GOOGLE_ALLOWED_CLIENT_IDS = [
    _GOOGLE_WEB_CLIENT_ID,
    '40483998095-jtmsfnithmn4jr4r552mt5rqpvisn7qu.apps.googleusercontent.com',
]

# ============================================================
# SITE CONFIGURATION FOR ACTIVATION EMAILS
# ============================================================

# Get the Render domain from environment variable
RENDER_EXTERNAL_URL = os.environ.get('RENDER_EXTERNAL_URL', 'https://farmaid-backend.onrender.com')
SITE_DOMAIN = RENDER_EXTERNAL_URL.replace('https://', '').replace('http://', '')
SITE_PROTOCOL = 'https'

# Force Django to use the correct domain for absolute URLs
USE_X_FORWARDED_HOST = True
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')

# Update Django Sites framework
try:
    from django.contrib.sites.models import Site
    current_site = Site.objects.get_current()
    current_site.domain = SITE_DOMAIN
    current_site.name = 'FarmAid Lesotho'
    current_site.save()
except Exception:
    pass

# ============================================================
# EMAIL CONFIGURATION
# ============================================================

EMAIL_BACKEND       = 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_HOST          = 'smtp.gmail.com'
EMAIL_PORT          = 587
EMAIL_USE_TLS       = True
EMAIL_HOST_USER     = os.environ.get('EMAIL_HOST_USER', 'ramokhelekeeke@gmail.com')
EMAIL_HOST_PASSWORD = os.environ.get('EMAIL_HOST_PASSWORD', '')

if EMAIL_HOST_USER:
    DEFAULT_FROM_EMAIL = f'FarmAid Support <{EMAIL_HOST_USER}>'
    SERVER_EMAIL       = DEFAULT_FROM_EMAIL
else:
    DEFAULT_FROM_EMAIL = 'noreply@farmaid.co.ls'
    SERVER_EMAIL       = 'noreply@farmaid.co.ls'

EMAIL_TIMEOUT = 30

if RENDER_EXTERNAL_URL:
    EMAIL_USE_TLS = True
    EMAIL_PORT    = 587
    if DEBUG:
        EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'

# --- CORS & SECURITY ---
CORS_ALLOW_CREDENTIALS = True
CORS_ALLOWED_ORIGIN_REGEXES = [
    r"^http://localhost:\d+$",
    r"^http://127\.0\.0\.1:\d+$",
    r"^https?://.*\.onrender\.com$",
]
CORS_ALLOWED_ORIGINS = [
    "https://farmaid-backend.onrender.com",
    "http://localhost:59464",
    "http://localhost:8080",
    "http://localhost:3000",
]
CSRF_TRUSTED_ORIGINS = [
    "http://localhost:62803",
    "http://127.0.0.1",
    "https://farmaid-backend.onrender.com",
]

CORS_ALLOW_HEADERS = list(default_headers) + ['authorization', 'content-type', 'accept']
APPEND_SLASH = True

# --- TIMEZONE ---
LANGUAGE_CODE = 'en-us'
TIME_ZONE     = 'Africa/Maseru'
USE_I18N      = True
USE_TZ        = True

# --- CELERY & REDIS ---
CELERY_BROKER_URL        = os.environ.get('REDIS_URL', 'redis://localhost:6379/0')
CELERY_RESULT_BACKEND    = 'django-db'
CELERY_CACHE_BACKEND     = 'default'
CELERY_ACCEPT_CONTENT    = ['json']
CELERY_TASK_SERIALIZER   = 'json'
CELERY_RESULT_SERIALIZER = 'json'
CELERY_TIMEZONE          = 'Africa/Maseru'
CELERY_ENABLE_UTC        = True

CELERY_BEAT_SCHEDULER       = 'django_celery_beat.schedulers:DatabaseScheduler'
CELERY_TASK_SOFT_TIME_LIMIT = 120
CELERY_TASK_TIME_LIMIT      = 180
CELERY_TASK_ACKS_LATE       = True

CELERY_TASK_ROUTES = {
    'api.tasks.sync_weather_and_generate_alerts': {'queue': 'weather'},
    'api.tasks.send_followup_reminders':          {'queue': 'reminders'},
    'api.tasks.send_market_price_alerts':         {'queue': 'market'},
}

CELERY_BEAT_SCHEDULE = {
    'fetch-weather-every-12-hours': {
        'task':     'api.tasks.sync_weather_and_generate_alerts',
        'schedule': crontab(minute=0, hour='*/12'),
        'options':  {'expires': 3600},
    },
    'followup-reminders-daily': {
        'task':     'api.tasks.send_followup_reminders',
        'schedule': crontab(minute=0, hour=7),
    },
    'market-alerts-daily': {
        'task':     'api.tasks.send_market_price_alerts',
        'schedule': crontab(minute=0, hour=8),
    },
}

# --- STATIC & MEDIA ---
STATIC_URL          = 'static/'
STATIC_ROOT         = os.path.join(BASE_DIR, 'staticfiles')
STATICFILES_STORAGE = 'whitenoise.storage.CompressedStaticFilesStorage'

MEDIA_URL  = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# --- JAZZMIN SETTINGS ---
JAZZMIN_SETTINGS = {
    "site_title":   "FarmAid Admin",
    "site_header":  "FarmAid",
    "site_brand":   "FarmAid Management",
    "welcome_sign": "FarmAid Management System",
    "copyright":    "FarmAid Lesotho",

    "topmenu_links": [
        {
            "name":        "Home",
            "url":         "admin:index",
            "permissions": ["auth.view_user"],
        },
        {
            "name":  "Activity Log",
            "model": "admin.LogEntry",
        },
        {
            "name": "Sign Out",
            "url":  "/admin/logout/",
            "icon": "fas fa-sign-out-alt",
        },
    ],

    "custom_links": {
        "api": [
            {
                "name":        "Knowledge Base",
                "url":         "admin:api_knowledgebase_changelist",
                "icon":        "fas fa-book-open",
                "permissions": ["api.view_knowledgebase"],
            },
            {
                "name":        "Translation Cache",
                "url":         "admin:api_translationcache_changelist",
                "icon":        "fas fa-language",
                "permissions": ["api.view_translationcache"],
            },
        ],
    },

    "show_sidebar":        True,
    "navigation_expanded": True,

    "icons": {
        "admin.LogEntry":                      "fas fa-history",
        "auth":                                "fas fa-users-cog",
        "auth.Group":                          "fas fa-users",
        "api.Farmer":                          "fas fa-user-tag",
        "api.CropProfile":                     "fas fa-seedling",
        "api.Plant":                           "fas fa-leaf",
        "api.Diagnosis":                       "fas fa-stethoscope",
        "api.Treatment":                       "fas fa-prescription-bottle-alt",
        "api.AppAlert":                        "fas fa-bell",
        "api.WeatherData":                     "fas fa-cloud-sun-rain",
        "api.KnowledgeBase":                   "fas fa-book-open",
        "api.AIModel":                         "fas fa-robot",
        "api.TranslationCache":                "fas fa-language",
        "api.FarmerInsight":                   "fas fa-chart-pie",
        "api.GrowthJournalEntry":              "fas fa-journal-whills",
        "django_celery_beat.PeriodicTask":     "fas fa-clock",
        "django_celery_beat.CrontabSchedule":  "fas fa-calendar",
        "django_celery_beat.IntervalSchedule": "fas fa-redo",
        "django_celery_beat.SolarSchedule":    "fas fa-sun",
        "django_celery_beat.ClockedSchedule":  "fas fa-hourglass",
        "django_celery_results.TaskResult":    "fas fa-tasks",
        "django_celery_results.GroupResult":   "fas fa-layer-group",
        "account.EmailAddress":                "fas fa-envelope",
        "socialaccount.SocialApp":             "fas fa-plug",
        "socialaccount.SocialToken":           "fas fa-key",
        "socialaccount.SocialAccount":         "fas fa-user-circle",
    },

    "order_with_respect_to": [
        "api",
        "api.Farmer",
        "api.CropProfile",
        "api.Plant",
        "api.Diagnosis",
        "api.Treatment",
        "api.AppAlert",
        "api.WeatherData",
        "api.KnowledgeBase",
        "api.TranslationCache",
        "api.FarmerInsight",
        "api.GrowthJournalEntry",
        "django_celery_beat",
        "django_celery_results",
        "auth",
        "account",
        "socialaccount",
    ],

    "hide_apps":   [],
    "hide_models": [],
}

JAZZMIN_UI_TWEAKS = {
    "brand_colour":             "navbar-success",
    "accent":                   "accent-teal",
    "navbar":                   "navbar-dark",
    "navbar_fixed":             True,
    "sidebar_fixed":            True,
    "sidebar":                  "sidebar-dark-success",
    "sidebar_nav_child_indent": True,
    "sidebar_nav_flat_style":   True,
    "theme":                    "default",
}

LOGOUT_ON_GET      = True
LOGIN_URL          = '/admin/login/'
LOGIN_REDIRECT_URL = '/admin/'
