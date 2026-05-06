# api/dashboard_views.py
"""
FarmAid Dashboard API Views
"""
import logging
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

logger = logging.getLogger(__name__)


def _get_field_value(obj, *field_names):
    """Try multiple field names (supports both camelCase and snake_case)"""
    for field_name in field_names:
        if hasattr(obj, field_name):
            return getattr(obj, field_name)
    return None


# ============================================================
# 1.  MAIN STATS  —  /admin/dashboard-stats/
# ============================================================
@staff_member_required
def dashboard_stats(request):
    try:
        today = timezone.now().date()

        # Try to get weather - support both field naming conventions
        weather = None
        # Try different possible field names for district
        try:
            weather = WeatherData.objects.filter(
                district__icontains='Maseru'
            ).order_by('-date_updated', '-DateUpdated').first()
        except:
            weather = WeatherData.objects.order_by('-date_updated', '-DateUpdated').first()

        weather_data = None
        if weather:
            # Try both naming conventions for each field
            temp_val = _get_field_value(weather, 'temperature', 'Temperature', 'temp', 'Temp')
            humidity_val = _get_field_value(weather, 'humidity', 'Humidity', 'hum', 'Hum')
            rainfall_val = _get_field_value(weather, 'rainfall', 'Rainfall', 'rain', 'Rain')
            
            weather_data = {
                'temp':      round(temp_val, 1) if temp_val else None,
                'humidity':  humidity_val if humidity_val else None,
                'rainfall':  round(rainfall_val, 1) if rainfall_val else None,
            }

        # Get counts with fallbacks for field names
        farmer_count = Farmer.objects.filter(
            **{'is_active__exact': True} if hasattr(Farmer, 'is_active') 
            else {'IsActive__exact': True} if hasattr(Farmer, 'IsActive')
            else {}
        ).count()
        
        crop_count = CropProfile.objects.filter(
            **{'is_active__exact': True} if hasattr(CropProfile, 'is_active')
            else {'IsActive__exact': True} if hasattr(CropProfile, 'IsActive')
            else {}
        ).count()
        
        alert_count = AppAlert.objects.filter(
            **{'is_read__exact': False} if hasattr(AppAlert, 'is_read')
            else {'IsRead__exact': False} if hasattr(AppAlert, 'IsRead')
            else {}
        ).count()

        # Get today's diagnoses
        date_field = 'date_diagnosed' if hasattr(Diagnosis, 'date_diagnosed') else 'DateDiagnosed'
        today_diagnoses = Diagnosis.objects.filter(
            **{f'{date_field}__date': today}
        ).count() if date_field else 0

        return JsonResponse({
            'farmers':         farmer_count,
            'diagnoses':       Diagnosis.objects.count(),
            'today_diagnoses': today_diagnoses,
            'crops':           crop_count,
            'alerts':          alert_count,
            'weather':         weather_data,
        })
    except Exception as e:
        logger.exception("Dashboard stats failed")
        return JsonResponse({'error': str(e)}, status=500)


# ============================================================
# 2.  RECENT DIAGNOSES  —  /admin/recent-diagnoses/
# ============================================================
@staff_member_required
def recent_diagnoses(request):
    try:
        # Determine field names dynamically
        date_field = 'date_diagnosed' if hasattr(Diagnosis, 'date_diagnosed') else 'DateDiagnosed'
        disease_field = 'disease_name' if hasattr(Diagnosis, 'disease_name') else 'DiseaseName'
        confidence_field = 'confidence_score' if hasattr(Diagnosis, 'confidence_score') else 'ConfidenceLevel'
        severity_field = 'severity' if hasattr(Diagnosis, 'severity') else 'Severity'
        
        # Build ordering
        order_by = f'-{date_field}' if date_field else '-id'
        
        # Try to get related farmer through different relationship paths
        qs = Diagnosis.objects.all()
        
        # Try to select_related with possible relationship names
        possible_relations = ['plant__farmer', 'PlantID__FarmerID', 'farmer', 'user']
        for relation in possible_relations:
            try:
                qs = qs.select_related(relation)
                break
            except:
                continue
        
        qs = qs.order_by(order_by)[:12]
        
        rows = []
        for d in qs:
            # Try to get farmer through various paths
            farmer = None
            if hasattr(d, 'plant') and d.plant and hasattr(d.plant, 'farmer'):
                farmer = d.plant.farmer
            elif hasattr(d, 'PlantID') and d.PlantID and hasattr(d.PlantID, 'FarmerID'):
                farmer = d.PlantID.FarmerID
            elif hasattr(d, 'farmer'):
                farmer = d.farmer
            elif hasattr(d, 'user'):
                farmer = d.user
            
            farmer_name = '—'
            farmer_id = None
            if farmer:
                farmer_name = getattr(farmer, 'username', None) or getattr(farmer, 'email', None) or '—'
                farmer_id = getattr(farmer, 'id', None) or getattr(farmer, 'pk', None)
            
            # Get disease name
            disease = _get_field_value(d, disease_field, 'disease_name', 'DiseaseName') or 'Unknown'
            
            # Get confidence
            confidence = _get_field_value(d, confidence_field, 'confidence_score', 'ConfidenceLevel')
            
            # Get severity
            severity = _get_field_value(d, severity_field, 'severity', 'Severity') or ''
            
            # Get date
            diag_date = _get_field_value(d, date_field, 'date_diagnosed', 'DateDiagnosed')
            date_str = diag_date.strftime('%d %b %Y') if diag_date else '—'
            
            rows.append({
                'farmer':     farmer_name,
                'farmer_id':  farmer_id,
                'disease':    disease.replace('_', ' ').title(),
                'confidence': confidence,
                'severity':   severity,
                'date':       date_str,
            })
        
        return JsonResponse(rows, safe=False)
    except Exception as e:
        logger.exception("Recent diagnoses failed")
        return JsonResponse({'error': str(e)}, status=500)


