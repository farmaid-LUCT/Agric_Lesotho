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
from django.utils import timezone
from django.utils.timesince import timesince
from .models import (
    Diagnosis, Plant, CropProfile, AppAlert, WeatherData,
    PersonalizedRule, FarmerInsight, GrowthJournalEntry, MarketPrice,
    TranslationCache,
)

# ============================================================
# --- 1. WEATHER DATA ---
# ============================================================
class WeatherDataSerializer(serializers.ModelSerializer):
    # Helps Flutter decide if it should show a rain icon or warning
    is_rainy = serializers.SerializerMethodField()

    class Meta:
        model = WeatherData
        fields = [
            'WeatherID', 'district', 'Temperature', 'Humidity',
            'Rainfall', 'rainfall_last_7_days', 'AlertMessage', 
            'DateUpdated', 'is_rainy',
        ]

    def get_is_rainy(self, obj):
        return obj.Rainfall > 0 or obj.rainfall_last_7_days > 10.0


# ============================================================
# --- 2. CROP PROFILE ---
# ============================================================
class CropProfileSerializer(serializers.ModelSerializer):
    days_since_planting = serializers.SerializerMethodField()
    growth_stage_label = serializers.SerializerMethodField()

    class Meta:
        model = CropProfile
        fields = [
            'ProfileID', 'FarmerID', 'VegetableType',
            'SoilEnvironment', 'PlantingDate', 'IsActive', 'CreatedAt',
            'plot_size_hectares', 'expected_harvest_date',
            'irrigation_method', 'seed_variety', 'notes',
            'days_since_planting', 'growth_stage_label',
        ]
        read_only_fields = ['FarmerID', 'CreatedAt']

    def get_days_since_planting(self, obj):
        return obj.days_since_planting

    def get_growth_stage_label(self, obj):
        return obj.growth_stage_label


# ============================================================
# --- 3. PLANT ---
# ============================================================
class PlantSerializer(serializers.ModelSerializer):
    """
    Includes Supabase Image URLs and GPS coordinates for the map view.
    """
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
    # Primary Key for the scan result
    confidence_percentage = serializers.SerializerMethodField()

    class Meta:
        model = Diagnosis
        fields = [
            'DiagnosisID', 'PlantID', 'DiseaseName', 'ConfidenceLevel',
            'confidence_percentage', 'DateDiagnosed', 'farmer_feedback', 
            'severity', 'treatment_applied', 'treatment_outcome', 'follow_up_date',
        ]
        read_only_fields = ['DiagnosisID', 'DateDiagnosed']

    def get_confidence_percentage(self, obj):
        return f"{int(obj.ConfidenceLevel * 100)}%"


# ============================================================
# --- 5. APP ALERT ---
# ============================================================
class AppAlertSerializer(serializers.ModelSerializer):
    time_ago = serializers.SerializerMethodField()

    class Meta:
        model = AppAlert
        fields = [
            'AlertID', 'FarmerID', 'Title', 'Message',
            'alert_type', 'priority', 'IsRead',
            'district_target', 'expires_at',
            'DateCreated', 'RelatedCrop',
            'time_ago',
        ]
        read_only_fields = ['FarmerID', 'DateCreated']

    def get_time_ago(self, obj):
        return f"{timesince(obj.DateCreated, timezone.now())} ago"


# ============================================================
# --- 6. PERSONALIZED RULE (RULE ENGINE OUTPUT) ---
# ============================================================
class PersonalizedRuleSerializer(serializers.ModelSerializer):
    """
    Returns the specific advice generated by the 8-Factor Engine.
    """
    class Meta:
        model = PersonalizedRule
        fields = [
            'RuleID', 'DiseaseName', 'ExpertAdvice', 'advice_beginner',
            'RecommendationCategory', 'priority_score',
        ]


# ============================================================
# --- 7. FARMER INSIGHT (DASHBOARD) ---
# ============================================================
class FarmerInsightSerializer(serializers.ModelSerializer):
    health_rate = serializers.SerializerMethodField()
    highest_risk_month_name = serializers.SerializerMethodField()

    class Meta:
        model = FarmerInsight
        fields = [
            'InsightID', 'total_scans', 'total_diseases_detected',
            'total_healthy_scans', 'most_scanned_crop', 'most_common_disease',
            'highest_risk_month', 'highest_risk_month_name',
            'last_scan_date', 'streak_healthy_days', 'last_updated',
            'health_rate',
        ]
        read_only_fields = fields 

    def get_health_rate(self, obj):
        if obj.total_scans == 0: return 0
        return round((obj.total_healthy_scans / obj.total_scans) * 100, 1)

    def get_highest_risk_month_name(self, obj):
        if not obj.highest_risk_month: return None
        months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
        return months[obj.highest_risk_month]


# ============================================================
# --- 8. GROWTH JOURNAL ---
# ============================================================
class GrowthJournalSerializer(serializers.ModelSerializer):
    crop_name = serializers.SerializerMethodField()
    formatted_date = serializers.SerializerMethodField()

    class Meta:
        model = GrowthJournalEntry
        fields = [
            'EntryID', 'FarmerID', 'CropProfile', 'crop_name',
            'entry_date', 'formatted_date', 'title', 'body', 
            'photo_url', 'mood', 'DateCreated',
        ]
        read_only_fields = ['FarmerID', 'DateCreated']

    def get_crop_name(self, obj):
        return obj.CropProfile.VegetableType if obj.CropProfile else "General"

    def get_formatted_date(self, obj):
        return obj.entry_date.strftime("%d %b %Y")


# ============================================================
# --- 9. MARKET PRICE ---
# ============================================================
class MarketPriceSerializer(serializers.ModelSerializer):
    trend_icon = serializers.SerializerMethodField()

    class Meta:
        model = MarketPrice
        fields = [
            'PriceID', 'vegetable_name', 'market_name', 'district',
            'price_per_kg', 'currency', 'date_recorded',
            'price_trend', 'trend_icon',
        ]

    def get_trend_icon(self, obj):
        mapping = {'rising': 'trending_up', 'stable': 'trending_flat', 'falling': 'trending_down'}
        return mapping.get(obj.price_trend, 'trending_flat')


# ============================================================
# --- 10. TRANSLATION CACHE ---
# ============================================================
class TranslationCacheSerializer(serializers.ModelSerializer):
    """
    Used by Admin to see which Sesotho translations are missing.
    """
    is_complete = serializers.SerializerMethodField()

    class Meta:
        model = TranslationCache
        fields = [
            'disease_name_en', 'pesticide_st', 'dosage_st',
            'steps_st', 'last_updated', 'is_complete',
        ]

    def get_is_complete(self, obj):
        return all([obj.pesticide_st, obj.dosage_st, obj.steps_st])
