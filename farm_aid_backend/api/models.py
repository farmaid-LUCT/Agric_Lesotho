
# from django.contrib.auth.models import AbstractUser
# from django.db import models
# from django.utils import timezone
# from django.core.validators import MinValueValidator, MaxValueValidator


# # ============================================================
# # --- 1. FARMER ---
# # ============================================================
# class Farmer(AbstractUser):
#     phone_number         = models.CharField(max_length=15, blank=True, null=True)
#     district             = models.CharField(max_length=100, blank=True, null=True)
#     language_preferences = models.CharField(max_length=10, default='en')
#     profile_photo_url    = models.CharField(max_length=500, blank=True, null=True)
#     farm_size_hectares   = models.FloatField(blank=True, null=True)

#     EXPERIENCE_CHOICES = [
#         ('beginner',     'Beginner'),
#         ('intermediate', 'Intermediate'),
#         ('expert',       'Expert'),
#     ]
#     experience_level = models.CharField(
#         max_length=20, choices=EXPERIENCE_CHOICES, default='beginner',
#     )
#     notification_diseases = models.BooleanField(default=True)
#     notification_weather  = models.BooleanField(default=True)
#     notification_market   = models.BooleanField(default=False)
#     onboarding_complete   = models.BooleanField(default=False)
#     last_active           = models.DateTimeField(null=True, blank=True)

#     @property
#     def role(self):
#         return "Admin" if self.is_superuser else "Farmer"

#     def __str__(self):
#         return f"{self.username} ({self.role})"


# # ============================================================
# # --- 2. CROP PROFILE ---
# # ============================================================
# class CropProfile(models.Model):
#     SOIL_CHOICES = [
#         ('sandy',      'Sandy'),
#         ('clay',       'Clay'),
#         ('loam',       'Loam'),
#         ('silt',       'Silt'),
#         ('sandy_loam', 'Sandy Loam'),
#         ('clay_loam',  'Clay Loam'),
#     ]
#     IRRIGATION_CHOICES = [
#         ('rain',      'Rain-fed'),
#         ('drip',      'Drip Irrigation'),
#         ('flood',     'Flood Irrigation'),
#         ('sprinkler', 'Sprinkler'),
#     ]

#     ProfileID       = models.AutoField(primary_key=True)
#     FarmerID        = models.ForeignKey(Farmer, on_delete=models.CASCADE, related_name="crop_profiles")
#     VegetableType   = models.CharField(max_length=100)
#     SoilEnvironment = models.CharField(max_length=20, choices=SOIL_CHOICES, blank=True, null=True)
#     PlantingDate    = models.DateField(blank=True, null=True)
#     IsActive        = models.BooleanField(default=True)
#     CreatedAt       = models.DateTimeField(auto_now_add=True)

#     plot_size_hectares    = models.FloatField(blank=True, null=True)
#     expected_harvest_date = models.DateField(blank=True, null=True)
#     irrigation_method     = models.CharField(max_length=20, choices=IRRIGATION_CHOICES, default='rain')
#     seed_variety          = models.CharField(max_length=100, blank=True, null=True)
#     notes                 = models.TextField(blank=True, null=True)

#     @property
#     def days_since_planting(self):
#         if self.PlantingDate:
#             return (timezone.now().date() - self.PlantingDate).days
#         return None

#     @property
#     def growth_stage_label(self):
#         days = self.days_since_planting
#         if days is None: return "Unknown"
#         if days < 14:    return "Seedling"
#         elif days < 45:  return "Vegetative"
#         elif days < 75:  return "Flowering"
#         else:            return "Fruiting / Harvest"

#     def __str__(self):
#         return f"{self.VegetableType} ({self.growth_stage_label}) - {self.FarmerID.username}"


# # ============================================================
# # --- 3. PLANT ---
# # ============================================================
# class Plant(models.Model):
#     PlantID     = models.AutoField(primary_key=True)
#     FarmerID    = models.ForeignKey(Farmer, on_delete=models.CASCADE, related_name="plants")
#     CropProfile = models.ForeignKey(CropProfile, on_delete=models.SET_NULL, null=True, blank=True)
#     CropType    = models.CharField(max_length=100, default='Vegetable')
#     ImageFile   = models.CharField(max_length=255)

#     latitude        = models.FloatField(blank=True, null=True)
#     longitude       = models.FloatField(blank=True, null=True)
#     altitude_meters = models.FloatField(blank=True, null=True)
#     gps_district    = models.CharField(max_length=100, blank=True, null=True)
#     DateCaptured    = models.DateTimeField(auto_now_add=True)

#     def __str__(self):
#         return f"{self.CropType} (ID: {self.PlantID}) @ ({self.latitude}, {self.longitude})"


# # ============================================================
# # --- 4. DIAGNOSIS ---
# # ============================================================
# class Diagnosis(models.Model):
#     FEEDBACK_CHOICES = [
#         ('correct',   'Correct'),
#         ('incorrect', 'Incorrect'),
#         ('unsure',    'Not Sure'),
#     ]
#     SEVERITY_CHOICES = [
#         ('mild',     'Mild'),
#         ('moderate', 'Moderate'),
#         ('severe',   'Severe'),
#     ]

#     DiagnosisID     = models.AutoField(primary_key=True)
#     PlantID         = models.ForeignKey(Plant, on_delete=models.CASCADE, related_name="diagnoses")
#     DiseaseName     = models.CharField(max_length=255)
#     ConfidenceLevel = models.FloatField()
#     DateDiagnosed   = models.DateTimeField(auto_now_add=True)

#     farmer_feedback   = models.CharField(max_length=20, choices=FEEDBACK_CHOICES, blank=True, null=True)
#     severity          = models.CharField(max_length=20, choices=SEVERITY_CHOICES, blank=True, null=True)
#     treatment_applied = models.BooleanField(default=False)
#     treatment_outcome = models.CharField(
#         max_length=20,
#         choices=[('recovered','Recovered'),('no_change','No Change'),('worsened','Worsened')],
#         blank=True, null=True,
#     )
#     follow_up_date = models.DateField(blank=True, null=True)

#     def __str__(self):
#         return f"{self.DiseaseName} ({self.ConfidenceLevel:.0%}) - {self.DateDiagnosed.date()}"


# # ============================================================
# # --- 5. TREATMENT (with structured dosage fields) ---
# # ============================================================
# class Treatment(models.Model):
#     """
#     RecommendedPesticide  — product name e.g. "Mancozeb 80 WP"
#     Dosage                — free-text fallback e.g. "25g per 10L per hectare"

#     Structured dosage fields (used for automatic calculation):
#       dosage_per_hectare_g   — grams OR ml of product per hectare
#       dosage_unit            — 'g' or 'ml'
#       water_per_hectare_l    — litres of water needed per hectare

#     Calculation in SaveScanView:
#       product_amount = dosage_per_hectare_g  × plot_size_hectares
#       water_volume   = water_per_hectare_l   × plot_size_hectares
#       buckets        = water_volume ÷ 10
#     """
#     UNIT_CHOICES = [
#         ('g',  'Grams (g)'),
#         ('ml', 'Millilitres (ml)'),
#     ]

#     TreatmentID          = models.AutoField(primary_key=True)
#     DiseaseName          = models.CharField(max_length=255, null=True, blank=True, unique=True)
#     RecommendedPesticide = models.CharField(max_length=255)
#     Dosage               = models.CharField(max_length=255)   # free-text fallback
#     ApplicationSteps     = models.TextField()

#     # ── Structured dosage fields ──────────────────────────────────────────
#     dosage_per_hectare_g = models.FloatField(
#         blank=True, null=True,
#         help_text="Grams or ml of product needed per hectare (e.g. 25 for 25g/ha)",
#     )
#     dosage_unit = models.CharField(
#         max_length=5, choices=UNIT_CHOICES, default='g',
#         help_text="Unit for dosage_per_hectare_g — 'g' or 'ml'",
#     )
#     water_per_hectare_l = models.FloatField(
#         blank=True, null=True,
#         help_text="Litres of water per hectare (e.g. 200 for standard field sprayer)",
#     )

#     def calculate_for_plot(self, plot_size_hectares: float) -> dict:
#         """
#         Returns calculated amounts for a specific plot size.
#         Returns empty dict if structured fields not populated.
#         """
#         if not all([
#             self.dosage_per_hectare_g,
#             self.water_per_hectare_l,
#             plot_size_hectares,
#         ]):
#             return {}

#         product_amount = round(self.dosage_per_hectare_g * plot_size_hectares, 1)
#         water_volume   = round(self.water_per_hectare_l  * plot_size_hectares, 1)
#         buckets        = round(water_volume / 10, 1)

