# from rest_framework import serializers
# from .models import Diagnosis, Plant, CropProfile, AppAlert, WeatherData


# # --- 1. CROP PROFILE SERIALIZER ---
# class CropProfileSerializer(serializers.ModelSerializer):
#     """Handles the vegetable data for personalization."""

#     # Computed property from PlantingDate — read-only, used by rule engine
#     # as one of the 9 matching factors (seedling / vegetative / flowering / etc.)
#     growth_stage = serializers.ReadOnlyField(source='growth_stage_label')

#     class Meta:
#         model = CropProfile
#         fields = [
#             'ProfileID',
#             'FarmerID',
#             'VegetableType',
#             'SoilEnvironment',
#             'PlantingDate',
#             'IsActive',
#             'CreatedAt',
#             'plot_size_hectares',
#             'expected_harvest_date',
#             'irrigation_method',
#             'seed_variety',
#             'growth_stage',   # derived from PlantingDate via days_since_planting
#             'notes',
#         ]
#         read_only_fields = ['FarmerID', 'CreatedAt', 'growth_stage']


# # --- 2. PLANT SERIALIZER ---
# class PlantSerializer(serializers.ModelSerializer):
#     """Serializes the leaf scans and links them to a Profile."""
#     vegetable_name = serializers.ReadOnlyField(source='CropProfile.VegetableType')

#     class Meta:
#         model = Plant
#         fields = [
#             'PlantID', 'FarmerID', 'CropProfile',
#             'CropType', 'ImageFile', 'DateCaptured', 'vegetable_name',
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
#             'alert_type', 'IsRead', 'DateCreated', 'RelatedCrop',
#         ]
#         read_only_fields = ['FarmerID', 'DateCreated']


# # --- 5. WEATHER DATA SERIALIZER ---
# class WeatherDataSerializer(serializers.ModelSerializer):
#     class Meta:
#         model = WeatherData
#         fields = [
#             'WeatherID',
#             'district',
#             'Temperature',
#             'Humidity',
#             'Rainfall',              # legacy field — kept for backwards compat
#             'rainfall_last_7_days',  # used by RuleMatchingService for rainfall level
#             'AlertMessage',
#             'DateUpdated',
#         ]

# POko sa jwalane

from rest_framework import serializers
from .models import Diagnosis, Plant, CropProfile, AppAlert, WeatherData


# --- 1. CROP PROFILE SERIALIZER ---
class CropProfileSerializer(serializers.ModelSerializer):
    """Handles the vegetable data for personalization."""
    # Computed property from PlantingDate — read-only, used by rule engine
    # as one of the 9 matching factors (seedling / vegetative / flowering / etc.)
    growth_stage = serializers.ReadOnlyField(source='growth_stage_label')

    class Meta:
        model = CropProfile
        fields = [
            'ProfileID',
            'FarmerID',
            'VegetableType',
            'SoilEnvironment',
            'PlantingDate',
            'IsActive',
            'CreatedAt',
            'plot_size_hectares',
            'expected_harvest_date',
            'irrigation_method',
            'seed_variety',
            'growth_stage',   # derived from PlantingDate via days_since_planting
            'notes',
        ]
        read_only_fields = ['FarmerID', 'CreatedAt', 'growth_stage']


# --- 2. PLANT SERIALIZER ---
class PlantSerializer(serializers.ModelSerializer):
    """Serializes the leaf scans and links them to a Profile."""
    vegetable_name = serializers.ReadOnlyField(source='CropProfile.VegetableType')

    class Meta:
        model = Plant
        fields = [
            'PlantID', 'FarmerID', 'CropProfile',
            'CropType', 'ImageFile', 'DateCaptured', 'vegetable_name',
        ]
        read_only_fields = ['FarmerID', 'DateCaptured']


# --- 3. DIAGNOSIS SERIALIZER ---
class DiagnosisSerializer(serializers.ModelSerializer):
    PlantID = serializers.PrimaryKeyRelatedField(queryset=Plant.objects.all())

    class Meta:
        model = Diagnosis
        fields = ['DiagnosisID', 'DiseaseName', 'ConfidenceLevel', 'DateDiagnosed', 'PlantID']


# --- 4. APP ALERT SERIALIZER ---
class AppAlertSerializer(serializers.ModelSerializer):
    """Serializes personalized alerts for the Farmer."""
    class Meta:
        model = AppAlert
        fields = [
            'AlertID',
            'FarmerID',
            'Title',
            'Message',
            'alert_type',
            'IsRead',
            'DateCreated',
            'RelatedCrop',
            'priority',          # FIX: was missing — needed for Flutter urgency badge
            'district_target',   # FIX: was missing — used by FarmerAlertsView filter
            'expires_at',        # FIX: was missing — used by FarmerAlertsView exclude
        ]
        read_only_fields = ['FarmerID', 'DateCreated']


# --- 5. WEATHER DATA SERIALIZER ---
class WeatherDataSerializer(serializers.ModelSerializer):
    class Meta:
        model = WeatherData
        fields = [
            'WeatherID',
            'district',
            'Temperature',
            'Humidity',
            'Rainfall',              # legacy field — kept for backwards compat
            'rainfall_last_7_days',  # used by RuleMatchingService for rainfall level
            'AlertMessage',
            'DateUpdated',
        ]
