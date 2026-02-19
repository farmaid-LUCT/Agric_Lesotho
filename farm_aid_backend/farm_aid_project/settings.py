# import dj_database_url
# import os
# from pathlib import Path
# from celery.schedules import crontab

# BASE_DIR = Path(__file__).resolve().parent.parent
# SECRET_KEY = 'u)w*v%19nm644-q@xn791_ac_@jyi_%%w(-*#cnd%0e)z*@8ib' 

# # Set DEBUG to False for production! 
# DEBUG = True

# ALLOWED_HOSTS = ['farmaid-backend.onrender.com', 'localhost', '127.0.0.1', '*']

# # --- APPS CONFIGURATION ---
# INSTALLED_APPS = [
#     'jazzmin',           # ✅ ADDED: Must be above admin
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
# WSGI_APPLICATION = 'farm_aid_project.wsgi.application'

# TEMPLATES = [
#     {
#         'BACKEND': 'django.template.backends.django.DjangoTemplates',
#         'DIRS': [],
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

# # --- DATABASE (Neon.tech) ---
# DATABASES = {
#     'default': dj_database_url.parse('postgresql://neondb_owner:npg_Z46qfbzXJSuj@ep-long-credit-ahfpyg3c-pooler.c-3.us-east-1.aws.neon.tech/neondb?sslmode=require')
# }

# # --- AUTHENTICATION ---
# AUTH_USER_MODEL = 'api.Farmer'

# REST_FRAMEWORK = {
#     'DEFAULT_AUTHENTICATION_CLASSES': [
#         'rest_framework.authentication.TokenAuthentication',
#         'rest_framework.authentication.SessionAuthentication', 
#     ],
# }

# # --- EMAIL CONFIGURATION ---
# EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
# EMAIL_HOST = 'smtp.gmail.com'
# EMAIL_PORT = 587
# EMAIL_USE_TLS = True
# EMAIL_HOST_USER = 'ramokhelekeeke@gmail.com'
# EMAIL_HOST_PASSWORD = 'sxhgmmpsxhtzotyh' 
# DEFAULT_FROM_EMAIL = 'FarmAid Support <ramokhelekeeke@gmail.com>'

# # --- TIMEZONE & LOCALIZATION ---
# LANGUAGE_CODE = 'en-us'
# TIME_ZONE = 'Africa/Maseru'
# USE_I18N = True
# USE_TZ = True

# # --- CELERY & REDIS CONFIGURATION ---
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

# # --- CORS & SECURITY SETTINGS ---
# CORS_ALLOW_ALL_ORIGINS = True 
# CORS_ALLOW_CREDENTIALS = True
# CSRF_TRUSTED_ORIGINS = [
#     "http://localhost", 
#     "http://127.0.0.1", 
#     "https://farmaid-backend.onrender.com" 
# ]

# # --- STATIC & MEDIA STORAGE ---
# STATIC_URL = 'static/'
# STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles') 
# STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'

# MEDIA_URL = '/media/'
# MEDIA_ROOT = os.path.join(BASE_DIR, 'media')

# DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# # --- JAZZMIN SETTINGS (UI POLISH) ---
# JAZZMIN_SETTINGS = {
#     "site_title": "FarmAid Admin",
#     "site_header": "FarmAid",
#     "site_brand": "FarmAid Management",
#     "welcome_sign": "Welcome to the FarmAid Admin Portal",
#     "copyright": "FarmAid Lesotho",
#     "user_avatar": None,
#     "topmenu_links": [
#         {"name": "Home",  "url": "admin:index", "permissions": ["auth.view_user"]},
#         {"model": "api.Farmer"},
#     ],
#     "show_sidebar": True,
#     "navigation_expanded": True,
#     "icons": {
#         "auth": "fas fa-users-cog",
#         "auth.user": "fas fa-user",
#         "api.Farmer": "fas fa-seedling",
#         "api.Plant": "fas fa-leaf",
#         "api.Alert": "fas fa-bell",
#     },
# }

# JAZZMIN_UI_TWEAKS = {
#     "navbar_small_text": False,
#     "footer_small_text": False,
#     "body_small_text": False,
#     "brand_small_text": False,
#     "brand_colour": "navbar-success",
#     "accent": "accent-teal",
#     "navbar": "navbar-dark",
#     "no_navbar_border": False,
#     "navbar_fixed": False,
#     "layout_boxed": False,
#     "footer_fixed": False,
#     "sidebar_fixed": False,
#     "sidebar": "sidebar-dark-success",
#     "sidebar_nav_small_text": False,
#     "sidebar_disable_expand": False,
#     "sidebar_nav_child_indent": False,
#     "sidebar_nav_compact_style": False,
#     "sidebar_nav_legacy_style": False,
#     "sidebar_nav_flat_style": False,
#     "theme": "default",
#     "dark_mode_theme": None,
# }

import dj_database_url
import os
from pathlib import Path
from celery.schedules import crontab

BASE_DIR = Path(__file__).resolve().parent.parent
SECRET_KEY = 'u)w*v%19nm644-q@xn791_ac_@jyi_%%w(-*#cnd%0e)z*@8ib' 

