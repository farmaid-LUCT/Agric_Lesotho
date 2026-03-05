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
#     'jazzmin',           
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

# # --- JAZZMIN SETTINGS (Professional Dashboard with Activity Log) ---
# JAZZMIN_SETTINGS = {
#     "site_title": "FarmAid Admin", 
#     "site_header": "FarmAid",
#     "site_brand": "FarmAid Management",
#     "welcome_sign": "FarmAid Management System",
#     "copyright": "FarmAid Lesotho",
#     "user_avatar": None,
#     "topmenu_links": [
#         {"name": "Home",  "url": "admin:index", "permissions": ["auth.view_user"]},
#         {"name": "Activity Log", "model": "admin.LogEntry"}, # Quick link to Admin Actions
#     ],
#     "usermenu_links": [
#         {"name": "Log out", "url": "admin:logout", "icon": "fas fa-sign-out-alt"},
#     ],
#     "show_sidebar": True,
#     "navigation_expanded": True,
    
#     # ✅ Grouping: Admin Actions (LogEntry) appear first
#     "order_with_respect_to": [
#         "admin.LogEntry", 
#         "api.Farmer", 
#         "api.Diagnosis", 
#         "api.Alert"
#     ],
    
#     "icons": {
#         "admin.LogEntry": "fas fa-history", # Icon for Admin Actions
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
#     "navbar_fixed": True,
#     "layout_boxed": False,
#     "footer_fixed": False,
#     "sidebar_fixed": True,
#     "sidebar": "sidebar-dark-success",
#     "sidebar_nav_small_text": False,
#     "sidebar_disable_expand": False,
#     "sidebar_nav_child_indent": True,
#     "sidebar_nav_compact_style": False,
#     "sidebar_nav_legacy_style": False,
#     "sidebar_nav_flat_style": True,
#     "theme": "default",
#     "dark_mode_theme": None,
# }

# LOGOUT_ON_GET = True

import dj_database_url
import os
from pathlib import Path
from celery.schedules import crontab

BASE_DIR = Path(__file__).resolve().parent.parent
SECRET_KEY = os.environ.get('DJANGO_SECRET_KEY', 'u)w*v%19nm644-q@xn791_ac_@jyi_%%w(-*#cnd%0e)z*@8ib')

DEBUG = os.environ.get('DEBUG', 'True') == 'True'

# --- HOSTS ---
ALLOWED_HOSTS = [
    'farmaid-backend.onrender.com', 
    'localhost', 
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

# --- TEMPLATES (FIXED: This solves your TemplateDoesNotExist error) ---
TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [os.path.join(BASE_DIR, 'templates')],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request', # Required for Jazzmin
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

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.TokenAuthentication',
        'rest_framework.authentication.SessionAuthentication', 
    ],
}

# --- CORS & SECURITY ---
CORS_ALLOW_CREDENTIALS = True
CORS_ALLOWED_ORIGIN_REGEXES = [
    r"^http://localhost:\d+$",
    r"^http://127.0.0.1:\d+$",
]
CORS_ALLOWED_ORIGINS = [
    "https://farmaid-backend.onrender.com",
]
CSRF_TRUSTED_ORIGINS = [
    "http://localhost",
    "http://127.0.0.1",
    "https://farmaid-backend.onrender.com"
]

APPEND_SLASH = False 

# --- EMAIL ---
EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_HOST = 'smtp.gmail.com'
EMAIL_PORT = 587
EMAIL_USE_TLS = True
EMAIL_HOST_USER = 'ramokhelekeeke@gmail.com'
EMAIL_HOST_PASSWORD = 'sxhgmmpsxhtzotyh' 
DEFAULT_FROM_EMAIL = 'FarmAid Support <ramokhelekeeke@gmail.com>'

# --- TIMEZONE ---
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'Africa/Maseru'
USE_I18N = True
USE_TZ = True

# --- CELERY & REDIS ---
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

# --- STATIC & MEDIA ---
STATIC_URL = 'static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles') 
# Static storage fix for whitenoise/jazzmin compatibility
STATICFILES_STORAGE = 'whitenoise.storage.CompressedStaticFilesStorage'

MEDIA_URL = '/media/'
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
        "admin.LogEntry": "fas fa-history",
        "auth": "fas fa-users-cog",
        "api.Farmer": "fas fa-user-tag",
        "api.Plant": "fas fa-leaf",
        "api.AppAlert": "fas fa-bell",
        "api.PersonalizedRule": "fas fa-gavel", # Icon for your 8-factor logic
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

LOGOUT_ON_GET = True
LOGIN_URL = '/admin/login/'
LOGIN_REDIRECT_URL = '/admin/'
