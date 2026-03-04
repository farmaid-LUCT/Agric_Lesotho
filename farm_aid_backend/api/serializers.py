# from rest_framework import serializers
# from .models import Diagnosis, Plant, CropProfile, AppAlert, WeatherData 

# # --- 1. CROP PROFILE SERIALIZER ---
# class CropProfileSerializer(serializers.ModelSerializer):
#     """Handles the vegetable data for personalization."""
#     class Meta:
#         model = CropProfile
#         # We include ProfileID because it's your primary key in models.py
#         fields = [
#             'ProfileID', 'FarmerID', 'VegetableType', 
#             'SoilEnvironment', 'FarmLocation', 'PlantingDate', 
#             'IsActive', 'CreatedAt'
#         ]
#         read_only_fields = ['FarmerID', 'CreatedAt']

# # --- 2. PLANT SERIALIZER ---
# class PlantSerializer(serializers.ModelSerializer):
#     """Serializes the leaf scans and links them to a Profile."""
#     # Useful for Flutter to show the vegetable name in the history list
#     vegetable_name = serializers.ReadOnlyField(source='CropProfile.VegetableType')

#     class Meta:
#         model = Plant
#         fields = [
#             'PlantID', 'FarmerID', 'CropProfile', 
#             'CropType', 'ImageFile', 'DateCaptured', 'vegetable_name'
#         ]
#         read_only_fields = ['FarmerID', 'DateCaptured']

# # --- 3. DIAGNOSIS SERIALIZER ---
# class DiagnosisSerializer(serializers.ModelSerializer):
#     PlantID = serializers.PrimaryKeyRelatedField(queryset=Plant.objects.all())

#     class Meta:
#         model = Diagnosis
#         fields = ['DiagnosisID', 'DiseaseName', 'ConfidenceLevel', 'DateDiagnosed', 'PlantID']

# # --- 4. APP ALERT SERIALIZER ---
# class AppAlertSerializer(serializers.ModelSerializer):
#     """Serializes personalized alerts for the Farmer."""
#     class Meta:
#         model = AppAlert
#         fields = [
#             'AlertID', 'FarmerID', 'Title', 'Message', 
#             'alert_type', 'IsRead', 'DateCreated', 'RelatedCrop'
#         ]
#         read_only_fields = ['FarmerID', 'DateCreated']

# # --- 5. WEATHER DATA SERIALIZER (ALIGNED TO YOUR MODELS.PY) ---
# class WeatherDataSerializer(serializers.ModelSerializer):
#     class Meta:
#         model = WeatherData
#         fields = [
#             'WeatherID',
#             'Temperature', 
#             'Humidity', 
#             'Rainfall',      # Matched to models.py
#             'AlertMessage',  # Matched to models.py
#             'DateUpdated'
#         ]

from rest_framework import serializers
from .models import (
    Diagnosis, Plant, CropProfile, AppAlert, WeatherData,
    PersonalizedRule, FarmerInsight, GrowthJournalEntry, MarketPrice,
    TranslationCache,
)


# ============================================================
# --- 1. WEATHER DATA ---
# ============================================================
class WeatherDataSerializer(serializers.ModelSerializer):
    class Meta:
        model = WeatherData
        fields = [
            'WeatherID', 'district', 'Temperature', 'Humidity',
            'Rainfall', 'rainfall_last_7_days', 'AlertMessage', 'DateUpdated',
        ]


# ============================================================
# --- 2. CROP PROFILE ---
# ============================================================
class CropProfileSerializer(serializers.ModelSerializer):
    # Read-only computed fields from model properties
    days_since_planting = serializers.SerializerMethodField()
    growth_stage_label  = serializers.SerializerMethodField()

    class Meta:
        model = CropProfile
        fields = [
            'ProfileID', 'FarmerID', 'VegetableType',
            'SoilEnvironment', 'PlantingDate', 'IsActive', 'CreatedAt',
            'plot_size_hectares', 'expected_harvest_date',
            'irrigation_method', 'seed_variety', 'notes',
            # Computed
            'days_since_planting', 'growth_stage_label',
        ]
        read_only_fields = ['FarmerID', 'CreatedAt', 'days_since_planting', 'growth_stage_label']

    def get_days_since_planting(self, obj):
        return obj.days_since_planting

    def get_growth_stage_label(self, obj):
        return obj.growth_stage_label


# ============================================================
# --- 3. PLANT ---
# ============================================================
class PlantSerializer(serializers.ModelSerializer):
    class Meta:
        model = Plant
        fields = [
            'PlantID', 'FarmerID', 'CropProfile', 'CropType',
            'ImageFile', 'latitude', 'longitude',
            'altitude_meters', 'gps_district', 'DateCaptured',
        ]
        read_only_fields = ['FarmerID', 'DateCaptured']


# ============================================================
# --- 4. DIAGNOSIS ---
# ============================================================
class DiagnosisSerializer(serializers.ModelSerializer):
    PlantID = serializers.PrimaryKeyRelatedField(queryset=Plant.objects.all())

    class Meta:
        model = Diagnosis
        fields = [
            'DiagnosisID', 'PlantID', 'DiseaseName', 'ConfidenceLevel',
            'DateDiagnosed', 'farmer_feedback', 'severity',
            'treatment_applied', 'treatment_outcome', 'follow_up_date',
        ]
        read_only_fields = ['DiagnosisID', 'DateDiagnosed']


