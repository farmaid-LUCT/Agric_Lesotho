

# from django.contrib.auth.models import AbstractUser
# from django.db import models
# from django.conf import settings

# # --- 1. FARMER TABLE ---
# class Farmer(AbstractUser):
#     phone_number = models.CharField(max_length=15, blank=True, null=True)
#     location = models.CharField(max_length=255, blank=True, null=True)
#     language_preferences = models.CharField(max_length=10, default='en')

#     @property
#     def role(self):
#         if self.is_superuser:
#             return "Admin"
#         return "Farmer"

#     def __str__(self):
#         return f"{self.username} ({self.role})"

# # --- 2. CROP PROFILE (Vegetable focused) ---
# class CropProfile(models.Model):
#     ProfileID = models.AutoField(primary_key=True)
#     FarmerID = models.ForeignKey(Farmer, on_delete=models.CASCADE, related_name="crop_profiles")
#     VegetableType = models.CharField(max_length=100) # e.g., "Tomato"
#     SoilEnvironment = models.CharField(max_length=100, blank=True, null=True)
#     FarmLocation = models.CharField(max_length=255, blank=True, null=True)
#     PlantingDate = models.DateField(blank=True, null=True)
#     IsActive = models.BooleanField(default=True)
#     CreatedAt = models.DateTimeField(auto_now_add=True)

#     def __str__(self):
#         return f"{self.VegetableType} Profile - {self.FarmerID.username}"

# # --- 3. PLANT TABLE (Linked to Supabase Bucket) ---
# class Plant(models.Model):
#     PlantID = models.AutoField(primary_key=True)
#     FarmerID = models.ForeignKey(Farmer, on_delete=models.CASCADE, related_name="plants")
#     CropProfile = models.ForeignKey(CropProfile, on_delete=models.SET_NULL, null=True, blank=True)
#     CropType = models.CharField(max_length=100, default='Vegetable')
#     ImageFile = models.CharField(max_length=255) # Stores Supabase Image URL
#     DateCaptured = models.DateTimeField(auto_now_add=True)

#     def __str__(self):
#         return f"{self.CropType} (ID: {self.PlantID})"

# # --- 4. DIAGNOSIS TABLE ---
# class Diagnosis(models.Model):
#     DiagnosisID = models.AutoField(primary_key=True)
#     PlantID = models.ForeignKey(Plant, on_delete=models.CASCADE, related_name="diagnoses")
#     DiseaseName = models.CharField(max_length=255) # Gemini disease name (or "Healthy")
#     ConfidenceLevel = models.FloatField()
#     DateDiagnosed = models.DateTimeField(auto_now_add=True)

#     def __str__(self):
#         return f"{self.DiseaseName} - {self.DateDiagnosed.date()}"

# # --- 5. TREATMENT TABLE ---
# class Treatment(models.Model):
#     TreatmentID = models.AutoField(primary_key=True)
#     DiseaseName = models.CharField(max_length=255, null=True, blank=True, unique=True)
#     RecommendedPesticide = models.CharField(max_length=255)
#     Dosage = models.CharField(max_length=255)
#     ApplicationSteps = models.TextField()

#     def __str__(self):
#         return f"Treatment for {self.DiseaseName}"

# # --- 6. APP ALERT ---
# class AppAlert(models.Model):
#     AlertID = models.AutoField(primary_key=True)
#     FarmerID = models.ForeignKey(Farmer, on_delete=models.CASCADE, related_name="alerts")
#     RelatedCrop = models.ForeignKey(CropProfile, on_delete=models.CASCADE, null=True, blank=True)
#     Title = models.CharField(max_length=255)
#     Message = models.TextField()
#     alert_type = models.CharField(max_length=50, default="weather") # 'weather' or 'disease'
#     IsRead = models.BooleanField(default=False)
#     DateCreated = models.DateTimeField(auto_now_add=True)

#     def __str__(self):
#         return f"{self.alert_type.upper()}: {self.Title}"

