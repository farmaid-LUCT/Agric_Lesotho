from celery import shared_task
from django.core.management import call_command
import logging

logger = logging.getLogger(__name__)

@shared_task
def sync_weather_and_generate_alerts():
    """
    This is the real automated task that runs your management command.
    """
    try:
        logger.info("Starting automated weather fetch...")
        # This calls your REAL fetch_weather.py command
        call_command('fetch_weather')
        logger.info("Automated weather fetch and alert generation complete.")
    except Exception as e:
        logger.error(f"Automated Task Failed: {str(e)}")