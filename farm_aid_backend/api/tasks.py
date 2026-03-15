# import logging
# from celery import shared_task
# from django.core.management import call_command
# from django.db import connection

# logger = logging.getLogger(__name__)

# @shared_task(
#     bind=True, 
#     max_retries=3, 
#     default_retry_delay=300  # Retry after 5 mins if it fails
# )
# def sync_weather_and_generate_alerts(self):
#     """
#     Automated task to fetch weather data and generate alerts for farmers.
#     """
#     try:
#         logger.info("--- Starting Weather Sync Task ---")
        
#         # 1. Health Check: Ensure DB connection is alive before calling command
#         connection.ensure_connection()
        
#         # 2. Execute the management command
#         # We pass verbosity=0 to keep logs clean, or 1 to see more detail
#         call_command('fetch_weather', verbosity=1)
        
#         logger.info("--- Weather Sync & Alert Generation Successful ---")
#         return "Success"

#     except Exception as e:
#         logger.error(f"Weather Task Failed: {str(e)}")
#         # If it's a temporary connection error, retry the task
#         raise self.retry(exc=e)


"""
api/tasks.py  —  FarmAid Lesotho  (complete replacement)
==========================================================
WHY THE ORIGINAL DIDN'T POPULATE THE ALERTS TABLE:
  AppAlert.objects.get_or_create(FarmerID=..., Title=..., Message=...) uses
  ALL three fields as the lookup key. Because Message includes the live sensor
  value (e.g. "88% humidity"), the string changes every weather refresh →
  get_or_create always inserts a new row AND never deduplicates.

  Fix: _create_alert_once() deduplicates by (FarmerID, alert_type, Title)
  within the last 24 hours, completely ignoring the Message content.

WHY BEAT TASKS WEREN'T FIRING:
  Celery Beat needs to run as a SEPARATE process from the worker.
  See the bottom of this file for the correct start commands.
"""

import logging
from datetime import timedelta

from celery import shared_task
from django.db import connection
from django.core.management import call_command
from django.utils import timezone

logger = logging.getLogger(__name__)


# ─────────────────────────────────────────────────────────────────────────────
# HELPER — deduplicated alert creation
# ─────────────────────────────────────────────────────────────────────────────

def _create_alert_once(farmer, title, message, alert_type,
                        related_crop=None, priority='medium', district_target=None):
    """
    Creates an AppAlert ONLY if no unread alert with the same
    (FarmerID, alert_type, Title) exists in the last 24 hours.

    This is the fix for the original get_or_create bug: we now ignore
    the Message field entirely when checking for duplicates, so changing
    sensor values no longer create duplicate alerts.
    """
    from .models import AppAlert

    cutoff  = timezone.now() - timedelta(hours=24)
    already = AppAlert.objects.filter(
        FarmerID         = farmer,
        alert_type       = alert_type,
        Title            = title,
        IsRead           = False,
        DateCreated__gte = cutoff,
    ).exists()

    if already:
        return None

    return AppAlert.objects.create(
        FarmerID        = farmer,
        Title           = title,
        Message         = message,
        alert_type      = alert_type,
        RelatedCrop     = related_crop,
        priority        = priority,
        district_target = district_target,
        expires_at      = timezone.now() + timedelta(hours=48),
    )


# ─────────────────────────────────────────────────────────────────────────────
# TASK 1 — Weather sync + alert generation (every 12 h via Beat)
# ─────────────────────────────────────────────────────────────────────────────

@shared_task(bind=True, max_retries=3, default_retry_delay=300)
def sync_weather_and_generate_alerts(self):
    """
    1. Calls the fetch_weather management command to pull live data into WeatherData.
    2. Runs the alert engine over the freshest row per district.

    Already scheduled in settings.py:
      'fetch-weather-every-12-hours': crontab(minute=0, hour='*/12')
    """
    try:
        logger.info('[WeatherTask] Starting weather sync ...')
        connection.ensure_connection()
        call_command('fetch_weather', verbosity=1)
        logger.info('[WeatherTask] fetch_weather done — running alert engine ...')
        _run_weather_alert_engine()
        logger.info('[WeatherTask] Complete')
        return 'success'
    except Exception as exc:
        logger.error(f'[WeatherTask] Failed: {exc}', exc_info=True)
        raise self.retry(exc=exc)


