"""
FarmAid Dashboard API Views
============================
Add these views to your api/views.py (or a new api/dashboard_views.py)
and wire them in urls.py as shown at the bottom of this file.
"""

from django.http import JsonResponse
from django.contrib.admin.views.decorators import staff_member_required
from django.contrib.admin.models import LogEntry, ADDITION, CHANGE, DELETION
from django.utils import timezone
from django.db.models import Count
from datetime import timedelta

from .models import (
    Farmer, Diagnosis, CropProfile,
    AppAlert, WeatherData,
)


# ============================================================
# 1.  MAIN STATS  —  /admin/dashboard-stats/
# ============================================================
@staff_member_required
def dashboard_stats(request):
    today = timezone.now().date()

    # Weather for Maseru (or first available record)
    weather = WeatherData.objects.filter(
        district__icontains='Maseru'
    ).order_by('-DateUpdated').first()

    if not weather:
        weather = WeatherData.objects.order_by('-DateUpdated').first()

    weather_data = None
    if weather:
        weather_data = {
            'temp':      round(weather.Temperature, 1),
            'humidity':  weather.Humidity,
            'rainfall':  round(weather.Rainfall, 1),
        }

    return JsonResponse({
        'farmers':         Farmer.objects.filter(is_active=True).count(),
        'diagnoses':       Diagnosis.objects.count(),
        'today_diagnoses': Diagnosis.objects.filter(DateDiagnosed__date=today).count(),
        'crops':           CropProfile.objects.filter(IsActive=True).count(),
        'alerts':          AppAlert.objects.filter(IsRead=False).count(),
        'weather':         weather_data,
    })


# ============================================================
# 2.  RECENT DIAGNOSES  —  /admin/recent-diagnoses/
# ============================================================
@staff_member_required
def recent_diagnoses(request):
    qs = (
        Diagnosis.objects
        .select_related('PlantID__FarmerID')
        .order_by('-DateDiagnosed')[:12]
    )

    rows = []
    for d in qs:
        farmer = d.PlantID.FarmerID if d.PlantID else None
        rows.append({
            'farmer':     farmer.username if farmer else '—',
            'farmer_id':  farmer.pk if farmer else None,
            'disease':    d.DiseaseName.replace('_', ' ').title(),
            'confidence': d.ConfidenceLevel,
            'severity':   d.severity or '',
            'date':       d.DateDiagnosed.strftime('%d %b %Y'),
        })

    return JsonResponse(rows, safe=False)


# ============================================================
# 3.  DISEASE BREAKDOWN  —  /admin/disease-breakdown/
# ============================================================
@staff_member_required
def disease_breakdown(request):
    qs = (
        Diagnosis.objects
        .values('DiseaseName')
        .annotate(count=Count('DiagnosisID'))
        .order_by('-count')[:8]
    )

    data = [
        {
            'name':  row['DiseaseName'].replace('_', ' ').title(),
            'count': row['count'],
        }
        for row in qs
    ]

    return JsonResponse(data, safe=False)


# ============================================================
# 4.  RECENT ACTIVITY  —  /admin/recent-activity/
# ============================================================
@staff_member_required
def recent_activity(request):
    action_map = {
        ADDITION: ('addition', 'added'),
        CHANGE:   ('change',   'updated'),
        DELETION: ('deletion', 'deleted'),
    }

    entries = LogEntry.objects.select_related('user').order_by('-action_time')[:10]

    data = []
    for entry in entries:
        action_key, action_label = action_map.get(entry.action_flag, ('change', 'modified'))
        # how long ago
        delta = timezone.now() - entry.action_time
        if delta.seconds < 3600:
            time_str = f"{delta.seconds // 60}m ago"
        elif delta.days == 0:
            time_str = f"{delta.seconds // 3600}h ago"
        else:
            time_str = f"{delta.days}d ago"

        data.append({
            'user':         entry.user.username,
            'action':       action_key,
            'action_label': action_label,
            'object':       entry.object_repr,
            'time':         time_str,
        })

    return JsonResponse(data, safe=False)


# ============================================================
# HOW TO WIRE IN urls.py
# ============================================================
"""
In your farm_aid_project/urls.py, add these BEFORE the admin URL:

from api.dashboard_views import (
    dashboard_stats,
    recent_diagnoses,
    disease_breakdown,
    recent_activity,
)

urlpatterns = [
    # Dashboard API endpoints
    path('admin/dashboard-stats/',    dashboard_stats,    name='dashboard_stats'),
    path('admin/recent-diagnoses/',   recent_diagnoses,   name='recent_diagnoses'),
    path('admin/disease-breakdown/',  disease_breakdown,  name='disease_breakdown'),
    path('admin/recent-activity/',    recent_activity,    name='recent_activity'),

    # Then the normal admin
    path('admin/', admin.site.urls),
    ...
]

Make sure the 4 custom paths come BEFORE path('admin/', ...) so Django
finds them first.
"""