#         result = {
#             'product_amount': product_amount,
#             'dosage_unit':    self.dosage_unit,
#             'water_litres':   water_volume,
#             'buckets_10l':    buckets,
#             'plot_hectares':  plot_size_hectares,
#             # Formatted display strings for Flutter
#             'product_display': f"{product_amount}{self.dosage_unit}",
#             'water_display':   f"{water_volume}L ({buckets} × 10L buckets)",
#         }

#         return result

#     def __str__(self):
#         return f"Treatment for {self.DiseaseName}"


# # ============================================================
# # --- 6. APP ALERT ---
# # ============================================================
# class AppAlert(models.Model):
#     ALERT_TYPE_CHOICES = [
#         ('weather',  'Weather'),
#         ('disease',  'Disease Outbreak'),
#         ('market',   'Market Price'),
#         ('reminder', 'Crop Reminder'),
#         ('system',   'System'),
#     ]
#     PRIORITY_CHOICES = [
#         ('low',    'Low'),
#         ('medium', 'Medium'),
#         ('high',   'High — Urgent'),
#     ]

#     AlertID     = models.AutoField(primary_key=True)
#     FarmerID    = models.ForeignKey(Farmer, on_delete=models.CASCADE, related_name="alerts")
#     RelatedCrop = models.ForeignKey(CropProfile, on_delete=models.CASCADE, null=True, blank=True)
#     Title       = models.CharField(max_length=255)
#     Message     = models.TextField()
#     alert_type  = models.CharField(max_length=50, choices=ALERT_TYPE_CHOICES, default="weather")
#     IsRead      = models.BooleanField(default=False)
#     DateCreated = models.DateTimeField(auto_now_add=True)
#     priority    = models.CharField(max_length=10, choices=PRIORITY_CHOICES, default='medium')
#     district_target = models.CharField(max_length=100, blank=True, null=True)
#     expires_at  = models.DateTimeField(blank=True, null=True)

#     def __str__(self):
#         return f"[{self.priority.upper()}] {self.alert_type.upper()}: {self.Title}"


# # ============================================================
# # --- 7. WEATHER DATA ---
# # ============================================================
# class WeatherData(models.Model):
#     WeatherID            = models.AutoField(primary_key=True)
#     district             = models.CharField(max_length=100, blank=True, null=True)
#     Temperature          = models.FloatField()
#     Humidity             = models.IntegerField()
#     Rainfall             = models.FloatField(default=0.0)
#     rainfall_last_7_days = models.FloatField(default=0.0)
#     AlertMessage         = models.CharField(max_length=255, blank=True)
#     DateUpdated          = models.DateTimeField(auto_now=True)

#     def __str__(self):
#         return f"Weather ({self.district}) - {self.DateUpdated.date()}"


# # ============================================================
# # --- 8. KNOWLEDGE BASE & AI ---
# # ============================================================
# class KnowledgeBase(models.Model):
#     EntryID       = models.AutoField(primary_key=True)
#     DiseaseName   = models.CharField(max_length=255, unique=True)
#     Symptoms      = models.TextField()
#     TreatmentInfo = models.TextField()
#     LastUpdated   = models.DateTimeField(auto_now=True)

#     def __str__(self):
#         return self.DiseaseName


# class AIModel(models.Model):
#     ModelID         = models.AutoField(primary_key=True)
#     Version         = models.CharField(max_length=50)
#     AccuracyRate    = models.FloatField()
#     LastTrainedDate = models.DateTimeField()


# # ============================================================
# # --- 9. TRANSLATION CACHE ---
# # ============================================================
# class TranslationCache(models.Model):
#     disease_name_en = models.CharField(max_length=255, primary_key=True)
#     pesticide_st    = models.CharField(max_length=255, verbose_name="Moriana (Sesotho)")
#     dosage_st       = models.CharField(max_length=255, verbose_name="Tekanyetso (Sesotho)")
#     steps_st        = models.TextField(verbose_name="Mekhoa ea Tšebeliso (Sesotho)")
#     last_updated    = models.DateTimeField(auto_now=True)

#     def __str__(self):
#         return f"Sesotho Translation: {self.disease_name_en}"


# # ============================================================
# # --- 10. PERSONALIZED RULE ENGINE (9-Factor) ---
# # ============================================================
# class PersonalizedRule(models.Model):
#     SOIL_CHOICES = [
#         ('sandy','Sandy'),('clay','Clay'),('loam','Loam'),
#         ('silt','Silt'),('sandy_loam','Sandy Loam'),('clay_loam','Clay Loam'),
#     ]
#     IRRIGATION_CHOICES = [
#         ('rain','Rain-fed'),('drip','Drip Irrigation'),
#         ('flood','Flood Irrigation'),('sprinkler','Sprinkler'),
#     ]
#     SEASON_CHOICES = [
#         ('dry','Dry Season (May–Sep)'),('wet','Wet Season (Oct–Apr)'),('any','Any Season'),
#     ]
#     RAINFALL_LEVEL_CHOICES = [
#         ('low','Low — < 10mm/week'),('moderate','Moderate — 10–30mm/week'),
#         ('high','High — > 30mm/week'),('any','Any'),
#     ]
#     ALTITUDE_TIER_CHOICES = [
#         ('lowland',  'Lowland — below 1800m'),
#         ('midland',  'Midland — 1800–2200m'),
#         ('highland', 'Highland — 2200–2800m'),
#         ('alpine',   'Alpine — above 2800m'),
#         ('any',      'Any altitude'),
#     ]

#     RuleID      = models.AutoField(primary_key=True)
#     DiseaseName = models.CharField(max_length=255)

#     TriggerDistrict     = models.CharField(max_length=100, blank=True, null=True)
#     TriggerAltitudeTier = models.CharField(max_length=10, choices=ALTITUDE_TIER_CHOICES, default='any')
#     TriggerSoilType     = models.CharField(max_length=20, choices=SOIL_CHOICES, blank=True, null=True)
#     TriggerIrrigation   = models.CharField(max_length=20, choices=IRRIGATION_CHOICES, blank=True, null=True)
#     MinDaysSincePlanting = models.IntegerField(default=0)
#     MaxDaysSincePlanting = models.IntegerField(default=999)
#     TriggerCropVariety  = models.CharField(max_length=100, blank=True, null=True)
#     TriggerSeason       = models.CharField(max_length=10, choices=SEASON_CHOICES, default='any')
#     TriggerRainfallLevel = models.CharField(max_length=10, choices=RAINFALL_LEVEL_CHOICES, default='any')

#     ExpertAdvice           = models.TextField()
#     advice_beginner        = models.TextField(blank=True, null=True)
#     RecommendationCategory = models.CharField(max_length=50, default="General")
#     priority_score         = models.IntegerField(default=1)

#     class Meta:
#         indexes = [
#             models.Index(fields=['DiseaseName', 'TriggerDistrict', 'TriggerAltitudeTier']),
#             models.Index(fields=['DiseaseName', 'TriggerSoilType', 'TriggerIrrigation']),
#             models.Index(fields=['DiseaseName', 'TriggerSeason',   'TriggerRainfallLevel']),
#         ]
#         ordering = ['-priority_score']

#     def __str__(self):
#         parts = [self.DiseaseName]
#         if self.TriggerDistrict:              parts.append(self.TriggerDistrict)
#         if self.TriggerAltitudeTier != 'any': parts.append(self.TriggerAltitudeTier)
#         if self.TriggerSoilType:              parts.append(self.TriggerSoilType)
#         return f"Rule: {' | '.join(parts)}"


# # ============================================================
# # --- 11. RULE MATCHING SERVICE ---
# # ============================================================
# class RuleMatchingService:
#     SEASON_MAP = {
#         1:'wet',2:'wet',3:'wet',4:'wet',
#         5:'dry',6:'dry',7:'dry',8:'dry',9:'dry',
#         10:'wet',11:'wet',12:'wet',
#     }

#     @staticmethod
#     def _classify_rainfall(mm: float) -> str:
#         if mm < 10:    return 'low'
#         elif mm <= 30: return 'moderate'
#         return 'high'

#     @staticmethod
#     def _classify_altitude(meters) -> str:
#         if meters is None: return 'any'
#         try:
#             m = float(meters)
#         except (TypeError, ValueError):
#             return 'any'
#         if m < 1800:   return 'lowland'
#         elif m < 2200: return 'midland'
#         elif m < 2800: return 'highland'
#         return 'alpine'

#     @classmethod
#     def get_best_match(cls, disease_name, farmer, crop_profile,
#                        gps_district, rainfall_mm=0.0, altitude_meters=None) -> dict:
#         from django.db.models import Q

#         current_season  = cls.SEASON_MAP.get(timezone.now().month, 'any')
#         rainfall_level  = cls._classify_rainfall(rainfall_mm)
#         altitude_tier   = cls._classify_altitude(altitude_meters)
#         days_planted    = crop_profile.days_since_planting or 0

