# import dj_database_url
# import os
# from pathlib import Path
# from celery.schedules import crontab, solar
# from datetime import timedelta
# from corsheaders.defaults import default_headers

# BASE_DIR = Path(__file__).resolve().parent.parent
# SECRET_KEY = os.environ.get('DJANGO_SECRET_KEY', 'u)w*v%19nm644-q@xn791_ac_@jyi_%%w(-*#cnd%0e)z*@8ib')

# # --- DEBUG OFF for production ---
# DEBUG = False

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
# DATABASE_URL = os.environ.get('DATABASE_URL', 'postgresql://neondb_owner:npg_Z46qfbzXJSuj@ep-long-credit-ahfpyg3c-pooler.c-3.us-east-1.aws.neon.tech/neondb?sslmode=require')
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

# # --- ALLAUTH ---
# SITE_ID = 1

# ACCOUNT_EMAIL_REQUIRED        = True
# ACCOUNT_USERNAME_REQUIRED     = False
# ACCOUNT_AUTHENTICATION_METHOD = 'email'
# ACCOUNT_EMAIL_VERIFICATION    = 'none'

# SOCIALACCOUNT_PROVIDERS = {
#     'google': {
#         'SCOPE': ['profile', 'email'],
#         'AUTH_PARAMS': {'access_type': 'online'},
#         'APP': {
#             'client_id': os.environ.get('GOOGLE_CLIENT_ID', ''),
#             'secret':    os.environ.get('GOOGLE_CLIENT_SECRET', ''),
#             'key':       '',
#         },
#     }
# }

# # --- CORS & SECURITY ---
# CORS_ALLOW_CREDENTIALS = True
# CORS_ALLOWED_ORIGIN_REGEXES = [
#     r"^http://localhost:\d+$",
#     r"^http://127.0.0.1:\d+$",
# ]
# CORS_ALLOWED_ORIGINS = [
#     "https://farmaid-backend.onrender.com",
#     "http://localhost:59464",
# ]
# CSRF_TRUSTED_ORIGINS = [
#     "http://localhost:62803",
#     "http://127.0.0.1",
#     "https://farmaid-backend.onrender.com"
# ]

# CORS_ALLOW_HEADERS = list(default_headers) + ['authorization']
# APPEND_SLASH = True

# # --- EMAIL ---
# EMAIL_BACKEND       = 'django.core.mail.backends.smtp.EmailBackend'
# EMAIL_HOST          = 'smtp.gmail.com'
# EMAIL_PORT          = 587
# EMAIL_USE_TLS       = True
# EMAIL_HOST_USER     = os.environ.get('EMAIL_HOST_USER', 'ramokhelekeeke@gmail.com')
# EMAIL_HOST_PASSWORD = os.environ.get('EMAIL_HOST_PASSWORD', 'sxhgmmpsxhtzotyh')
# DEFAULT_FROM_EMAIL  = 'FarmAid Support <ramokhelekeeke@gmail.com>'

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
#     # Uncomment after: pip install ephem
#     # 'sunrise-weather-maseru': {
#     #     'task':     'api.tasks.sync_weather_and_generate_alerts',
#     #     'schedule': solar('sunrise', -29.31, 27.48),
#     #     'options':  {'expires': 1800},
#     # },
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
# # All model URLs follow: admin/<app_label>/<modelname>/
# # FarmAid app label is 'api' — all models live under admin/api/
# # FIX: was using wrong app label 'knowledgebase' instead of 'api'
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
#             {
#                 "name":        "Personalized Rules",
#                 "url":         "admin:api_personalizedrule_changelist",
#                 "icon":        "fas fa-gavel",
#                 "permissions": ["api.view_personalizedrule"],
#             },
#             {
#                 "name":        "Market Prices",
#                 "url":         "admin:api_marketprice_changelist",
#                 "icon":        "fas fa-chart-line",
#                 "permissions": ["api.view_marketprice"],
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
#         "api.PersonalizedRule":                "fas fa-gavel",
#         "api.FarmerInsight":                   "fas fa-chart-pie",
#         "api.GrowthJournalEntry":              "fas fa-journal-whills",
#         "api.MarketPrice":                     "fas fa-chart-line",
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
#         "api.PersonalizedRule",
#         "api.FarmerInsight",
#         "api.GrowthJournalEntry",
#         "api.MarketPrice",
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
#     'localhost:62803',
#     '127.0.0.1',
#     '10.0.2.2',
#     '.onrender.com'
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
# DATABASE_URL = os.environ.get('DATABASE_URL', 'postgresql://neondb_owner:npg_Z46qfbzXJSuj@ep-long-credit-ahfpyg3c-pooler.c-3.us-east-1.aws.neon.tech/neondb?sslmode=require')
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

# # --- ALLAUTH ---
# SITE_ID = 1

# # FIX — replaces 3 deprecated settings that caused warnings
# ACCOUNT_LOGIN_METHODS      = {'email'}
# ACCOUNT_SIGNUP_FIELDS      = ['email*', 'password1*', 'password2*']
# ACCOUNT_EMAIL_VERIFICATION = 'none'

