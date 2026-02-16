# farm_aid_backend/api/tasks.py
from celery import shared_task
from django.core.management import call_command

@shared_task
def scheduled_weather_update():
    # This runs the REAL code you wrote in fetch_weather.py automatically
    call_command('fetch_weather')