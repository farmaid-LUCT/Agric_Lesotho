"""
api/tasks.py  —  FarmAid Lesotho

Celery background tasks.
Called by signals.py and the Celery beat scheduler defined in settings.py.
"""

import logging
from django.utils import timezone
from django.db.models import Q

logger = logging.getLogger(__name__)


# ── Helper called by the WeatherData post_save signal ────────────────────────

def _evaluate_weather_row(instance):
    """
    Evaluates a freshly-saved WeatherData row and creates AppAlerts for
    affected farmers. Called from signals.py — NOT a Celery task so it runs
    synchronously during the save.  Kept here so the logic is in one place.
    """
    from .models import CropProfile, AppAlert

    district = instance.district or ''

    # ── 1. Fungal / Blight risk (high humidity) ───────────────────────────
    if instance.Humidity > 80:
        blight_prone = ["Tomato", "Potato", "Pepper", "Eggplant", "Cucumber"]
        query = Q()
        for veg in blight_prone:
            query |= Q(VegetableType__icontains=veg)

        for profile in CropProfile.objects.filter(query, IsActive=True):
            AppAlert.objects.get_or_create(
                FarmerID    = profile.FarmerID,
                Title       = "Fungal Disease Risk",
                alert_type  = "disease",
                RelatedCrop = profile,
                defaults={
                    'Message': (
                        f"High humidity ({instance.Humidity}%) detected in {district}. "
                        f"Check your {profile.VegetableType} for signs of Blight or Mildew."
                    ),
                    'priority': 'high',
                },
            )

    # ── 2. Frost risk (low temperature) ──────────────────────────────────
    if instance.Temperature < 3.0:
        for profile in CropProfile.objects.filter(IsActive=True):
            AppAlert.objects.get_or_create(
                FarmerID    = profile.FarmerID,
                Title       = "Frost Warning",
                alert_type  = "weather",
                RelatedCrop = profile,
                defaults={
                    'Message': (
                        f"Freezing temperatures ({instance.Temperature:.1f}°C) in {district}. "
                        f"Protect your {profile.VegetableType} from frost damage tonight."
                    ),
                    'priority': 'high',
                },
            )

    # ── 3. Heat stress (high temperature) ────────────────────────────────
    if instance.Temperature > 30.0:
        leafy_greens = ["Cabbage", "Spinach", "Lettuce", "Kale", "Chard"]
        query = Q()
        for veg in leafy_greens:
            query |= Q(VegetableType__icontains=veg)

        for profile in CropProfile.objects.filter(query, IsActive=True):
            AppAlert.objects.get_or_create(
                FarmerID    = profile.FarmerID,
                Title       = "Heat Stress Alert",
                alert_type  = "weather",
                RelatedCrop = profile,
                defaults={
                    'Message': (
                        f"High heat ({instance.Temperature:.1f}°C) in {district}. "
                        f"Increase irrigation for your {profile.VegetableType} to prevent wilting."
                    ),
                    'priority': 'medium',
                },
            )

    # ── 4. Heavy rainfall / disease spread risk ───────────────────────────
    if instance.rainfall_last_7_days > 30:
        for profile in CropProfile.objects.filter(IsActive=True):
            AppAlert.objects.get_or_create(
                FarmerID    = profile.FarmerID,
                Title       = "Heavy Rainfall Alert",
                alert_type  = "weather",
                RelatedCrop = profile,
                defaults={
                    'Message': (
                        f"Heavy rainfall ({instance.rainfall_last_7_days:.0f}mm in 7 days) "
                        f"in {district}. Watch for waterlogging and root rot on your {profile.VegetableType}."
                    ),
                    'priority': 'medium',
                },
            )

    logger.info(
        f'[_evaluate_weather_row] district={district} '
        f'temp={instance.Temperature} humidity={instance.Humidity} '
        f'rain7d={instance.rainfall_last_7_days}'
    )


# ── Celery tasks (require Redis broker — only active when Celery worker runs) ─

try:
    from celery import shared_task

    @shared_task(bind=True, max_retries=3, default_retry_delay=300)
    def sync_weather_and_generate_alerts(self):
        """Fetch latest weather and generate alerts. Scheduled every 12h by Celery Beat."""
        try:
            from django.core.management import call_command
            call_command('fetch_weather', verbosity=1)
            logger.info('sync_weather_and_generate_alerts completed successfully.')
            return 'success'
        except Exception as exc:
            logger.error(f'sync_weather_and_generate_alerts failed: {exc}')
            raise self.retry(exc=exc)

    @shared_task(bind=True, max_retries=2, default_retry_delay=60)
    def send_followup_reminders(self):
        """Send follow-up reminders to farmers with upcoming follow-up dates."""
        try:
            from datetime import date
            from .models import Diagnosis, AppAlert
            today = date.today()
            due = Diagnosis.objects.filter(follow_up_date=today).select_related('PlantID__FarmerID')
            count = 0
            for diag in due:
                farmer = diag.PlantID.FarmerID
                AppAlert.objects.get_or_create(
                    FarmerID   = farmer,
                    Title      = f"Follow-up: {diag.DiseaseName}",
                    alert_type = "reminder",
                    defaults={
                        'Message': (
                            f"Today is your scheduled follow-up for {diag.DiseaseName} "
                            f"diagnosed on {diag.DateDiagnosed.strftime('%d %b')}. "
                            f"Please check your crop and update the treatment outcome."
                        ),
                        'priority': 'medium',
                    },
                )
                count += 1
            logger.info(f'send_followup_reminders: {count} reminders sent.')
            return f'{count} reminders sent'
        except Exception as exc:
            logger.error(f'send_followup_reminders failed: {exc}')
            raise self.retry(exc=exc)

    @shared_task(bind=True, max_retries=2, default_retry_delay=120)
    def send_market_price_alerts(self):
        """Notify farmers of significant price movements."""
        try:
            from .models import MarketPrice, Farmer, AppAlert
            recent = MarketPrice.objects.order_by('-date_recorded')[:20]
            count  = 0
            for price in recent:
                if price.price_trend in ('rising', 'falling'):
                    trend_word = 'risen' if price.price_trend == 'rising' else 'fallen'
                    for farmer in Farmer.objects.filter(
                        notification_market=True,
                        district__iexact=price.district,
                        is_active=True,
                    ):
                        AppAlert.objects.get_or_create(
                            FarmerID   = farmer,
                            Title      = f"Market Update: {price.vegetable_name}",
                            alert_type = "market",
                            defaults={
                                'Message': (
                                    f"{price.vegetable_name} prices have {trend_word} "
                                    f"to LSL {price.price_per_kg}/kg at {price.market_name}."
                                ),
                                'priority': 'low',
                            },
                        )
                        count += 1
            logger.info(f'send_market_price_alerts: {count} alerts created.')
            return f'{count} alerts'
        except Exception as exc:
            logger.error(f'send_market_price_alerts failed: {exc}')
            raise self.retry(exc=exc)

except ImportError:
    # Celery not installed or not configured — tasks are unavailable but the
    # Django app itself continues to work normally.
    logger.warning('Celery not available — background tasks disabled.')