# Set DEBUG to False for production! 
DEBUG = True

ALLOWED_HOSTS = ['farmaid-backend.onrender.com', 'localhost', '127.0.0.1', '*']

# --- APPS CONFIGURATION ---
INSTALLED_APPS = [
    'jazzmin',           # ✅ Must be above admin
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles', 
    
    # 3rd Party
    'rest_framework',
    'rest_framework.authtoken',
    'corsheaders', 
    'django_celery_beat', 
    
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
]

ROOT_URLCONF = 'farm_aid_project.urls'
WSGI_APPLICATION = 'farm_aid_project.wsgi.application'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
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

# --- DATABASE (Neon.tech) ---
DATABASES = {
    'default': dj_database_url.parse('postgresql://neondb_owner:npg_Z46qfbzXJSuj@ep-long-credit-ahfpyg3c-pooler.c-3.us-east-1.aws.neon.tech/neondb?sslmode=require')
}

# --- AUTHENTICATION ---
AUTH_USER_MODEL = 'api.Farmer'

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.TokenAuthentication',
        'rest_framework.authentication.SessionAuthentication', 
    ],
}

# --- EMAIL CONFIGURATION ---
EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_HOST = 'smtp.gmail.com'
EMAIL_PORT = 587
EMAIL_USE_TLS = True
EMAIL_HOST_USER = 'ramokhelekeeke@gmail.com'
EMAIL_HOST_PASSWORD = 'sxhgmmpsxhtzotyh' 
DEFAULT_FROM_EMAIL = 'FarmAid Support <ramokhelekeeke@gmail.com>'

# --- TIMEZONE & LOCALIZATION ---
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'Africa/Maseru'
USE_I18N = True
USE_TZ = True

# --- CELERY & REDIS CONFIGURATION ---
CELERY_BROKER_URL = os.environ.get('REDIS_URL', 'redis://localhost:6379/0')
CELERY_RESULT_BACKEND = os.environ.get('REDIS_URL', 'redis://localhost:6379/0')
CELERY_ACCEPT_CONTENT = ['json']
CELERY_TASK_SERIALIZER = 'json'
CELERY_RESULT_SERIALIZER = 'json'
CELERY_TIMEZONE = 'Africa/Maseru'
CELERY_BEAT_SCHEDULER = 'django_celery_beat.schedulers:DatabaseScheduler'

CELERY_BEAT_SCHEDULE = {
    'fetch-weather-every-12-hours': {
        'task': 'api.tasks.sync_weather_and_generate_alerts',
        'schedule': crontab(minute=0, hour='*/12'),  
    },
}

# --- CORS & SECURITY SETTINGS ---
CORS_ALLOW_ALL_ORIGINS = True 
CORS_ALLOW_CREDENTIALS = True
CSRF_TRUSTED_ORIGINS = [
    "http://localhost", 
    "http://127.0.0.1", 
    "https://farmaid-backend.onrender.com" 
]

# --- STATIC & MEDIA STORAGE ---
STATIC_URL = 'static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles') 
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'

MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# --- JAZZMIN SETTINGS (UI POLISH) ---
JAZZMIN_SETTINGS = {
    "site_title": "FarmAid Admin",
    "site_header": "FarmAid",
    "site_brand": "FarmAid Management",
    "welcome_sign": "Welcome to the FarmAid Admin Portal",
    "copyright": "FarmAid Lesotho",
    "user_avatar": None,
    "topmenu_links": [
        {"name": "Home",  "url": "admin:index", "permissions": ["auth.view_user"]},
        {"model": "api.Farmer"},
    ],
    # ✅ Adds Logout inside the User Icon (Top Right)
    "usermenu_links": [
        {"name": "Log out", "url": "admin:logout", "icon": "fas fa-sign-out-alt"},
    ],
    "show_sidebar": True,
    "navigation_expanded": True,
    "icons": {
        "auth": "fas fa-users-cog",
        "auth.user": "fas fa-user",
        "api.Farmer": "fas fa-seedling",
        "api.Plant": "fas fa-leaf",
        "api.Alert": "fas fa-bell",
    },
}

JAZZMIN_UI_TWEAKS = {
    "navbar_small_text": False,
    "footer_small_text": False,
    "body_small_text": False,
    "brand_small_text": False,
    "brand_colour": "navbar-success",
    "accent": "accent-teal",
    "navbar": "navbar-dark",
    "no_navbar_border": False,
    "navbar_fixed": True,
    "layout_boxed": False,
    "footer_fixed": False,
    "sidebar_fixed": True,
    "sidebar": "sidebar-dark-success",
    "sidebar_nav_small_text": False,
    "sidebar_disable_expand": False,
    "sidebar_nav_child_indent": True,
    "sidebar_nav_compact_style": False,
    "sidebar_nav_legacy_style": False,
    "sidebar_nav_flat_style": True,
    "theme": "default",
    "dark_mode_theme": None,
}

# ✅ Required for Django 5.1 to allow logout from the dropdown link
LOGOUT_ON_GET = True
