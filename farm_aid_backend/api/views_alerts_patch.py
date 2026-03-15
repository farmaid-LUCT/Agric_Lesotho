"""
views_alerts_patch.py — FarmAid Lesotho
==========================================
DROP-IN REPLACEMENT for FarmerAlertsView + new AlertCountView.

Add to urls.py:
  path('alerts/',               FarmerAlertsView.as_view(),  name='alerts'),
  path('alerts/mark-read/',     FarmerAlertsView.as_view(),  name='mark-alerts-read'),
  path('alerts/unread-count/',  AlertCountView.as_view(),    name='alerts-unread-count'),

The /alerts/unread-count/ endpoint powers the bell-icon badge in the app.
Flutter polls it every 60 s (or on focus) and shows the red dot + number.
"""

from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.db.models import Q
from django.utils import timezone

from .models import AppAlert
from .serializers import AppAlertSerializer


class FarmerAlertsView(APIView):
    """
    GET  /api/alerts/           → list all alerts for this farmer
    POST /api/alerts/mark-read/ → mark all unread alerts as read
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user      = request.user
        user_dist = (user.district or "").strip()

        # Fetch alerts addressed to this farmer OR broadcast to their district
        qs = AppAlert.objects.filter(
            Q(FarmerID=user)
            | Q(district_target__iexact=user_dist, FarmerID__isnull=True)
        ).order_by("-DateCreated")

        # Expire old alerts silently
        now = timezone.now()
        qs  = qs.exclude(expires_at__lt=now)

        # Apply type filter if provided
        alert_type = request.query_params.get("type")
        if alert_type:
            qs = qs.filter(alert_type=alert_type)

        data = AppAlertSerializer(qs, many=True).data
        return Response({
            "count":        qs.count(),
            "unread_count": qs.filter(IsRead=False).count(),
            "alerts":       data,
        })

    def post(self, request):
        """Mark all unread alerts as read."""
        updated = AppAlert.objects.filter(
            FarmerID=request.user, IsRead=False
        ).update(IsRead=True)
        return Response({"status": "success", "marked_read": updated})


class AlertCountView(APIView):
    """
    GET /api/alerts/unread-count/
    Lightweight endpoint — returns just the unread badge count.
    Used by the Flutter bell icon so it doesn't fetch full alert payloads.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        now       = timezone.now()
        user_dist = (request.user.district or "").strip()

        count = AppAlert.objects.filter(
            Q(FarmerID=request.user)
            | Q(district_target__iexact=user_dist, FarmerID__isnull=True),
            IsRead=False,
        ).exclude(expires_at__lt=now).count()

        return Response({"unread_count": count})