# # --- 7. WEATHER DATA ---
# class WeatherData(models.Model):
#     WeatherID = models.AutoField(primary_key=True)
#     Temperature = models.FloatField()
#     Humidity = models.IntegerField()
#     Rainfall = models.FloatField(default=0.0) 
#     AlertMessage = models.CharField(max_length=255, blank=True)
#     DateUpdated = models.DateTimeField(auto_now=True)

# # --- 8. KNOWLEDGE & AI ---
# class KnowledgeBase(models.Model):
#     EntryID = models.AutoField(primary_key=True)
#     DiseaseName = models.CharField(max_length=255, unique=True)
#     Symptoms = models.TextField()
#     TreatmentInfo = models.TextField()
#     LastUpdated = models.DateTimeField(auto_now=True)

# class AIModel(models.Model):
#     ModelID = models.AutoField(primary_key=True)
#     Version = models.CharField(max_length=50)
#     AccuracyRate = models.FloatField()
#     LastTrainedDate = models.DateTimeField()
    
# # --- 9. EXPERT SYSTEM RULES (UPDATED) ---
# class PersonalizedRule(models.Model):
#     RuleID = models.AutoField(primary_key=True)
#     # The condition from Gemini/AI
#     DiseaseName = models.CharField(max_length=255) 
    
#     # Triggers from CropProfile
#     TriggerSoilType = models.CharField(max_length=100, blank=True, null=True, help_text="e.g., Sandy, Clayey")
#     TriggerLocation = models.CharField(max_length=100, blank=True, null=True, help_text="e.g., Maseru, Leribe")
    
#     # New: Growth Stage triggers (calculated from PlantingDate)
#     MinDaysSincePlanting = models.IntegerField(default=0)
#     MaxDaysSincePlanting = models.IntegerField(default=999)
    
#     # The Expert Output
#     ExpertAdvice = models.TextField()
#     RecommendationCategory = models.CharField(max_length=50, default="General", help_text="e.g., Irrigation, Nutrition")

#     def __str__(self):
#         return f"Rule: {self.DiseaseName} ({self.TriggerSoilType or 'Any Soil'})"



from django.contrib.auth.models import AbstractUser
from django.db import models
from django.conf import settings

# --- 1. FARMER TABLE ---
class Farmer(AbstractUser):
    phone_number = models.CharField(max_length=15, blank=True, null=True)
    location = models.CharField(max_length=255, blank=True, null=True)
    language_preferences = models.CharField(max_length=10, default='en') # 'en' or 'st'

    @property
    def role(self):
        if self.is_superuser:
            return "Admin"
        return "Farmer"

    def __str__(self):
        return f"{self.username} ({self.role})"

# --- REFACTORED: TRANSLATION CACHE (Structured for Agricultural Advice) ---
class TranslationCache(models.Model):
    """
    Acts as a Sesotho lookup for Disease Treatments.
    Keyed by DiseaseName to match Gemini/AI output.
    """
    # We use the English Disease Name as the key (e.g., "Cabbage Alternaria Leaf Spot")
    disease_name_en = models.CharField(max_length=255, primary_key=True)
    
    # Clearly labeled Sesotho fields for the Admin to fill
    pesticide_st = models.CharField(max_length=255, verbose_name="Moriana (Sesotho)")
    dosage_st = models.CharField(max_length=255, verbose_name="Tekanyetso (Sesotho)")
    steps_st = models.TextField(verbose_name="Mekhoa ea Tšebeliso (Sesotho)")
    
    last_updated = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Sesotho Translation: {self.disease_name_en}"

# --- 2. CROP PROFILE (Vegetable focused) ---
class CropProfile(models.Model):
    ProfileID = models.AutoField(primary_key=True)
    FarmerID = models.ForeignKey(Farmer, on_delete=models.CASCADE, related_name="crop_profiles")
    VegetableType = models.CharField(max_length=100) 
    SoilEnvironment = models.CharField(max_length=100, blank=True, null=True)
    FarmLocation = models.CharField(max_length=255, blank=True, null=True)
    PlantingDate = models.DateField(blank=True, null=True)
    IsActive = models.BooleanField(default=True)
    CreatedAt = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.VegetableType} Profile - {self.FarmerID.username}"

