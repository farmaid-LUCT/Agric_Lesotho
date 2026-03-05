# from celery import shared_task
# from django.core.management import call_command
# import logging

# logger = logging.getLogger(__name__)

# @shared_task
# def sync_weather_and_generate_alerts():
#     """
#     This is the real automated task that runs your management command.
#     """
#     try:
#         logger.info("Starting automated weather fetch...")
#         # This calls your REAL fetch_weather.py command
#         call_command('fetch_weather')
#         logger.info("Automated weather fetch and alert generation complete.")
#     except Exception as e:
#         logger.error(f"Automated Task Failed: {str(e)}")

import logging
from celery import shared_task
from django.core.management import call_command
from django.db import connection

logger = logging.getLogger(__name__)

@shared_task(
    bind=True, 
    max_retries=3, 
    default_retry_delay=300  # Retry after 5 mins if it fails
)
def sync_weather_and_generate_alerts(self):
    """
    Automated task to fetch weather data and generate alerts for farmers.
    """
    try:
        logger.info("--- Starting Weather Sync Task ---")
        
        # 1. Health Check: Ensure DB connection is alive before calling command
        connection.ensure_connection()
        
        # 2. Execute the management command
        # We pass verbosity=0 to keep logs clean, or 1 to see more detail
        call_command('fetch_weather', verbosity=1)
        
        logger.info("--- Weather Sync & Alert Generation Successful ---")
        return "Success"

    except Exception as e:
        logger.error(f"Weather Task Failed: {str(e)}")
        # If it's a temporary connection error, retry the task
        raise self.retry(exc=e)