#         matching_rules = PersonalizedRule.objects.filter(
#             Q(DiseaseName__iexact=disease_name)
#             & (Q(TriggerDistrict__iexact=gps_district) | Q(TriggerDistrict__isnull=True))
#             & (Q(TriggerAltitudeTier=altitude_tier)    | Q(TriggerAltitudeTier='any'))
#             & (Q(TriggerSoilType=crop_profile.SoilEnvironment)        | Q(TriggerSoilType__isnull=True))
#             & (Q(TriggerIrrigation=crop_profile.irrigation_method)    | Q(TriggerIrrigation__isnull=True))
#             & Q(MinDaysSincePlanting__lte=days_planted)
#             & Q(MaxDaysSincePlanting__gte=days_planted)
#             & (Q(TriggerCropVariety__iexact=crop_profile.seed_variety)| Q(TriggerCropVariety__isnull=True))
#             & (Q(TriggerSeason=current_season)         | Q(TriggerSeason='any'))
#             & (Q(TriggerRainfallLevel=rainfall_level)  | Q(TriggerRainfallLevel='any'))
#         ).order_by('-priority_score')

#         best_rule = matching_rules.first()
#         if not best_rule:
#             return {"found": False, "advice": None, "category": "General"}

#         use_simple  = (farmer.experience_level == 'beginner' and best_rule.advice_beginner)
#         advice_text = best_rule.advice_beginner if use_simple else best_rule.ExpertAdvice

#         # Fill context placeholders in advice text
#         variety_label = crop_profile.seed_variety or crop_profile.VegetableType
#         context = {
#             'district':      gps_district or 'your district',
#             'altitude_tier': altitude_tier if altitude_tier != 'any' else 'your altitude',
#             'altitude_m':    f"{int(float(altitude_meters))}m" if altitude_meters else 'unknown altitude',
#             'soil':          crop_profile.SoilEnvironment or 'your soil',
#             'irrigation':    crop_profile.irrigation_method or 'your irrigation',
#             'growth_stage':  crop_profile.growth_stage_label,
#             'variety':       variety_label,
#             'crop':          crop_profile.VegetableType,
#             'season':        current_season,
#             'rainfall':      rainfall_level,
#         }
#         try:
#             advice_text = advice_text.format(**context)
#         except (KeyError, ValueError):
#             pass

#         return {
#             "found":    True,
#             "rule_id":  best_rule.RuleID,
#             "advice":   advice_text,
#             "category": best_rule.RecommendationCategory,
#             "matched_on": {
#                 "district":      gps_district,
#                 "altitude_tier": altitude_tier,
#                 "altitude_m":    altitude_meters,
#                 "soil":          crop_profile.SoilEnvironment,
#                 "irrigation":    crop_profile.irrigation_method,
#                 "variety":       crop_profile.seed_variety,
#                 "growth_stage":  crop_profile.growth_stage_label,
#                 "season":        current_season,
#                 "rainfall":      rainfall_level,
#             },
#         }


# # ============================================================
# # --- 12. FARMER INSIGHT ---
# # ============================================================
# class FarmerInsight(models.Model):
#     InsightID               = models.AutoField(primary_key=True)
#     FarmerID                = models.OneToOneField(Farmer, on_delete=models.CASCADE, related_name="insight")
#     total_scans             = models.IntegerField(default=0)
#     total_diseases_detected = models.IntegerField(default=0)
#     total_healthy_scans     = models.IntegerField(default=0)
#     most_scanned_crop       = models.CharField(max_length=100, blank=True, null=True)
#     most_common_disease     = models.CharField(max_length=255, blank=True, null=True)
#     highest_risk_month      = models.IntegerField(blank=True, null=True,
#         validators=[MinValueValidator(1), MaxValueValidator(12)])
#     last_scan_date          = models.DateTimeField(blank=True, null=True)
#     streak_healthy_days     = models.IntegerField(default=0)
#     last_updated            = models.DateTimeField(auto_now=True)

#     def __str__(self):
#         return f"Insights: {self.FarmerID.username} | {self.total_scans} scans"


# # ============================================================
# # --- 13. GROWTH JOURNAL ---
# # ============================================================
# class GrowthJournalEntry(models.Model):
#     EntryID     = models.AutoField(primary_key=True)
#     CropProfile = models.ForeignKey(CropProfile, on_delete=models.CASCADE, related_name="journal_entries")
#     FarmerID    = models.ForeignKey(Farmer, on_delete=models.CASCADE, related_name="journal_entries")
#     entry_date  = models.DateField(default=timezone.now)
#     title       = models.CharField(max_length=200)
#     body        = models.TextField()
#     photo_url   = models.CharField(max_length=500, blank=True, null=True)
#     mood        = models.CharField(
#         max_length=20,
#         choices=[('great','Great'),('ok','OK'),('concerned','Concerned'),('bad','Bad')],
#         default='ok',
#     )
#     DateCreated = models.DateTimeField(auto_now_add=True)

#     class Meta:
#         ordering = ['-entry_date']

#     def __str__(self):
#         return f"Journal: {self.CropProfile.VegetableType} - {self.entry_date}"


# # ============================================================
# # --- 14. MARKET PRICE ---
# # ============================================================
# class MarketPrice(models.Model):
#     PriceID        = models.AutoField(primary_key=True)
#     vegetable_name = models.CharField(max_length=100)
#     market_name    = models.CharField(max_length=100)
#     district       = models.CharField(max_length=100)
#     price_per_kg   = models.DecimalField(max_digits=6, decimal_places=2)
#     currency       = models.CharField(max_length=5, default='LSL')
#     date_recorded  = models.DateField(default=timezone.now)
#     price_trend    = models.CharField(
#         max_length=10,
#         choices=[('rising','Rising'),('stable','Stable'),('falling','Falling')],
#         default='stable',
#     )

#     class Meta:
#         ordering = ['-date_recorded']

#     def __str__(self):
#         return f"{self.vegetable_name} @ {self.market_name}: LSL {self.price_per_kg}/kg"


import logging
import traceback
from datetime import date, timedelta

from django.contrib.auth.models import AbstractUser
from django.db import models
from django.db.models import Q
from django.utils import timezone
from django.core.validators import MinValueValidator, MaxValueValidator

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework import status

logger = logging.getLogger(__name__)


# ============================================================
# --- 1. FARMER ---
# ============================================================
class Farmer(AbstractUser):
    phone_number         = models.CharField(max_length=15, blank=True, null=True)
    district             = models.CharField(max_length=100, blank=True, null=True)
    language_preferences = models.CharField(max_length=10, default='en')
    profile_photo_url    = models.CharField(max_length=500, blank=True, null=True)
    farm_size_hectares   = models.FloatField(blank=True, null=True)

    EXPERIENCE_CHOICES = [
        ('beginner',     'Beginner'),
        ('intermediate', 'Intermediate'),
        ('expert',       'Expert'),
    ]
    experience_level = models.CharField(
        max_length=20, choices=EXPERIENCE_CHOICES, default='beginner',
    )
    notification_diseases = models.BooleanField(default=True)
    notification_weather  = models.BooleanField(default=True)
    notification_market   = models.BooleanField(default=False)
    onboarding_complete   = models.BooleanField(default=False)
    last_active           = models.DateTimeField(null=True, blank=True)

    @property
    def role(self):
        return "Admin" if self.is_superuser else "Farmer"

    def __str__(self):
        return f"{self.username} ({self.role})"


# ============================================================
# --- 2. CROP PROFILE ---
# ============================================================
class CropProfile(models.Model):
    SOIL_CHOICES = [
        ('sandy',      'Sandy'),
        ('clay',       'Clay'),
        ('loam',       'Loam'),
        ('silt',       'Silt'),
        ('sandy_loam', 'Sandy Loam'),
        ('clay_loam',  'Clay Loam'),
    ]
    IRRIGATION_CHOICES = [
        ('rain',      'Rain-fed'),
        ('drip',      'Drip Irrigation'),
        ('flood',     'Flood Irrigation'),
        ('sprinkler', 'Sprinkler'),
    ]

    ProfileID       = models.AutoField(primary_key=True)
    FarmerID        = models.ForeignKey(Farmer, on_delete=models.CASCADE, related_name="crop_profiles")
    VegetableType   = models.CharField(max_length=100)
    SoilEnvironment = models.CharField(max_length=20, choices=SOIL_CHOICES, blank=True, null=True)
    PlantingDate    = models.DateField(blank=True, null=True)
    IsActive        = models.BooleanField(default=True)
    CreatedAt       = models.DateTimeField(auto_now_add=True)

    plot_size_hectares    = models.FloatField(blank=True, null=True)
    expected_harvest_date = models.DateField(blank=True, null=True)
    irrigation_method     = models.CharField(max_length=20, choices=IRRIGATION_CHOICES, default='rain')
    seed_variety          = models.CharField(max_length=100, blank=True, null=True)
    notes                 = models.TextField(blank=True, null=True)

    @property
    def days_since_planting(self):
        if self.PlantingDate:
            return (timezone.now().date() - self.PlantingDate).days
        return None

    @property
    def growth_stage_label(self):
        days = self.days_since_planting
        if days is None:  return "Unknown"
        if days < 14:     return "Seedling"
        elif days < 45:   return "Vegetative"
        elif days < 75:   return "Flowering"
        else:             return "Fruiting / Harvest"

    def __str__(self):
        return f"{self.VegetableType} ({self.growth_stage_label}) - {self.FarmerID.username}"


