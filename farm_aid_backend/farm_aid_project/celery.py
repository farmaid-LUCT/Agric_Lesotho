import os
from celery import Celery

# Set the default Django settings module for the 'celery' program.
# This points to your settings.py file
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'farm_aid_project.settings')

app = Celery('farm_aid_project')

# Using a string here means the worker doesn't have to serialize
# the configuration object to child processes.
# namespace='CELERY' means all celery-related config keys 
# should have a `CELERY_` prefix in settings.py.
app.config_from_object('django.conf:settings', namespace='CELERY')

# Load task modules from all registered Django app configs.
# This will automatically find tasks.py in your 'api' folder.
app.autodiscover_tasks()

@app.task(bind=True)
def debug_task(self):
    print(f'Request: {self.request!r}')