# SOCIALACCOUNT_PROVIDERS = {
#     'google': {
#         'SCOPE': ['profile', 'email'],
#         'AUTH_PARAMS': {'access_type': 'online'},
#         'APP': {
#             'client_id': os.environ.get('GOOGLE_CLIENT_ID', ''),
#             'secret':    os.environ.get('GOOGLE_CLIENT_SECRET', ''),
#             'key':       '',
#         },
#     }
# }

# # --- CORS & SECURITY ---
# CORS_ALLOW_CREDENTIALS = True
# CORS_ALLOWED_ORIGIN_REGEXES = [
#     r"^http://localhost:\d+$",
#     r"^http://127.0.0.1:\d+$",
# ]
# CORS_ALLOWED_ORIGINS = [
#     "https://farmaid-backend.onrender.com",
#     "http://localhost:59464",
# ]
# CSRF_TRUSTED_ORIGINS = [
#     "http://localhost:62803",
#     "http://127.0.0.1",
#     "https://farmaid-backend.onrender.com"
# ]

# CORS_ALLOW_HEADERS = list(default_headers) + ['authorization']
# APPEND_SLASH = True

# # --- EMAIL ---
# EMAIL_BACKEND       = 'django.core.mail.backends.smtp.EmailBackend'
# EMAIL_HOST          = 'smtp.gmail.com'
# EMAIL_PORT          = 587
# EMAIL_USE_TLS       = True
# EMAIL_HOST_USER     = os.environ.get('EMAIL_HOST_USER', 'ramokhelekeeke@gmail.com')
# EMAIL_HOST_PASSWORD = os.environ.get('EMAIL_HOST_PASSWORD', 'sxhgmmpsxhtzotyh')
# DEFAULT_FROM_EMAIL  = 'FarmAid Support <ramokhelekeeke@gmail.com>'

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
#     # Uncomment after: pip install ephem
#     # 'sunrise-weather-maseru': {
#     #     'task':     'api.tasks.sync_weather_and_generate_alerts',
#     #     'schedule': solar('sunrise', -29.31, 27.48),
#     #     'options':  {'expires': 1800},
#     # },
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
#             {
#                 "name":        "Personalized Rules",
#                 "url":         "admin:api_personalizedrule_changelist",
#                 "icon":        "fas fa-gavel",
#                 "permissions": ["api.view_personalizedrule"],
#             },
#             {
#                 "name":        "Market Prices",
#                 "url":         "admin:api_marketprice_changelist",
#                 "icon":        "fas fa-chart-line",
#                 "permissions": ["api.view_marketprice"],
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
#         "api.PersonalizedRule":                "fas fa-gavel",
#         "api.FarmerInsight":                   "fas fa-chart-pie",
#         "api.GrowthJournalEntry":              "fas fa-journal-whills",
#         "api.MarketPrice":                     "fas fa-chart-line",
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
#         "api.PersonalizedRule",
#         "api.FarmerInsight",
#         "api.GrowthJournalEntry",
#         "api.MarketPrice",
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

# Masenya

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
    '.onrender.com'
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
    # 'farm_aid_project.middleware.CorsExceptionMiddleware',  # DISABLED - file not found
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
# FIXED: Get DATABASE_URL from environment variable, not hardcoded
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

# --- ALLAUTH ---
SITE_ID = 1

ACCOUNT_LOGIN_METHODS      = {'email'}
ACCOUNT_SIGNUP_FIELDS      = ['email*', 'password1*', 'password2*']
ACCOUNT_EMAIL_VERIFICATION = 'none'

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

# --- EMAIL ---
EMAIL_BACKEND       = 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_HOST          = 'smtp.gmail.com'
EMAIL_PORT          = 587
EMAIL_USE_TLS       = True
EMAIL_HOST_USER     = os.environ.get('EMAIL_HOST_USER', 'ramokhelekeeke@gmail.com')
EMAIL_HOST_PASSWORD = os.environ.get('EMAIL_HOST_PASSWORD', '')  # FIXED: Removed hardcoded password
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
            {
                "name":        "Personalized Rules",
                "url":         "admin:api_personalizedrule_changelist",
                "icon":        "fas fa-gavel",
                "permissions": ["api.view_personalizedrule"],
            },
            {
                "name":        "Market Prices",
                "url":         "admin:api_marketprice_changelist",
                "icon":        "fas fa-chart-line",
                "permissions": ["api.view_marketprice"],
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
        "api.PersonalizedRule":                "fas fa-gavel",
        "api.FarmerInsight":                   "fas fa-chart-pie",
        "api.GrowthJournalEntry":              "fas fa-journal-whills",
        "api.MarketPrice":                     "fas fa-chart-line",
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
        "api.PersonalizedRule",
        "api.FarmerInsight",
        "api.GrowthJournalEntry",
        "api.MarketPrice",
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