# ============================================================
# --- 3. PLANT ---
# ============================================================
class Plant(models.Model):
    PlantID     = models.AutoField(primary_key=True)
    FarmerID    = models.ForeignKey(Farmer, on_delete=models.CASCADE, related_name="plants")
    CropProfile = models.ForeignKey(CropProfile, on_delete=models.SET_NULL, null=True, blank=True)
    CropType    = models.CharField(max_length=100, default='Vegetable')
    ImageFile   = models.CharField(max_length=255)

    latitude        = models.FloatField(blank=True, null=True)
    longitude       = models.FloatField(blank=True, null=True)
    altitude_meters = models.FloatField(blank=True, null=True)
    gps_district    = models.CharField(max_length=100, blank=True, null=True)
    DateCaptured    = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.CropType} (ID: {self.PlantID}) @ ({self.latitude}, {self.longitude})"


# ============================================================
# --- 4. DIAGNOSIS ---
# ============================================================
class Diagnosis(models.Model):
    FEEDBACK_CHOICES = [
        ('correct',   'Correct'),
        ('incorrect', 'Incorrect'),
        ('unsure',    'Not Sure'),
    ]
    SEVERITY_CHOICES = [
        ('mild',     'Mild'),
        ('moderate', 'Moderate'),
        ('severe',   'Severe'),
    ]

    DiagnosisID     = models.AutoField(primary_key=True)
    PlantID         = models.ForeignKey(Plant, on_delete=models.CASCADE, related_name="diagnoses")
    DiseaseName     = models.CharField(max_length=255)
    ConfidenceLevel = models.FloatField()
    DateDiagnosed   = models.DateTimeField(auto_now_add=True)

    farmer_feedback   = models.CharField(max_length=20, choices=FEEDBACK_CHOICES, blank=True, null=True)
    severity          = models.CharField(max_length=20, choices=SEVERITY_CHOICES, blank=True, null=True)
    treatment_applied = models.BooleanField(default=False)
    treatment_outcome = models.CharField(
        max_length=20,
        choices=[('recovered', 'Recovered'), ('no_change', 'No Change'), ('worsened', 'Worsened')],
        blank=True, null=True,
    )
    follow_up_date = models.DateField(blank=True, null=True)

    def __str__(self):
        return f"{self.DiseaseName} ({self.ConfidenceLevel:.0%}) - {self.DateDiagnosed.date()}"


# ============================================================
# --- 5. TREATMENT (with structured dosage fields) ---
# ============================================================
class Treatment(models.Model):
    """
    RecommendedPesticide  — product name e.g. "Mancozeb 80 WP"
    Dosage                — free-text fallback e.g. "25g per 10L per hectare"

    Structured dosage fields (used for automatic calculation):
      dosage_per_hectare_g   — grams OR ml of product per hectare
      dosage_unit            — 'g' or 'ml'
      water_per_hectare_l    — litres of water needed per hectare

    Calculation in SaveScanView:
      product_amount = dosage_per_hectare_g  × plot_size_hectares
      water_volume   = water_per_hectare_l   × plot_size_hectares
      buckets        = water_volume ÷ 10
    """
    UNIT_CHOICES = [
        ('g',  'Grams (g)'),
        ('ml', 'Millilitres (ml)'),
    ]

    TreatmentID          = models.AutoField(primary_key=True)
    DiseaseName          = models.CharField(max_length=255, null=True, blank=True, unique=True)
    RecommendedPesticide = models.CharField(max_length=255)
    Dosage               = models.CharField(max_length=255)   # free-text fallback
    ApplicationSteps     = models.TextField()

    # ── Structured dosage fields ──────────────────────────────────────────
    dosage_per_hectare_g = models.FloatField(
        blank=True, null=True,
        help_text="Grams or ml of product needed per hectare (e.g. 25 for 25g/ha)",
    )
    dosage_unit = models.CharField(
        max_length=5, choices=UNIT_CHOICES, default='g',
        help_text="Unit for dosage_per_hectare_g — 'g' or 'ml'",
    )
    water_per_hectare_l = models.FloatField(
        blank=True, null=True,
        help_text="Litres of water per hectare (e.g. 200 for standard field sprayer)",
    )

    def calculate_for_plot(self, plot_size_hectares: float) -> dict:
        """
        Returns calculated amounts for a specific plot size.
        Returns empty dict if structured fields not populated.
        """
        if not all([
            self.dosage_per_hectare_g,
            self.water_per_hectare_l,
            plot_size_hectares,
        ]):
            return {}

        product_amount = round(self.dosage_per_hectare_g * plot_size_hectares, 1)
        water_volume   = round(self.water_per_hectare_l  * plot_size_hectares, 1)
        buckets        = round(water_volume / 10, 1)

        return {
            'product_amount':  product_amount,
            'dosage_unit':     self.dosage_unit,
            'water_litres':    water_volume,
            'buckets_10l':     buckets,
            'plot_hectares':   plot_size_hectares,
            'product_display': f"{product_amount}{self.dosage_unit}",
            'water_display':   f"{water_volume}L ({buckets} × 10L buckets)",
        }

    def __str__(self):
        return f"Treatment for {self.DiseaseName}"


# ============================================================
# --- 6. APP ALERT ---
# ============================================================
class AppAlert(models.Model):
    ALERT_TYPE_CHOICES = [
        ('weather',  'Weather'),
        ('disease',  'Disease Outbreak'),
        ('market',   'Market Price'),
        ('reminder', 'Crop Reminder'),
        ('system',   'System'),
    ]
    PRIORITY_CHOICES = [
        ('low',    'Low'),
        ('medium', 'Medium'),
        ('high',   'High — Urgent'),
    ]

    AlertID     = models.AutoField(primary_key=True)
    FarmerID    = models.ForeignKey(Farmer, on_delete=models.CASCADE, related_name="alerts")
    RelatedCrop = models.ForeignKey(CropProfile, on_delete=models.CASCADE, null=True, blank=True)
    Title       = models.CharField(max_length=255)
    Message     = models.TextField()
    alert_type  = models.CharField(max_length=50, choices=ALERT_TYPE_CHOICES, default="weather")
    IsRead      = models.BooleanField(default=False)
    DateCreated = models.DateTimeField(auto_now_add=True)
    priority    = models.CharField(max_length=10, choices=PRIORITY_CHOICES, default='medium')
    district_target = models.CharField(max_length=100, blank=True, null=True)
    expires_at  = models.DateTimeField(blank=True, null=True)

    def __str__(self):
        return f"[{self.priority.upper()}] {self.alert_type.upper()}: {self.Title}"


# ============================================================
# --- 7. WEATHER DATA ---
# ============================================================
class WeatherData(models.Model):
    WeatherID            = models.AutoField(primary_key=True)
    district             = models.CharField(max_length=100, blank=True, null=True)
    Temperature          = models.FloatField()
    Humidity             = models.IntegerField()
    Rainfall             = models.FloatField(default=0.0)
    rainfall_last_7_days = models.FloatField(default=0.0)
    AlertMessage         = models.CharField(max_length=255, blank=True)
    DateUpdated          = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Weather ({self.district}) - {self.DateUpdated.date()}"


# ============================================================
# --- 8. KNOWLEDGE BASE & AI ---
# ============================================================
class KnowledgeBase(models.Model):
    EntryID       = models.AutoField(primary_key=True)
    DiseaseName   = models.CharField(max_length=255, unique=True)
    Symptoms      = models.TextField()
    TreatmentInfo = models.TextField()
    LastUpdated   = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.DiseaseName


class AIModel(models.Model):
    ModelID         = models.AutoField(primary_key=True)
    Version         = models.CharField(max_length=50)
    AccuracyRate    = models.FloatField()
    LastTrainedDate = models.DateTimeField()


# ============================================================
# --- 9. TRANSLATION CACHE ---
# ============================================================
class TranslationCache(models.Model):
    disease_name_en = models.CharField(max_length=255, primary_key=True)
    pesticide_st    = models.CharField(max_length=255, verbose_name="Moriana (Sesotho)")
    dosage_st       = models.CharField(max_length=255, verbose_name="Tekanyetso (Sesotho)")
    steps_st        = models.TextField(verbose_name="Mekhoa ea Tšebeliso (Sesotho)")
    last_updated    = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Sesotho Translation: {self.disease_name_en}"