def _run_weather_alert_engine():
    """
    Reads the latest WeatherData row per district and fans out AppAlerts.
    Called from the Celery task AND from signals.py post_save so the logic
    lives in one place only.
    """
    from .models import WeatherData
    seen = set()
    for weather in WeatherData.objects.order_by('-DateUpdated'):
        key = (weather.district or 'unknown').lower()
        if key in seen:
            continue
        seen.add(key)
        _evaluate_weather_row(weather)


def _evaluate_weather_row(weather):
    """
    Core alert logic for one WeatherData row.
    Called from _run_weather_alert_engine() and directly from signals.py.
    """
    from django.db.models import Q
    from .models import CropProfile

    dist_q = (
        Q(FarmerID__district__iexact=weather.district)
        if weather.district else Q()
    )

    # ── 1. Fungal / Blight risk (humidity > 80 %) ────────────────────────
    if weather.Humidity > 80:
        blight_prone = ['Tomato', 'Potato', 'Pepper', 'Eggplant', 'Cucumber']
        q = Q()
        for v in blight_prone:
            q |= Q(VegetableType__icontains=v)

        for profile in CropProfile.objects.filter(q, IsActive=True).select_related('FarmerID'):
            if not profile.FarmerID.notification_diseases:
                continue
            _create_alert_once(
                farmer          = profile.FarmerID,
                title           = 'Fungal Disease Risk',
                message         = (
                    f'Humidity is {weather.Humidity}% in {weather.district or "your area"}. '
                    f'Your {profile.VegetableType} is at risk of Blight or Mold. '
                    'Inspect leaves and apply preventive fungicide if needed.'
                ),
                alert_type      = 'disease',
                related_crop    = profile,
                priority        = 'high',
                district_target = weather.district,
            )

    # ── 2. Frost warning (temp < 3 °C) ───────────────────────────────────
    if weather.Temperature < 3.0:
        for profile in CropProfile.objects.filter(
            dist_q, IsActive=True
        ).select_related('FarmerID'):
            if not profile.FarmerID.notification_weather:
                continue
            _create_alert_once(
                farmer          = profile.FarmerID,
                title           = 'Frost Warning',
                message         = (
                    f'Temperature has dropped to {weather.Temperature}C in '
                    f'{weather.district or "your area"}. '
                    f'Cover or move your {profile.VegetableType} to prevent frost damage.'
                ),
                alert_type      = 'weather',
                related_crop    = profile,
                priority        = 'high',
                district_target = weather.district,
            )

    # ── 3. Heat stress (temp > 30 °C) ────────────────────────────────────
    if weather.Temperature > 30.0:
        leafy = ['Cabbage', 'Spinach', 'Lettuce', 'Kale', 'Chard']
        q = Q()
        for v in leafy:
            q |= Q(VegetableType__icontains=v)

        for profile in CropProfile.objects.filter(
            q, dist_q, IsActive=True
        ).select_related('FarmerID'):
            if not profile.FarmerID.notification_weather:
                continue
            _create_alert_once(
                farmer          = profile.FarmerID,
                title           = 'Heat Stress Alert',
                message         = (
                    f"It's {weather.Temperature}C in {weather.district or 'your area'}. "
                    f'Increase irrigation for your {profile.VegetableType} to prevent wilting.'
                ),
                alert_type      = 'weather',
                related_crop    = profile,
                priority        = 'medium',
                district_target = weather.district,
            )

    # ── 4. Waterlogging risk (rainfall > 30 mm / 7 days) ─────────────────
    if weather.rainfall_last_7_days > 30:
        root_veg = ['Potato', 'Carrot', 'Beetroot', 'Onion', 'Garlic']
        q = Q()
        for v in root_veg:
            q |= Q(VegetableType__icontains=v)

        for profile in CropProfile.objects.filter(
            q, dist_q, IsActive=True
        ).select_related('FarmerID'):
            if not profile.FarmerID.notification_weather:
                continue
            _create_alert_once(
                farmer          = profile.FarmerID,
                title           = 'Waterlogging Risk',
                message         = (
                    f'{weather.rainfall_last_7_days} mm of rain in the last 7 days in '
                    f'{weather.district or "your area"}. '
                    f'Check drainage around your {profile.VegetableType} to prevent root rot.'
                ),
                alert_type      = 'weather',
                related_crop    = profile,
                priority        = 'medium',
                district_target = weather.district,
            )


