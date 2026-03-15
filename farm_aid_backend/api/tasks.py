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
api/signals.py  —  FarmAid Lesotho  (complete replacement)

Already imported by ApiConfig.ready() in apps.py — no change to apps.py needed.

Key fix: instead of duplicating the alert logic here with get_or_create,
we delegate to _evaluate_weather_row() in tasks.py so the logic is only
defined in one place and uses the correct deduplication.
"""

from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import WeatherData

print('FarmAid signals loaded successfully!')


@receiver(post_save, sender=WeatherData)
def analyze_weather_for_alerts(sender, instance, created, **kwargs):
    """
    Fires when a WeatherData row is saved — e.g. from the admin dashboard,
    from fetch_weather management command, or from the API.

    Only reacts to NEW rows (created=True) to avoid re-triggering on edits.
    Delegates to tasks._evaluate_weather_row() for the actual alert logic.
    """
    if not created:
        return

    try:
        from .tasks import _evaluate_weather_row
        _evaluate_weather_row(instance)
    except Exception as exc:
        import logging
        logging.getLogger(__name__).error(
            f'[Signal] analyze_weather_for_alerts error: {exc}', exc_info=True
        )