# ============================================================
# --- 10. PERSONALIZED RULE ENGINE (9-Factor) ---
# ============================================================
class PersonalizedRule(models.Model):
    SOIL_CHOICES = [
        ('sandy', 'Sandy'), ('clay', 'Clay'), ('loam', 'Loam'),
        ('silt', 'Silt'), ('sandy_loam', 'Sandy Loam'), ('clay_loam', 'Clay Loam'),
    ]
    IRRIGATION_CHOICES = [
        ('rain', 'Rain-fed'), ('drip', 'Drip Irrigation'),
        ('flood', 'Flood Irrigation'), ('sprinkler', 'Sprinkler'),
    ]
    SEASON_CHOICES = [
        ('dry', 'Dry Season (May–Sep)'), ('wet', 'Wet Season (Oct–Apr)'), ('any', 'Any Season'),
    ]
    RAINFALL_LEVEL_CHOICES = [
        ('low', 'Low — < 10mm/week'), ('moderate', 'Moderate — 10–30mm/week'),
        ('high', 'High — > 30mm/week'), ('any', 'Any'),
    ]
    ALTITUDE_TIER_CHOICES = [
        ('lowland',  'Lowland — below 1800m'),
        ('midland',  'Midland — 1800–2200m'),
        ('highland', 'Highland — 2200–2800m'),
        ('alpine',   'Alpine — above 2800m'),
        ('any',      'Any altitude'),
    ]

    RuleID      = models.AutoField(primary_key=True)
    DiseaseName = models.CharField(max_length=255)

    TriggerDistrict      = models.CharField(max_length=100, blank=True, null=True)
    TriggerAltitudeTier  = models.CharField(max_length=10, choices=ALTITUDE_TIER_CHOICES, default='any')
    TriggerSoilType      = models.CharField(max_length=20, choices=SOIL_CHOICES, blank=True, null=True)
    TriggerIrrigation    = models.CharField(max_length=20, choices=IRRIGATION_CHOICES, blank=True, null=True)
    MinDaysSincePlanting = models.IntegerField(default=0)
    MaxDaysSincePlanting = models.IntegerField(default=999)
    TriggerCropVariety   = models.CharField(max_length=100, blank=True, null=True)
    TriggerSeason        = models.CharField(max_length=10, choices=SEASON_CHOICES, default='any')
    TriggerRainfallLevel = models.CharField(max_length=10, choices=RAINFALL_LEVEL_CHOICES, default='any')

    ExpertAdvice           = models.TextField()
    advice_beginner        = models.TextField(blank=True, null=True)
    RecommendationCategory = models.CharField(max_length=50, default="General")
    priority_score         = models.IntegerField(default=1)

    class Meta:
        indexes = [
            models.Index(fields=['DiseaseName', 'TriggerDistrict', 'TriggerAltitudeTier']),
            models.Index(fields=['DiseaseName', 'TriggerSoilType', 'TriggerIrrigation']),
            models.Index(fields=['DiseaseName', 'TriggerSeason',   'TriggerRainfallLevel']),
        ]
        ordering = ['-priority_score']

    def __str__(self):
        parts = [self.DiseaseName]
        if self.TriggerDistrict:              parts.append(self.TriggerDistrict)
        if self.TriggerAltitudeTier != 'any': parts.append(self.TriggerAltitudeTier)
        if self.TriggerSoilType:              parts.append(self.TriggerSoilType)
        return f"Rule: {' | '.join(parts)}"


# ============================================================
# --- 11. RULE MATCHING SERVICE ---
# ============================================================
class RuleMatchingService:
    SEASON_MAP = {
        1: 'wet', 2: 'wet', 3: 'wet', 4: 'wet',
        5: 'dry', 6: 'dry', 7: 'dry', 8: 'dry', 9: 'dry',
        10: 'wet', 11: 'wet', 12: 'wet',
    }

    @staticmethod
    def _classify_rainfall(mm: float) -> str:
        if mm < 10:    return 'low'
        elif mm <= 30: return 'moderate'
        return 'high'

    @staticmethod
    def _classify_altitude(meters) -> str:
        if meters is None: return 'any'
        try:
            m = float(meters)
        except (TypeError, ValueError):
            return 'any'
        if m < 1800:   return 'lowland'
        elif m < 2200: return 'midland'
        elif m < 2800: return 'highland'
        return 'alpine'

    @classmethod
    def get_best_match(cls, disease_name, farmer, crop_profile,
                       gps_district, rainfall_mm=0.0, altitude_meters=None) -> dict:
        current_season = cls.SEASON_MAP.get(timezone.now().month, 'any')
        rainfall_level = cls._classify_rainfall(rainfall_mm)
        altitude_tier  = cls._classify_altitude(altitude_meters)
        days_planted   = crop_profile.days_since_planting or 0

        matching_rules = PersonalizedRule.objects.filter(
            Q(DiseaseName__iexact=disease_name)
            & (Q(TriggerDistrict__iexact=gps_district) | Q(TriggerDistrict__isnull=True))
            & (Q(TriggerAltitudeTier=altitude_tier)    | Q(TriggerAltitudeTier='any'))
            & (Q(TriggerSoilType=crop_profile.SoilEnvironment)        | Q(TriggerSoilType__isnull=True))
            & (Q(TriggerIrrigation=crop_profile.irrigation_method)    | Q(TriggerIrrigation__isnull=True))
            & Q(MinDaysSincePlanting__lte=days_planted)
            & Q(MaxDaysSincePlanting__gte=days_planted)
            & (Q(TriggerCropVariety__iexact=crop_profile.seed_variety) | Q(TriggerCropVariety__isnull=True))
            & (Q(TriggerSeason=current_season)         | Q(TriggerSeason='any'))
            & (Q(TriggerRainfallLevel=rainfall_level)  | Q(TriggerRainfallLevel='any'))
        ).order_by('-priority_score')

        best_rule = matching_rules.first()
        if not best_rule:
            return {"found": False, "advice": None, "category": "General"}

        use_simple  = (farmer.experience_level == 'beginner' and best_rule.advice_beginner)
        advice_text = best_rule.advice_beginner if use_simple else best_rule.ExpertAdvice

        variety_label = crop_profile.seed_variety or crop_profile.VegetableType
        context = {
            'district':      gps_district or 'your district',
            'altitude_tier': altitude_tier if altitude_tier != 'any' else 'your altitude',
            'altitude_m':    f"{int(float(altitude_meters))}m" if altitude_meters else 'unknown altitude',
            'soil':          crop_profile.SoilEnvironment or 'your soil',
            'irrigation':    crop_profile.irrigation_method or 'your irrigation',
            'growth_stage':  crop_profile.growth_stage_label,
            'variety':       variety_label,
            'crop':          crop_profile.VegetableType,
            'season':        current_season,
            'rainfall':      rainfall_level,
        }
        try:
            advice_text = advice_text.format(**context)
        except (KeyError, ValueError):
            pass

        return {
            "found":    True,
            "rule_id":  best_rule.RuleID,
            "advice":   advice_text,
            "category": best_rule.RecommendationCategory,
            "matched_on": {
                "district":      gps_district,
                "altitude_tier": altitude_tier,
                "altitude_m":    altitude_meters,
                "soil":          crop_profile.SoilEnvironment,
                "irrigation":    crop_profile.irrigation_method,
                "variety":       crop_profile.seed_variety,
                "growth_stage":  crop_profile.growth_stage_label,
                "season":        current_season,
                "rainfall":      rainfall_level,
            },
        }


# ============================================================
# --- 12. FARMER INSIGHT ---
# ============================================================
class FarmerInsight(models.Model):
    InsightID               = models.AutoField(primary_key=True)
    FarmerID                = models.OneToOneField(Farmer, on_delete=models.CASCADE, related_name="insight")
    total_scans             = models.IntegerField(default=0)
    total_diseases_detected = models.IntegerField(default=0)
    total_healthy_scans     = models.IntegerField(default=0)
    most_scanned_crop       = models.CharField(max_length=100, blank=True, null=True)
    most_common_disease     = models.CharField(max_length=255, blank=True, null=True)
    highest_risk_month      = models.IntegerField(
        blank=True, null=True,
        validators=[MinValueValidator(1), MaxValueValidator(12)],
    )
    last_scan_date      = models.DateTimeField(blank=True, null=True)
    streak_healthy_days = models.IntegerField(default=0)
    last_updated        = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Insights: {self.FarmerID.username} | {self.total_scans} scans"


