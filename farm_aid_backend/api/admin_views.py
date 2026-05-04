# api/admin_views.py
from django.contrib.admin.views.decorators import staff_member_required
from django.shortcuts import render
from django.db.models import Count, Q
from django.utils import timezone
from datetime import timedelta
from .models import (
    Farmer, Diagnosis, Plant, CropProfile, AppAlert, 
    Treatment, KnowledgeBase, TranslationCache
)


@staff_member_required
def admin_dashboard(request):
    """Custom admin dashboard with charts and statistics"""
    
    # Get date ranges
    today = timezone.now().date()
    last_30_days = today - timedelta(days=30)
    last_7_days = today - timedelta(days=7)
    
    # ============================================================
    # KEY METRICS
    # ============================================================
    
    # User statistics
    total_farmers = Farmer.objects.count()
    active_farmers = Farmer.objects.filter(is_active=True).count()
    new_farmers_30d = Farmer.objects.filter(date_joined__date__gte=last_30_days).count()
    
    # Scan statistics
    total_scans = Plant.objects.count()
    scans_last_30d = Plant.objects.filter(DateCaptured__date__gte=last_30_days).count()
    scans_last_7d = Plant.objects.filter(DateCaptured__date__gte=last_7_days).count()
    
    # Disease statistics
    total_diagnoses = Diagnosis.objects.count()
    healthy_scans = Diagnosis.objects.filter(DiseaseName__icontains='healthy').count()
    diseased_scans = total_diagnoses - healthy_scans
    
    # Top diseases (excluding healthy)
    top_diseases = Diagnosis.objects.exclude(
        DiseaseName__icontains='healthy'
    ).values('DiseaseName').annotate(
        count=Count('DiagnosisID')
    ).order_by('-count')[:5]
    
    # Treatment statistics
    treatments_applied = Diagnosis.objects.filter(treatment_applied=True).count()
    treatment_success = Diagnosis.objects.filter(
        treatment_applied=True, 
        treatment_outcome='recovered'
    ).count()
    
    # Alert statistics
    unread_alerts = AppAlert.objects.filter(IsRead=False).count()
    high_priority_alerts = AppAlert.objects.filter(priority='high', IsRead=False).count()
    
    # Crop statistics
    top_crops = CropProfile.objects.values('VegetableType').annotate(
        count=Count('ProfileID')
    ).order_by('-count')[:5]
    
    # Knowledge base status
    kb_total = KnowledgeBase.objects.count()
    kb_with_causes = KnowledgeBase.objects.exclude(
        Q(Causes__isnull=True) | Q(Causes='')
    ).count()
    kb_missing_causes = kb_total - kb_with_causes
    
    # Translation status
    translations_total = TranslationCache.objects.count()
    
    # ============================================================
    # CHART DATA
    # ============================================================
    
    # Daily scan data for chart (last 30 days)
    daily_scans = []
    for i in range(29, -1, -1):
        date = today - timedelta(days=i)
        count = Plant.objects.filter(DateCaptured__date=date).count()
        daily_scans.append({
            'date': date.strftime('%b %d'),
            'count': count
        })
    
    # Severity distribution
    severity_distribution = {
        'mild': Diagnosis.objects.filter(severity='mild').count(),
        'moderate': Diagnosis.objects.filter(severity='moderate').count(),
        'severe': Diagnosis.objects.filter(severity='severe').count(),
    }
    
    # Calculate percentages
    healthy_percentage = round((healthy_scans / total_diagnoses * 100), 1) if total_diagnoses > 0 else 0
    diseased_percentage = round((diseased_scans / total_diagnoses * 100), 1) if total_diagnoses > 0 else 0
    treatment_success_rate = round((treatment_success / treatments_applied * 100), 1) if treatments_applied > 0 else 0
    kb_completion = round((kb_with_causes / kb_total * 100), 1) if kb_total > 0 else 0
    
    context = {
        # Key metrics
        'total_farmers': total_farmers,
        'active_farmers': active_farmers,
        'new_farmers_30d': new_farmers_30d,
        'total_scans': total_scans,
        'scans_last_30d': scans_last_30d,
        'scans_last_7d': scans_last_7d,
        'total_diagnoses': total_diagnoses,
        'healthy_scans': healthy_scans,
        'diseased_scans': diseased_scans,
        'healthy_percentage': healthy_percentage,
        'diseased_percentage': diseased_percentage,
        'treatments_applied': treatments_applied,
        'treatment_success': treatment_success,
        'treatment_success_rate': treatment_success_rate,
        'unread_alerts': unread_alerts,
        'high_priority_alerts': high_priority_alerts,
        'kb_total': kb_total,
        'kb_with_causes': kb_with_causes,
        'kb_missing_causes': kb_missing_causes,
        'kb_completion': kb_completion,
        'translations_total': translations_total,
        
        # Chart data
        'daily_scans': daily_scans,
        'top_diseases': top_diseases,
        'top_crops': top_crops,
        'severity_distribution': severity_distribution,
        'today': today,
    }
    
    return render(request, 'api/dashboard.html', context)