# --- 3. PLANT TABLE (Linked to Supabase Bucket) ---
class Plant(models.Model):
    PlantID = models.AutoField(primary_key=True)
    FarmerID = models.ForeignKey(Farmer, on_delete=models.CASCADE, related_name="plants")
    CropProfile = models.ForeignKey(CropProfile, on_delete=models.SET_NULL, null=True, blank=True)
    CropType = models.CharField(max_length=100, default='Vegetable')
    ImageFile = models.CharField(max_length=255) # Supabase Image URL
    DateCaptured = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.CropType} (ID: {self.PlantID})"

# --- 4. DIAGNOSIS TABLE ---
class Diagnosis(models.Model):
    DiagnosisID = models.AutoField(primary_key=True)
    PlantID = models.ForeignKey(Plant, on_delete=models.CASCADE, related_name="diagnoses")
    DiseaseName = models.CharField(max_length=255) 
    ConfidenceLevel = models.FloatField()
    DateDiagnosed = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.DiseaseName} - {self.DateDiagnosed.date()}"

# --- 5. TREATMENT TABLE (The English Baseline) ---
class Treatment(models.Model):
    TreatmentID = models.AutoField(primary_key=True)
    DiseaseName = models.CharField(max_length=255, null=True, blank=True, unique=True)
    RecommendedPesticide = models.CharField(max_length=255)
    Dosage = models.CharField(max_length=255)
    ApplicationSteps = models.TextField()

    def __str__(self):
        return f"English Treatment for {self.DiseaseName}"

# --- 6. APP ALERT ---
class AppAlert(models.Model):
    AlertID = models.AutoField(primary_key=True)
    FarmerID = models.ForeignKey(Farmer, on_delete=models.CASCADE, related_name="alerts")
    RelatedCrop = models.ForeignKey(CropProfile, on_delete=models.CASCADE, null=True, blank=True)
    Title = models.CharField(max_length=255)
    Message = models.TextField()
    alert_type = models.CharField(max_length=50, default="weather") 
    IsRead = models.BooleanField(default=False)
    DateCreated = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.alert_type.upper()}: {self.Title}"

# --- 7. WEATHER DATA ---
class WeatherData(models.Model):
    WeatherID = models.AutoField(primary_key=True)
    Temperature = models.FloatField()
    Humidity = models.IntegerField()
    Rainfall = models.FloatField(default=0.0) 
    AlertMessage = models.CharField(max_length=255, blank=True)
    DateUpdated = models.DateTimeField(auto_now=True)

# --- 8. KNOWLEDGE & AI ---
class KnowledgeBase(models.Model):
    EntryID = models.AutoField(primary_key=True)
    DiseaseName = models.CharField(max_length=255, unique=True)
    Symptoms = models.TextField()
    TreatmentInfo = models.TextField()
    LastUpdated = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.DiseaseName

class AIModel(models.Model):
    ModelID = models.AutoField(primary_key=True)
    Version = models.CharField(max_length=50)
    AccuracyRate = models.FloatField()
    LastTrainedDate = models.DateTimeField()
    
# --- 9. EXPERT SYSTEM RULES ---
class PersonalizedRule(models.Model):
    RuleID = models.AutoField(primary_key=True)
    DiseaseName = models.CharField(max_length=255) 
    TriggerSoilType = models.CharField(max_length=100, blank=True, null=True)
    TriggerLocation = models.CharField(max_length=100, blank=True, null=True)
    MinDaysSincePlanting = models.IntegerField(default=0)
    MaxDaysSincePlanting = models.IntegerField(default=999)
    ExpertAdvice = models.TextField()
    RecommendationCategory = models.CharField(max_length=50, default="General")

    def __str__(self):
        return f"Rule: {self.DiseaseName}"