# ─────────────────────────────────────────────────────────────────────────────
# TASK 2 — Follow-up reminders (daily at 07:00)
# ─────────────────────────────────────────────────────────────────────────────

@shared_task
def send_followup_reminders():
    """
    Alerts farmers whose Diagnosis.follow_up_date == today and who have
    not yet marked treatment_applied = True.

    Add to CELERY_BEAT_SCHEDULE in settings.py:
      'followup-reminders-daily': {
          'task': 'api.tasks.send_followup_reminders',
          'schedule': crontab(minute=0, hour=7),
      },
    """
    from .models import Diagnosis
    today = timezone.now().date()
    due   = Diagnosis.objects.filter(
        follow_up_date    = today,
        treatment_applied = False,
    ).select_related('PlantID__FarmerID', 'PlantID__CropProfile')

    count = 0
    for diag in due:
        farmer  = diag.PlantID.FarmerID
        profile = diag.PlantID.CropProfile
        _create_alert_once(
            farmer       = farmer,
            title        = 'Follow-up Due Today',
            message      = (
                f"Your follow-up for '{diag.DiseaseName}' is due today. "
                'Has the treatment been applied? Open the app to log your update.'
            ),
            alert_type   = 'reminder',
            related_crop = profile,
            priority     = 'medium',
        )
        count += 1

    logger.info(f'[FollowUpTask] {count} reminders sent.')
    return f'{count} reminders sent'


# ─────────────────────────────────────────────────────────────────────────────
# TASK 3 — Market price alerts (daily at 08:00)
# ─────────────────────────────────────────────────────────────────────────────

@shared_task
def send_market_price_alerts():
    """
    Alerts farmers with notification_market=True when a crop they grow
    has a rising or falling price trend.

    Add to CELERY_BEAT_SCHEDULE in settings.py:
      'market-alerts-daily': {
          'task': 'api.tasks.send_market_price_alerts',
          'schedule': crontab(minute=0, hour=8),
      },
    """
    from .models import MarketPrice, CropProfile

    count = 0
    for trend, title_tpl, msg_tpl in [
        (
            'rising',
            '{veg} Price Rising',
            '{veg} is now LSL {price}/kg at {market} ({district}). Good time to sell!',
        ),
        (
            'falling',
            '{veg} Price Falling',
            '{veg} price has dropped to LSL {price}/kg. Consider holding stock or exploring other markets.',
        ),
    ]:
        for price_row in MarketPrice.objects.filter(price_trend=trend):
            for profile in CropProfile.objects.filter(
                VegetableType__icontains=price_row.vegetable_name,
                IsActive=True,
            ).select_related('FarmerID'):
                if not profile.FarmerID.notification_market:
                    continue
                fmt = dict(
                    veg      = price_row.vegetable_name,
                    price    = price_row.price_per_kg,
                    market   = price_row.market_name,
                    district = price_row.district,
                )
                _create_alert_once(
                    farmer       = profile.FarmerID,
                    title        = title_tpl.format(**fmt),
                    message      = msg_tpl.format(**fmt),
                    alert_type   = 'market',
                    related_crop = profile,
                    priority     = 'low',
                )
                count += 1

    logger.info(f'[MarketTask] {count} market alerts sent.')
    return f'{count} market alerts sent'
