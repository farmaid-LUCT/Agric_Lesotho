import dj_database_url
import os
from pathlib import Path
from celery.schedules import crontab, solar
from datetime import timedelta
from corsheaders.defaults import default_headers

BASE_DIR = Path(__file__).resolve().parent.parent
SECRET_KEY = os.environ.get('DJANGO_SECRET_KEY', 'u)w*v%19nm644-q@xn791_ac_@jyi_%%w(-*#cnd%0e)z*@8ib')

# Set to False in production
DEBUG = os.environ.get('DEBUG', 'False') == 'True'

# --- HOSTS ---
ALLOWED_HOSTS = [
    'farmaid-backend.onrender.com',
    'localhost',
    '127.0.0.1',
    '10.0.2.2', # Android Emulator Loopback
    '.onrender.com'
]

# --- APPS ---
INSTALLED_APPS = [
    'jazzmin',  # Must be before admin
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
    'corsheaders.middleware.CorsMiddleware',  # Must be first
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware', # After security, before everything else
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
DATABASE_URL = os.environ.get('DATABASE_URL', 'postgresql://neondb_owner:npg_Z46qfbzXJSuj@ep-long-credit-ahfpyg3c-pooler.c-3.us-east-1.aws.neon.tech/neondb?sslmode=require')
DATABASES = {
    'default': dj_database_url.parse(DATABASE_URL)
}

# --- AUTHENTICATION ---
AUTH_USER_MODEL = 'api.Farmer'

AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator', 'OPTIONS': {'min_length': 8}},
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
    {'NAME': 'api.validators.NoCommonPasswordValidator'},
    {'NAME': 'api.validators.PasswordStrengthValidator'},
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

# --- ALLAUTH (Modern Config) ---
SITE_ID = 1
ACCOUNT_LOGIN_METHODS = {'email'}
ACCOUNT_EMAIL_REQUIRED = True
ACCOUNT_USERNAME_REQUIRED = False
ACCOUNT_EMAIL_VERIFICATION = 'none'
ACCOUNT_ADAPTER = 'allauth.account.adapter.DefaultAccountAdapter'

SOCIALACCOUNT_PROVIDERS = {
    'google': {
        'SCOPE': ['profile', 'email'],
        'AUTH_PARAMS': {'access_type': 'online'},
        'APP': {
            'client_id': os.environ.get('GOOGLE_CLIENT_ID', ''),
            'secret':    os.environ.get('GOOGLE_CLIENT_SECRET', ''),
            'key':       '',
        },
    }
}

# --- CORS & SECURITY ---
CORS_ALLOW_ALL_ORIGINS = True  # Set to False and use ALLOWED_ORIGINS for strict production
CORS_ALLOW_CREDENTIALS = True

# Allows any local Flutter development port
CORS_ALLOWED_ORIGIN_REGEXES = [
    r"^http://localhost:\d+$",
    r"^http://127\.0\.0\.1:\d+$",
]

CSRF_TRUSTED_ORIGINS = [
    "http://localhost",
    "https://farmaid-backend.onrender.com"
]

CORS_ALLOW_HEADERS = list(default_headers) + [
    'authorization',
    'content-type',
    'accept',
    'origin',
    'x-requested-with',
]

APPEND_SLASH = True

# --- EMAIL ---
EMAIL_BACKEND       = 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_HOST          = 'smtp.gmail.com'
EMAIL_PORT          = 587
EMAIL_USE_TLS       = True
EMAIL_HOST_USER      = os.environ.get('EMAIL_HOST_USER', 'ramokhelekeeke@gmail.com')
EMAIL_HOST_PASSWORD = os.environ.get('EMAIL_HOST_PASSWORD', 'sxhgmmpsxhtzotyh')
DEFAULT_FROM_EMAIL  = 'FarmAid Support <ramokhelekeeke@gmail.com>'

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

# --- STATIC & MEDIA ---
STATIC_URL          = 'static/'
STATIC_ROOT         = os.path.join(BASE_DIR, 'staticfiles')
# WhiteNoise optimized for production
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'

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
    "show_sidebar": True,
    "navigation_expanded": True,
    "icons": {
        "auth": "fas fa-users-cog",
        "api.Farmer": "fas fa-user-tag",
        "api.Plant": "fas fa-leaf",
        "api.AppAlert": "fas fa-bell",
        "api.WeatherData": "fas fa-cloud-sun-rain",
    },
}

JAZZMIN_UI_TWEAKS = {
    "brand_colour": "navbar-success",
    "accent": "accent-teal",
    "navbar": "navbar-dark",
    "sidebar": "sidebar-dark-success",
}

LOGOUT_ON_GET = True
LOGIN_URL = '/admin/login/'
LOGIN_REDIRECT_URL = '/admin/'