# ============================================================
# --- 13. GROWTH JOURNAL ---
# ============================================================
class GrowthJournalEntry(models.Model):
    EntryID     = models.AutoField(primary_key=True)
    CropProfile = models.ForeignKey(CropProfile, on_delete=models.CASCADE, related_name="journal_entries")
    FarmerID    = models.ForeignKey(Farmer, on_delete=models.CASCADE, related_name="journal_entries")
    entry_date  = models.DateField(default=timezone.now)
    title       = models.CharField(max_length=200)
    body        = models.TextField()
    photo_url   = models.CharField(max_length=500, blank=True, null=True)
    mood        = models.CharField(
        max_length=20,
        choices=[('great', 'Great'), ('ok', 'OK'), ('concerned', 'Concerned'), ('bad', 'Bad')],
        default='ok',
    )
    DateCreated = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-entry_date']

    def __str__(self):
        return f"Journal: {self.CropProfile.VegetableType} - {self.entry_date}"


# ============================================================
# --- 14. MARKET PRICE ---
# ============================================================
class MarketPrice(models.Model):
    PriceID        = models.AutoField(primary_key=True)
    vegetable_name = models.CharField(max_length=100)
    market_name    = models.CharField(max_length=100)
    district       = models.CharField(max_length=100)
    price_per_kg   = models.DecimalField(max_digits=6, decimal_places=2)
    currency       = models.CharField(max_length=5, default='LSL')
    date_recorded  = models.DateField(default=timezone.now)
    price_trend    = models.CharField(
        max_length=10,
        choices=[('rising', 'Rising'), ('stable', 'Stable'), ('falling', 'Falling')],
        default='stable',
    )

    class Meta:
        ordering = ['-date_recorded']

    def __str__(self):
        return f"{self.vegetable_name} @ {self.market_name}: LSL {self.price_per_kg}/kg"