# ============================================================
# 3.  DISEASE BREAKDOWN  —  /admin/disease-breakdown/
# ============================================================
@staff_member_required
def disease_breakdown(request):
    try:
        disease_field = 'disease_name' if hasattr(Diagnosis, 'disease_name') else 'DiseaseName'
        
        qs = (
            Diagnosis.objects
            .values(disease_field)
            .annotate(count=Count('id'))
            .order_by('-count')[:8]
        )
        
        data = [
            {
                'name':  row[disease_field].replace('_', ' ').title(),
                'count': row['count'],
            }
            for row in qs if row[disease_field]
        ]
        
        return JsonResponse(data, safe=False)
    except Exception as e:
        logger.exception("Disease breakdown failed")
        return JsonResponse({'error': str(e)}, status=500)


# ============================================================
# 4.  RECENT ACTIVITY  —  /admin/recent-activity/
# ============================================================
@staff_member_required
def recent_activity(request):
    try:
        action_map = {
            ADDITION: ('addition', 'added'),
            CHANGE:   ('change',   'updated'),
            DELETION: ('deletion', 'deleted'),
        }
        
        entries = LogEntry.objects.select_related('user').order_by('-action_time')[:10]
        
        data = []
        for entry in entries:
            action_key, action_label = action_map.get(entry.action_flag, ('change', 'modified'))
            
            # How long ago
            delta = timezone.now() - entry.action_time
            if delta.seconds < 3600:
                time_str = f"{delta.seconds // 60}m ago" if delta.seconds // 60 > 0 else "just now"
            elif delta.days == 0:
                time_str = f"{delta.seconds // 3600}h ago"
            else:
                time_str = f"{delta.days}d ago"
            
            user_name = entry.user.get_full_name() if entry.user else 'System'
            if not user_name or user_name == '':
                user_name = entry.user.username if entry.user else 'System'
            
            data.append({
                'user':         user_name,
                'action':       action_key,
                'action_label': action_label,
                'object':       entry.object_repr or '—',
                'time':         time_str,
            })
        
        return JsonResponse(data, safe=False)
    except Exception as e:
        logger.exception("Recent activity failed")
        return JsonResponse({'error': str(e)}, status=500)


# ============================================================
# 5.  DEBUG ENDPOINT  —  /admin/debug-fields/
# ============================================================
@staff_member_required
def debug_fields(request):
    """Debug endpoint to see actual model fields"""
    if not request.user.is_superuser:
        return JsonResponse({'error': 'Superuser required'}, status=403)
    
    try:
        weather_fields = [f.name for f in WeatherData._meta.fields]
        diagnosis_fields = [f.name for f in Diagnosis._meta.fields]
        farmer_fields = [f.name for f in Farmer._meta.fields]
        
        # Get sample data
        sample_weather = WeatherData.objects.first()
        sample_diagnosis = Diagnosis.objects.first()
        
        return JsonResponse({
            'weather_fields': weather_fields,
            'diagnosis_fields': diagnosis_fields,
            'farmer_fields': farmer_fields,
            'sample_weather': sample_weather.__dict__ if sample_weather else None,
            'sample_diagnosis': sample_diagnosis.__dict__ if sample_diagnosis else None,
        })
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)
