
from rest_framework import serializers
from .models import Diagnosis, Plant, CropProfile, AppAlert

# --- 1. CROP PROFILE SERIALIZER ---
class CropProfileSerializer(serializers.ModelSerializer):
    """Handles the optional form data for personalization."""
    class Meta:
        model = CropProfile
        fields = [
            'ProfileID', 'FarmerID', 'VegetableType', 
            'SoilEnvironment', 'FarmLocation', 'PlantingDate', 
            'IsActive', 'CreatedAt'
        ]
        read_only_fields = ['FarmerID'] # Set automatically in the View

# --- 2. PLANT SERIALIZER ---
class PlantSerializer(serializers.ModelSerializer):
    """Serializes the leaf scans."""
    class Meta:
        model = Plant
        fields = [
            'PlantID', 'FarmerID', 'CropProfile', 
            'CropType', 'ImageFile', 'DateCaptured'
        ]
        read_only_fields = ['FarmerID']

# --- 3. DIAGNOSIS SERIALIZER ---
class DiagnosisSerializer(serializers.ModelSerializer):
    # Keeping your PrimaryKeyRelatedField logic so Flutter sends the ID
    PlantID = serializers.PrimaryKeyRelatedField(queryset=Plant.objects.all())

    class Meta:
        model = Diagnosis
        fields = ['DiagnosisID', 'DiseaseName', 'ConfidenceLevel', 'DateDiagnosed', 'PlantID']

# --- 4. APP ALERT SERIALIZER ---
class AppAlertSerializer(serializers.ModelSerializer):
    """Serializes personalized alerts for the Farmer."""
    class Meta:
        model = AppAlert
        # Added 'alert_type' to match the icon logic in your Flutter AlertsScreen
        fields = [
            'AlertID', 
            'FarmerID', 
            'Title', 
            'Message', 
            'alert_type', 
            'is_read', 
            'DateCreated', 
            'RelatedCrop'
        ]
        read_only_fields = ['FarmerID', 'DateCreated']




# from rest_framework import serializers
# from .models import (
#     Diagnosis, Plant, CropProfile, AppAlert, 
#     WeatherData, PersonalizedRule, Farmer # Added Farmer
# )

# # --- 1. FARMER SERIALIZER (Crucial for Language & Profile) ---
# class FarmerSerializer(serializers.ModelSerializer):
#     """Handles updating farmer profile and language preferences."""
#     class Meta:
#         model = Farmer
#         fields = [
#             'id', 'first_name', 'last_name', 'email', 
#             'phone_number', 'location', 'language_preferences'
#         ]
#         read_only_fields = ['id', 'email'] # Email shouldn't change via profile update

# # --- 2. WEATHER DATA SERIALIZER ---
# class WeatherDataSerializer(serializers.ModelSerializer):
#     class Meta:
#         model = WeatherData
#         fields = [
#             'WeatherID', 'Temperature', 'Humidity', 
#             'Rainfall', 'AlertMessage', 'Timestamp'
#         ]

# # --- 3. CROP PROFILE SERIALIZER ---
# class CropProfileSerializer(serializers.ModelSerializer):
#     class Meta:
#         model = CropProfile
#         fields = [
#             'ProfileID', 'FarmerID', 'VegetableType', 
#             'SoilEnvironment', 'FarmLocation', 'PlantingDate', 
#             'IsActive', 'CreatedAt'
#         ]
#         read_only_fields = ['FarmerID']

# # --- 4. PLANT SERIALIZER ---
# class PlantSerializer(serializers.ModelSerializer):
#     class Meta:
#         model = Plant
#         fields = [
#             'PlantID', 'FarmerID', 'CropProfile', 
#             'CropType', 'ImageFile', 'DateCaptured'
#         ]
#         read_only_fields = ['FarmerID']

# # --- 5. DIAGNOSIS SERIALIZER ---
# class DiagnosisSerializer(serializers.ModelSerializer):
#     PlantID = serializers.PrimaryKeyRelatedField(queryset=Plant.objects.all())
#     class Meta:
#         model = Diagnosis
#         fields = ['DiagnosisID', 'DiseaseName', 'ConfidenceLevel', 'DateDiagnosed', 'PlantID']

# # --- 6. APP ALERT SERIALIZER ---
# class AppAlertSerializer(serializers.ModelSerializer):
#     class Meta:
#         model = AppAlert
#         fields = [
#             'AlertID', 'FarmerID', 'Title', 'Message', 
#             'alert_type', 'IsRead', 'DateCreated', 'RelatedCrop'
#         ]
#         read_only_fields = ['FarmerID', 'DateCreated']

# # --- 7. PERSONALIZED RULE SERIALIZER ---
# class PersonalizedRuleSerializer(serializers.ModelSerializer):
#     class Meta:
#         model = PersonalizedRule
#         fields = [
#             'RuleID', 'DiseaseName', 'ExpertAdvice', 'RecommendationCategory'
#         ]