# ============================================================
# --- 15. SAVE SCAN VIEW ---
# ============================================================
class SaveScanView(APIView):
    permission_classes = [IsAuthenticated]

    # ── Helpers ──────────────────────────────────────────────────────────

    def _get_sesotho(self, disease_name: str, field: str = 'pesticide'):
        """Fetch a single Sesotho-translated field from TranslationCache."""
        if not disease_name:
            return None
        try:
            cache = TranslationCache.objects.get(disease_name_en__iexact=disease_name)
            value = {'pesticide': cache.pesticide_st,
                     'dosage':    cache.dosage_st,
                     'steps':     cache.steps_st}.get(field)
            if value:
                logger.warning(f"[Sesotho] ✓ Found '{field}' for '{disease_name}': {value[:100]}...")
            else:
                logger.warning(f"[Sesotho] ✗ No '{field}' found for '{disease_name}'")
            return value
        except TranslationCache.DoesNotExist:
            logger.warning(f"[Sesotho] ✗ No translation cache entry for '{disease_name}'")
            return None
        except Exception as exc:
            logger.warning(f"[Sesotho] Error: {exc}")
            return None

    @staticmethod
    def _get_highland_temp(altitude: float) -> int:
        """Estimate temperature (°C) from altitude."""
        return int(22 - (altitude / 100 * 0.65))

    @staticmethod
    def _classify_altitude(meters) -> str:
        """Return altitude tier string from metres value."""
        if meters is None:
            return 'any'
        try:
            m = float(meters)
        except (TypeError, ValueError):
            return 'any'
        if m < 1800:   return 'lowland'
        elif m < 2200: return 'midland'
        elif m < 2800: return 'highland'
        return 'alpine'

    def _generate_personalized_advice(
        self,
        disease_name: str,
        farmer: Farmer,
        crop_profile: CropProfile,
        gps_district: str,
        gps_lat,
        gps_lon,
        gps_alt,
    ) -> dict:
        """
        Build a multi-factor, GPS-aware advice string.
        Falls back gracefully when any data point is absent.
        """
        experience_level = farmer.experience_level
        district  = gps_district or farmer.district or 'your area'
        crop_type = crop_profile.VegetableType if crop_profile else 'your crop'
        soil_type = (crop_profile.SoilEnvironment or 'your soil type') if crop_profile else 'your soil type'
        irrigation = (crop_profile.irrigation_method or 'your irrigation method') if crop_profile else 'your irrigation method'
        planting_date = crop_profile.PlantingDate if crop_profile else None
        plot_size     = crop_profile.plot_size_hectares if crop_profile else None

        # Growth stage
        days_since_planting = 0
        growth_stage = "Unknown"
        if planting_date:
            days_since_planting = (date.today() - planting_date).days
            if days_since_planting < 14:   growth_stage = "seedling"
            elif days_since_planting < 45: growth_stage = "vegetative"
            elif days_since_planting < 75: growth_stage = "flowering"
            else:                          growth_stage = "fruiting/harvest"

        # Altitude
        altitude_tier    = self._classify_altitude(gps_alt)
        altitude_display = f"{int(gps_alt)}m" if gps_alt is not None else None

        # Season
        current_month = date.today().month
        if 5 <= current_month <= 9:
            season = "dry"
            season_advice = (
                "During this dry season, fungal diseases spread less. "
                "Focus on proper irrigation and soil moisture management."
            )
        else:
            season = "wet"
            season_advice = (
                "During this wet season, fungal diseases spread rapidly. "
                "Apply preventive fungicides and ensure good drainage."
            )

        # Regional flags
        is_western = is_eastern = is_northern = is_southern = False
        if gps_lat is not None and gps_lon is not None:
            if gps_lon < 27.5:   is_western  = True
            elif gps_lon > 28.5: is_eastern  = True
            if gps_lat > -29.0:  is_northern = True
            elif gps_lat < -30.0: is_southern = True

        advice_parts = []
        disease_lower = disease_name.lower()

        # 1 ── Location opening
        location_context = []
        if gps_lat is not None and gps_lon is not None:
            location_context.append(f"Your farm at coordinates {gps_lat:.4f}°S, {gps_lon:.4f}°E")
            if altitude_display:
                location_context.append(f"at {altitude_display} elevation")
            location_context.append(f"in {district} district")
        else:
            location_context.append(f"Your farm in {district} district")
        advice_parts.append(
            f"{' '.join(location_context)} faces specific conditions for "
            f"{disease_name.replace('_', ' ')}."
        )

        # 2 ── Altitude-based advice
        if gps_alt is not None:
            if altitude_tier == 'highland':
                temp = self._get_highland_temp(gps_alt)
                advice_parts.append(
                    f"At {int(gps_alt)}m elevation, nights are cold ({temp}°C). "
                    "This slows pathogen development but also slows plant growth. "
                    "Apply treatments early morning when temperatures rise above 10°C."
                )
                if 'blight' in disease_lower:
                    advice_parts.append(
                        "Highland conditions favour late blight. "
                        "Increase copper spray frequency to every 5 days during wet periods."
                    )
                elif 'mildew' in disease_lower:
                    advice_parts.append(
                        "Highland humidity promotes powdery mildew. "
                        "Ensure good air circulation by spacing plants wider (add 10–15 cm to standard spacing)."
                    )
            elif altitude_tier == 'midland':
                advice_parts.append(
                    f"Your midland altitude ({int(gps_alt)}m) provides good growing conditions. "
                    "Standard treatment intervals work well here."
                )
            elif altitude_tier == 'lowland':
                advice_parts.append(
                    f"At {int(gps_alt)}m elevation, warmer temperatures accelerate disease spread. "
                    "Reduce treatment intervals by 20–30 % compared to highland recommendations."
                )

        # 3 ── Regional climate advice
        if is_western:
            advice_parts.append(
                "Western Lesotho (your area) receives less rainfall (600–800 mm annually). "
                "During dry spells, focus on soil moisture conservation. "
                "Use mulch to retain moisture and reduce plant stress."
            )
            if 'blight' in disease_lower:
                advice_parts.append(
                    "Despite lower rainfall in western Lesotho, morning dew can still promote blight. "
                    "Apply fungicides early morning before dew forms."
                )
        elif is_eastern:
            advice_parts.append(
                "Eastern Lesotho (your area) receives high rainfall (1 000–1 500 mm annually). "
                "This high humidity creates perfect conditions for fungal diseases. "
                "Increase fungicide frequency and ensure excellent drainage."
            )
            if 'mildew' in disease_lower:
                advice_parts.append(
                    "Your high-rainfall area is a hotspot for powdery mildew. "
                    "Consider systemic fungicides and improve air circulation through proper pruning."
                )

        if is_northern:
            advice_parts.append(
                "Northern Lesotho (your area) has warmer temperatures, "
                "which can accelerate disease cycles. Monitor crops daily during peak growing season."
            )
        elif is_southern:
            advice_parts.append(
                "Southern Lesotho (your area) experiences cooler temperatures. "
                "Diseases develop slower, but frost damage can weaken plants, making them susceptible."
            )

        # 4 ── Season
        advice_parts.append(season_advice)

        # 5 ── Disease-specific treatment
        if 'blight' in disease_lower:
            if altitude_tier == 'highland':
                advice_parts.append(
                    "BLIGHT TREATMENT for highlands: Apply copper hydroxide (250 g/100 L) every 5–7 days. "
                    "In Mokhotlong/Thaba-Tseka highlands, late blight is the #1 potato disease."
                )
            elif is_eastern:
                advice_parts.append(
                    f"BLIGHT TREATMENT for eastern Lesotho: Due to your high-rainfall area ({gps_lon:.1f}°E), "
                    "apply metalaxyl-based fungicides preventively every 7 days during rainy season."
                )
            else:
                advice_parts.append(
                    "BLIGHT TREATMENT: Apply copper-based fungicide every 7–10 days. "
                    "Remove infected leaves immediately and destroy them away from your field."
                )
        elif 'mildew' in disease_lower:
            if is_eastern or altitude_tier == 'highland':
                advice_parts.append(
                    "MILDEW TREATMENT for your high-humidity location: Apply sulfur (200 g/100 L) weekly. "
                    "Your area's morning fog creates ideal mildew conditions."
                )
            else:
                advice_parts.append(
                    "MILDEW TREATMENT: Apply neem oil or sulfur weekly. "
                    "Water plants at the base, not overhead, to reduce leaf wetness."
                )
        elif 'rust' in disease_lower:
            if is_western:
                advice_parts.append(
                    "RUST TREATMENT for western Lesotho: Your drier conditions actually favour rust development. "
                    "Apply azoxystrobin (100 ml/100 L) at first sign."
                )
            else:
                advice_parts.append(
                    "RUST TREATMENT: Remove affected leaves. "
                    "Apply fungicide containing azoxystrobin or tebuconazole."
                )
        elif 'aphid' in disease_lower:
            advice_parts.append(
                "APHID CONTROL: Release ladybugs (available from Lesotho Agricultural Supply) "
                "or spray neem oil (30 ml/10 L). Aphids thrive in Lesotho's spring (September–October)."
            )
        elif 'rot' in disease_lower:
            if is_eastern:
                advice_parts.append(
                    "ROT TREATMENT for eastern Lesotho: Your high-rainfall area requires raised beds "
                    "(30 cm high) for drainage. Apply copper-based fungicide as soil drench."
                )
            else:
                advice_parts.append(
                    "ROT TREATMENT: Improve drainage immediately. Reduce watering. "
                    "Apply copper-based fungicide."
                )
        elif 'virus' in disease_lower:
            advice_parts.append(
                f"VIRUS MANAGEMENT: Viruses have no cure. Remove infected plants immediately from {district}. "
                "Control insect vectors and use virus-free seeds. "
                "In Lesotho, tomato spotted wilt virus is common in lowlands."
            )
        elif 'healthy' in disease_lower:
            advice_parts.append(
                f"✅ Your {crop_type} appears healthy. Continue good agricultural practices in {district}."
            )
        else:
            advice_parts.append(
                f"For {disease_name} in {district}, consult your local agricultural extension officer "
                "for specific treatment."
            )

        # 6 ── Soil-specific advice
        if soil_type and soil_type != 'your soil type':
            if 'clay' in soil_type.lower():
                advice_parts.append(
                    f"Your {soil_type} soil in {district} needs raised beds for better drainage. "
                    "Add river sand and compost to improve soil structure."
                )
            elif 'sandy' in soil_type.lower():
                advice_parts.append(
                    f"Your {soil_type} soil in {district} drains quickly. "
                    "Add compost to retain moisture. In dry areas like western Lesotho, this is especially important."
                )
            elif 'loam' in soil_type.lower():
                advice_parts.append(
                    f"Your {soil_type} soil is ideal for {crop_type} in {district} conditions."
                )

        # 7 ── Irrigation advice
        if irrigation and irrigation != 'your irrigation method':
            if irrigation.lower() == 'drip':
                if is_western:
                    advice_parts.append(
                        "Your drip irrigation is excellent for western Lesotho's drier conditions. "
                        "Water early morning (6–8 AM) to minimise evaporation."
                    )
                else:
                    advice_parts.append(
                        "Your drip irrigation is ideal. Water early morning to allow leaves to dry."
                    )
            elif irrigation.lower() in ('overhead', 'sprinkler'):
                if is_eastern or altitude_tier == 'highland':
                    advice_parts.append(
                        "⚠️ In your high-rainfall/high-humidity area, overhead watering spreads diseases. "
                        "Switch to drip irrigation or water only at soil level."
                    )
                else:
                    advice_parts.append(
                        "Switch to drip irrigation if possible. "
                        "Overhead watering spreads many fungal diseases."
                    )

        # 8 ── Growth stage advice
        if growth_stage != "Unknown":
            if growth_stage == "seedling":
                advice_parts.append(
                    f"Your {crop_type} is in seedling stage. "
                    f"Young plants in {district} are vulnerable — monitor daily for disease spread."
                )
            elif growth_stage == "flowering":
                advice_parts.append(
                    f"Your {crop_type} is flowering. Avoid spraying during peak flowering (9 AM–3 PM) "
                    "to protect bees. Spray early morning or late evening."
                )
            elif growth_stage == "fruiting/harvest":
                advice_parts.append(
                    f"Your {crop_type} is in fruiting stage. Follow the pre-harvest interval on all "
                    "pesticides — check the label for days to wait after spraying before harvest."
                )

        # 9 ── Experience level
        if experience_level == 'beginner':
            advice_parts.append(
                "👨‍🌾 Beginner tip: Start with a small test area first. "
                "Always wear gloves, mask, and protective clothing when spraying. "
                "Read all pesticide labels carefully."
            )
        elif experience_level == 'expert':
            advice_parts.append(
                "🔬 Expert recommendation: Rotate between different fungicide groups (FRAC codes) "
                "to prevent resistance development."
            )

        # 10 ── Local resources
        if district and district != 'your area':
            advice_parts.append(
                f"📍 Local resources in {district}: Contact your nearest agricultural extension officer "
                "for site-specific advice and free soil testing."
            )

        # 11 ── Dosage calculation
        if plot_size and plot_size > 0:
            water_liters = int(plot_size * 200)
            buckets = int(water_liters / 10)
            advice_parts.append(
                f"📐 For your {plot_size} ha plot, mix the recommended product with "
                f"{water_liters} L water (approx. {buckets} × 10 L buckets)."
            )

        return {
            'advice': " ".join(advice_parts),
            'matched_on': {
                'district':           district,
                'latitude':           gps_lat,
                'longitude':          gps_lon,
                'altitude_tier':      altitude_tier,
                'altitude_m':         gps_alt,
                'soil':               soil_type,
                'irrigation':         irrigation,
                'growth_stage':       growth_stage,
                'season':             season,
                'days_since_planting': days_since_planting,
                'region': (
                    'western' if is_western
                    else 'eastern' if is_eastern
                    else 'central'
                ),
            },
            'farmer_level': experience_level,
        }

    # ── POST handler ──────────────────────────────────────────────────────

    def post(self, request):
        try:
            user = request.user

            logger.warning("[SaveScan] ========== NEW SCAN REQUEST ==========")
            logger.warning(f"[SaveScan] incoming data: {dict(request.data)}")

            # ── Language ─────────────────────────────────────────────────
            incoming_lang = request.data.get('language') or request.data.get('lang')
            if incoming_lang in ('st', 'en'):
                user.language_preferences = incoming_lang
                user.save(update_fields=['language_preferences'])
            lang = user.language_preferences
            logger.warning(f"[SaveScan] 🌐 LANGUAGE PREFERENCE: '{lang}'")

            # ── Disease label ─────────────────────────────────────────────
            raw_label   = (request.data.get('diseaseName')
                          or request.data.get('DiseaseName')
                          or 'Healthy')
            clean_label = raw_label.replace('___', ' ').replace('_', ' ').strip()
            logger.warning(f"[SaveScan] 🦠 Disease: '{clean_label}'")

            image_url  = (request.data.get('imageUrl')
                         or request.data.get('image_url')
                         or request.data.get('ImageFile')
                         or '')
            confidence = float(
                request.data.get('confidence')
                or request.data.get('ConfidenceLevel')
                or 0.0
            )
            profile_id = (request.data.get('profileId')
                         or request.data.get('ProfileID'))

            # ── GPS ───────────────────────────────────────────────────────
            gps_lat = request.data.get('latitude')
            gps_lon = request.data.get('longitude')
            gps_alt = request.data.get('altitude')
            for val, name in ((gps_lat, 'lat'), (gps_lon, 'lon'), (gps_alt, 'alt')):
                try:
                    if val is not None:
                        val = float(val)
                except (TypeError, ValueError):
                    pass

            # Re-assign after safe conversion
            try:
                gps_lat = float(gps_lat) if gps_lat is not None else None
                gps_lon = float(gps_lon) if gps_lon is not None else None
                gps_alt = float(gps_alt) if gps_alt is not None else None
            except (TypeError, ValueError):
                gps_lat = gps_lon = gps_alt = None

            gps_district = (
                request.data.get('gps_district')
                or request.data.get('district')
                or user.district
                or ''
            )
            logger.warning(
                f"[SaveScan] 📍 GPS: lat={gps_lat}, lon={gps_lon}, "
                f"alt={gps_alt}, district={gps_district}"
            )

            # ── Scan mode ─────────────────────────────────────────────────
            scan_mode = (
                request.data.get('scan_mode')
                or request.data.get('scanMode')
                or 'general'
            ).lower()
            wants_personalized = scan_mode == 'personalized'
            logger.warning(
                f"[SaveScan] 📱 Mode: scan_mode='{scan_mode}', "
                f"wants_personalized={wants_personalized}"
            )

            # ── Crop profile ──────────────────────────────────────────────
            target_profile = None
            if profile_id and str(profile_id).lower() not in ('null', 'none', ''):
                target_profile = CropProfile.objects.filter(
                    pk=profile_id, FarmerID=user
                ).first()

            crop_type = (
                target_profile.VegetableType
                if target_profile
                else request.data.get('cropType', 'Vegetable')
            )

            # ── Persist plant record ──────────────────────────────────────
            new_plant = Plant.objects.create(
                FarmerID=user,
                CropProfile=target_profile,
                CropType=crop_type,
                ImageFile=image_url,
                latitude=gps_lat,
                longitude=gps_lon,
                altitude_meters=gps_alt,
                gps_district=gps_district,
            )

            # ── Persist diagnosis ─────────────────────────────────────────
            urgent = any(
                w in clean_label.lower()
                for w in ('blight', 'rot', 'wilt', 'mold', 'virus',
                          'bacteria', 'phytophthora', 'fusarium')
            )
            follow_up_date = date.today() + timedelta(days=3 if urgent else 10)
            diagnosis = Diagnosis.objects.create(
                PlantID=new_plant,
                DiseaseName=clean_label,
                ConfidenceLevel=confidence,
                follow_up_date=follow_up_date,
            )

            # ── Treatment & knowledge base lookup ─────────────────────────
            tq    = Q(DiseaseName__iexact=clean_label) | Q(DiseaseName__iexact=raw_label)
            treat = Treatment.objects.filter(tq).first()
            kb    = KnowledgeBase.objects.filter(tq).first()

            res_pesticide = treat.RecommendedPesticide if treat else 'Consult local expert'
            res_dosage    = treat.Dosage               if treat else 'N/A'
            res_steps     = (
                treat.ApplicationSteps if treat and treat.ApplicationSteps
                else kb.TreatmentInfo  if kb   and kb.TreatmentInfo
                else 'Isolate plant immediately and consult your local agricultural officer.'
            )

            # ── Structured dosage calculation ─────────────────────────────
            plot_ha    = target_profile.plot_size_hectares if target_profile else None
            dosage_calc = treat.calculate_for_plot(plot_ha) if (treat and plot_ha) else {}

            # ── Sesotho translations ──────────────────────────────────────
            if lang == 'st':
                logger.warning(
                    f"[SaveScan] 🎯 APPLYING SESOTHO TRANSLATION for disease: '{clean_label}'"
                )
                st_pesticide = self._get_sesotho(clean_label, 'pesticide')
                st_dosage    = self._get_sesotho(clean_label, 'dosage')
                st_steps     = self._get_sesotho(clean_label, 'steps')

                if st_pesticide:
                    res_pesticide = st_pesticide
                    logger.warning(f"[SaveScan] ✅ Sesotho PESTICIDE applied: '{st_pesticide[:100]}'")
                else:
                    logger.warning(f"[SaveScan] ⚠️ No Sesotho pesticide for '{clean_label}'")

                if st_dosage:
                    res_dosage = st_dosage
                    logger.warning(f"[SaveScan] ✅ Sesotho DOSAGE applied: '{st_dosage}'")
                else:
                    logger.warning(f"[SaveScan] ⚠️ No Sesotho dosage for '{clean_label}'")

                if st_steps:
                    res_steps = st_steps
                    logger.warning(
                        f"[SaveScan] ✅ Sesotho STEPS applied ({len(st_steps)} chars): "
                        f"{st_steps[:200]}..."
                    )
                else:
                    logger.warning(f"[SaveScan] ⚠️ No Sesotho steps for '{clean_label}'")

            # ── Personalized mode ─────────────────────────────────────────
            personalized_advice = matched_context = personalized_dosage = None

            if wants_personalized and target_profile:
                logger.warning("[SaveScan] 📝 Generating personalized advice...")
                personalized = self._generate_personalized_advice(
                    disease_name=clean_label,
                    farmer=user,
                    crop_profile=target_profile,
                    gps_district=gps_district,
                    gps_lat=gps_lat,
                    gps_lon=gps_lon,
                    gps_alt=gps_alt,
                )
                personalized_advice = personalized['advice']
                matched_context     = personalized['matched_on']

                # Override with Sesotho steps if applicable
                if lang == 'st':
                    st_steps_p = self._get_sesotho(clean_label, 'steps')
                    if st_steps_p:
                        personalized_advice = st_steps_p
                        logger.warning(
                            "[SaveScan] ✅ Personalized advice replaced with Sesotho steps"
                        )

                if dosage_calc:
                    personalized_dosage = {
                        'product':       res_pesticide,
                        'amount':        dosage_calc.get('product_display'),
                        'water':         dosage_calc.get('water_display'),
                        'unit':          dosage_calc.get('dosage_unit'),
                        'plot_hectares': dosage_calc.get('plot_hectares'),
                        'raw': {
                            'product_amount': dosage_calc.get('product_amount'),
                            'water_litres':   dosage_calc.get('water_litres'),
                            'buckets_10l':    dosage_calc.get('buckets_10l'),
                        },
                    }

            # ── Build response ────────────────────────────────────────────
            personalized_block = None
            if wants_personalized and target_profile:
                personalized_block = {
                    'advice':       personalized_advice,
                    'dosage':       personalized_dosage,
                    'matched_on':   matched_context,
                    'farmer_level': user.experience_level,
                }

            response_data = {
                'status':        'success',
                'id':            diagnosis.DiagnosisID,
                'follow_up_date': follow_up_date.isoformat(),
                'crop_type':     crop_type,
                'scan_mode':     scan_mode,
                'language_used': lang,
                'gps_data': {
                    'latitude':  gps_lat,
                    'longitude': gps_lon,
                    'altitude':  gps_alt,
                    'district':  gps_district,
                },
                '_debug': {
                    'received_scan_mode':      scan_mode,
                    'wants_personalized':      wants_personalized,
                    'target_profile_found':    target_profile is not None,
                    'gps_received':            gps_lat is not None,
                    'language':                lang,
                    'sesotho_translations_available': {
                        'pesticide': self._get_sesotho(clean_label, 'pesticide') is not None,
                        'dosage':    self._get_sesotho(clean_label, 'dosage')    is not None,
                        'steps':     self._get_sesotho(clean_label, 'steps')     is not None,
                    } if lang == 'st' else None,
                },
                'personalized': personalized_block,
                'results': {
                    'disease':    clean_label,
                    'pesticide':  res_pesticide,
                    'dosage':     res_dosage,
                    'steps':      res_steps,
                    'confidence': confidence,
                    'treatment_dose_display': (
                        dosage_calc.get('product_display')
                        if dosage_calc and wants_personalized else None
                    ),
                    'water_volume_display': (
                        dosage_calc.get('water_display')
                        if dosage_calc and wants_personalized else None
                    ),
                },
                'treatment_product':  res_pesticide,
                'personalized_advice': personalized_advice if wants_personalized else None,
            }

            logger.warning("[SaveScan] 📤 RESPONSE SUMMARY:")
            logger.warning(f"[SaveScan]   - Language: {lang}")
            logger.warning(
                f"[SaveScan]   - Pesticide: "
                f"{res_pesticide[:100] if res_pesticide else 'None'}..."
            )
            logger.warning(f"[SaveScan]   - Dosage: {res_dosage}")
            logger.warning(
                f"[SaveScan]   - Steps length: {len(res_steps) if res_steps else 0} chars"
            )
            logger.warning("[SaveScan] ========== SCAN COMPLETE ==========")

            return Response(response_data)

        except Exception as exc:
            logger.error(f"[SaveScan] ❌ ERROR: {exc}")
            logger.error(traceback.format_exc())
            return Response(
                {'error': str(exc), 'detail': traceback.format_exc()},
                status=status.HTTP_400_BAD_REQUEST,
            )