# ============================================================
# --- 5. APP ALERT ---
# ============================================================
class AppAlertSerializer(serializers.ModelSerializer):
    # Human-readable time difference for Flutter UI (e.g. "2 hours ago")
    time_ago = serializers.SerializerMethodField()

    class Meta:
        model = AppAlert
        fields = [
            'AlertID', 'FarmerID', 'Title', 'Message',
            'alert_type', 'priority', 'IsRead',
            'district_target', 'expires_at',
            'DateCreated', 'RelatedCrop',
            # Computed
            'time_ago',
        ]
        read_only_fields = ['FarmerID', 'DateCreated']

    def get_time_ago(self, obj):
        from django.utils import timezone
        from django.utils.timesince import timesince
        return f"{timesince(obj.DateCreated, timezone.now())} ago"


# ============================================================
# --- 6. PERSONALIZED RULE ---
# ============================================================
class PersonalizedRuleSerializer(serializers.ModelSerializer):
    """
    Returns the matched rule result to Flutter.
    Flutter uses 'category' to pick the correct icon/card colour.
    """
    class Meta:
        model = PersonalizedRule
        fields = [
            'RuleID', 'DiseaseName',
            'TriggerDistrict', 'TriggerSoilType', 'TriggerIrrigation',
            'TriggerCropVariety', 'TriggerSeason', 'TriggerRainfallLevel',
            'MinDaysSincePlanting', 'MaxDaysSincePlanting',
            'ExpertAdvice', 'advice_beginner',
            'RecommendationCategory', 'priority_score',
        ]


# ============================================================
# --- 7. FARMER INSIGHT ---
# ============================================================
class FarmerInsightSerializer(serializers.ModelSerializer):
    """
    Powers personalized dashboard cards in Flutter:
    - 'Your most common disease is Early Blight'
    - 'You have a 12-day healthy streak'
    - 'Tomatoes are your highest-risk crop'
    """
    health_rate = serializers.SerializerMethodField()
    highest_risk_month_name = serializers.SerializerMethodField()

    class Meta:
        model = FarmerInsight
        fields = [
            'InsightID', 'total_scans', 'total_diseases_detected',
            'total_healthy_scans', 'most_scanned_crop', 'most_common_disease',
            'highest_risk_month', 'highest_risk_month_name',
            'last_scan_date', 'streak_healthy_days', 'last_updated',
            # Computed
            'health_rate',
        ]
        read_only_fields = fields  # All fields are computed — never written by Flutter

    def get_health_rate(self, obj):
        """Percentage of scans that came back healthy."""
        if obj.total_scans == 0:
            return 0
        return round((obj.total_healthy_scans / obj.total_scans) * 100, 1)

    def get_highest_risk_month_name(self, obj):
        """Converts month number to name for Flutter display."""
        if not obj.highest_risk_month:
            return None
        months = [
            '', 'January', 'February', 'March', 'April',
            'May', 'June', 'July', 'August', 'September',
            'October', 'November', 'December'
        ]
        return months[obj.highest_risk_month]


# ============================================================
# --- 8. GROWTH JOURNAL ---
# ============================================================
class GrowthJournalSerializer(serializers.ModelSerializer):
    crop_name = serializers.SerializerMethodField()

    class Meta:
        model = GrowthJournalEntry
        fields = [
            'EntryID', 'FarmerID', 'CropProfile', 'crop_name',
            'entry_date', 'title', 'body', 'photo_url',
            'mood', 'DateCreated',
        ]
        read_only_fields = ['FarmerID', 'DateCreated', 'crop_name']

    def get_crop_name(self, obj):
        return obj.CropProfile.VegetableType if obj.CropProfile else None


# ============================================================
# --- 9. MARKET PRICE ---
# ============================================================
class MarketPriceSerializer(serializers.ModelSerializer):
    """
    Returned by MarketPriceView — pre-filtered to the farmer's
    active crops and district so Flutter just renders what it receives.
    """
    trend_icon = serializers.SerializerMethodField()

    class Meta:
        model = MarketPrice
        fields = [
            'PriceID', 'vegetable_name', 'market_name', 'district',
            'price_per_kg', 'currency', 'date_recorded',
            'price_trend', 'trend_icon',
        ]

    def get_trend_icon(self, obj):
        """Maps price trend to an icon name Flutter can use directly."""
        return {
            'rising':  'trending_up',
            'stable':  'trending_flat',
            'falling': 'trending_down',
        }.get(obj.price_trend, 'trending_flat')


# ============================================================
# --- 10. TRANSLATION CACHE ---
# ============================================================
class TranslationCacheSerializer(serializers.ModelSerializer):
    """
    Used by the admin API to review which diseases
    still need Sesotho translations filled in.
    """
    is_complete = serializers.SerializerMethodField()

    class Meta:
        model = TranslationCache
        fields = [
            'disease_name_en', 'pesticide_st', 'dosage_st',
            'steps_st', 'last_updated', 'is_complete',
        ]

    def get_is_complete(self, obj):
        """True only when all three Sesotho fields are filled."""
        return bool(obj.pesticide_st and obj.dosage_st and obj.steps_st)
