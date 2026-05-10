from django.contrib.auth.models import AbstractUser
from django.db import models
from django.utils import timezone
from django.core.validators import MinValueValidator, MaxValueValidator


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
        if days is None: return "Unknown"
        if days < 14:    return "Seedling"
        elif days < 45:  return "Vegetative"
        elif days < 75:  return "Flowering"
        else:            return "Fruiting / Harvest"

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
        choices=[('recovered','Recovered'),('no_change','No Change'),('worsened','Worsened')],
        blank=True, null=True,
    )
    follow_up_date = models.DateField(blank=True, null=True)
    
    # NEW FIELD: Stores personalized recommendation snapshot
    recommendation_snapshot = models.JSONField(default=dict, blank=True)

    def __str__(self):
        return f"{self.DiseaseName} ({self.ConfidenceLevel:.0%}) - {self.DateDiagnosed.date()}"


# ============================================================
# --- 5. TREATMENT ---
# ============================================================
class Treatment(models.Model):
    UNIT_CHOICES = [
        ('g',  'Grams (g)'),
        ('ml', 'Millilitres (ml)'),
    ]

    TreatmentID          = models.AutoField(primary_key=True)
    DiseaseName          = models.CharField(max_length=255, null=True, blank=True, unique=True)
    RecommendedPesticide = models.CharField(max_length=255)
    Dosage               = models.CharField(max_length=255)
    ApplicationSteps     = models.TextField()

    dosage_per_hectare_g = models.FloatField(blank=True, null=True)
    dosage_unit = models.CharField(max_length=5, choices=UNIT_CHOICES, default='g')
    water_per_hectare_l = models.FloatField(blank=True, null=True)

    def calculate_for_plot(self, plot_size_hectares: float) -> dict:
        if not all([self.dosage_per_hectare_g, self.water_per_hectare_l, plot_size_hectares]):
            return {}

        product_amount = round(self.dosage_per_hectare_g * plot_size_hectares, 1)
        water_volume   = round(self.water_per_hectare_l * plot_size_hectares, 1)
        buckets        = round(water_volume / 10, 1)

        return {
            'product_amount': product_amount,
            'dosage_unit': self.dosage_unit,
            'water_litres': water_volume,
            'buckets_10l': buckets,
            'plot_hectares': plot_size_hectares,
            'product_display': f"{product_amount}{self.dosage_unit}",
            'water_display': f"{water_volume}L ({buckets} × 10L buckets)",
        }

    def __str__(self):
        return f"Treatment for {self.DiseaseName}"


# ============================================================
# --- 6. APP ALERT ---
# ============================================================
class AppAlert(models.Model):
    ALERT_TYPE_CHOICES = [
        ('weather', 'Weather'),
        ('disease', 'Disease Outbreak'),
        ('market', 'Market Price'),
        ('reminder', 'Crop Reminder'),
        ('system', 'System'),
    ]
    PRIORITY_CHOICES = [
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High — Urgent'),
    ]

    AlertID = models.AutoField(primary_key=True)
    FarmerID = models.ForeignKey(Farmer, on_delete=models.CASCADE, related_name="alerts")
    RelatedCrop = models.ForeignKey(CropProfile, on_delete=models.CASCADE, null=True, blank=True)
    Title = models.CharField(max_length=255)
    Message = models.TextField()
    alert_type = models.CharField(max_length=50, choices=ALERT_TYPE_CHOICES, default="weather")
    IsRead = models.BooleanField(default=False)
    DateCreated = models.DateTimeField(auto_now_add=True)
    priority = models.CharField(max_length=10, choices=PRIORITY_CHOICES, default='medium')
    district_target = models.CharField(max_length=100, blank=True, null=True)
    expires_at = models.DateTimeField(blank=True, null=True)

    def __str__(self):
        return f"[{self.priority.upper()}] {self.alert_type.upper()}: {self.Title}"


# ============================================================
# --- 7. WEATHER DATA ---
# ============================================================
class WeatherData(models.Model):
    WeatherID = models.AutoField(primary_key=True)
    district = models.CharField(max_length=100, blank=True, null=True)
    Temperature = models.FloatField()
    Humidity = models.IntegerField()
    Rainfall = models.FloatField(default=0.0)
    rainfall_last_7_days = models.FloatField(default=0.0)
    AlertMessage = models.CharField(max_length=255, blank=True)
    DateUpdated = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Weather ({self.district}) - {self.DateUpdated.date()}"


# ============================================================
# --- 8. KNOWLEDGE BASE & AI ---
# ============================================================
class KnowledgeBase(models.Model):
    EntryID = models.AutoField(primary_key=True)
    DiseaseName = models.CharField(max_length=255, unique=True)
    Symptoms = models.TextField()
    TreatmentInfo = models.TextField()
    LastUpdated = models.DateTimeField(auto_now=True)
    
    # NEW FIELD: Causes for this disease
    Causes = models.TextField(blank=True, null=True)

    def __str__(self):
        return self.DiseaseName


class AIModel(models.Model):
    ModelID = models.AutoField(primary_key=True)
    Version = models.CharField(max_length=50)
    AccuracyRate = models.FloatField()
    LastTrainedDate = models.DateTimeField()


# ============================================================
# --- 9. TRANSLATION CACHE ---
# ============================================================
class TranslationCache(models.Model):
    disease_name_en = models.CharField(max_length=255, primary_key=True)
    pesticide_st = models.CharField(max_length=255, verbose_name="Moriana (Sesotho)")
    dosage_st = models.CharField(max_length=255, verbose_name="Tekanyetso (Sesotho)")
    steps_st = models.TextField(verbose_name="Mekhoa ea Tšebeliso (Sesotho)")
    # NEW FIELD: Causes in Sesotho
    causes_st = models.TextField(verbose_name="Lisosa (Sesotho)", blank=True, null=True)
    last_updated = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Sesotho Translation: {self.disease_name_en}"

# ============================================================
# --- 10. PERSONALIZED RULE ENGINE ---
# ============================================================
class PersonalizedRule(models.Model):
    SOIL_CHOICES = [
        ('sandy','Sandy'),('clay','Clay'),('loam','Loam'),
        ('silt','Silt'),('sandy_loam','Sandy Loam'),('clay_loam','Clay Loam'),
    ]
    IRRIGATION_CHOICES = [
        ('rain','Rain-fed'),('drip','Drip Irrigation'),
        ('flood','Flood Irrigation'),('sprinkler','Sprinkler'),
    ]
    SEASON_CHOICES = [
        ('dry','Dry Season (May–Sep)'),('wet','Wet Season (Oct–Apr)'),('any','Any Season'),
    ]
    RAINFALL_LEVEL_CHOICES = [
        ('low','Low — < 10mm/week'),('moderate','Moderate — 10–30mm/week'),
        ('high','High — > 30mm/week'),('any','Any'),
    ]
    ALTITUDE_TIER_CHOICES = [
        ('lowland', 'Lowland — below 1800m'),
        ('midland', 'Midland — 1800–2200m'),
        ('highland', 'Highland — 2200–2800m'),
        ('alpine', 'Alpine — above 2800m'),
        ('any', 'Any altitude'),
    ]

    RuleID = models.AutoField(primary_key=True)
    DiseaseName = models.CharField(max_length=255)

    TriggerDistrict = models.CharField(max_length=100, blank=True, null=True)
    TriggerAltitudeTier = models.CharField(max_length=10, choices=ALTITUDE_TIER_CHOICES, default='any')
    TriggerSoilType = models.CharField(max_length=20, choices=SOIL_CHOICES, blank=True, null=True)
    TriggerIrrigation = models.CharField(max_length=20, choices=IRRIGATION_CHOICES, blank=True, null=True)
    MinDaysSincePlanting = models.IntegerField(default=0)
    MaxDaysSincePlanting = models.IntegerField(default=999)
    TriggerCropVariety = models.CharField(max_length=100, blank=True, null=True)
    TriggerSeason = models.CharField(max_length=10, choices=SEASON_CHOICES, default='any')
    TriggerRainfallLevel = models.CharField(max_length=10, choices=RAINFALL_LEVEL_CHOICES, default='any')

    ExpertAdvice = models.TextField()
    advice_beginner = models.TextField(blank=True, null=True)
    RecommendationCategory = models.CharField(max_length=50, default="General")
    priority_score = models.IntegerField(default=1)

    class Meta:
        indexes = [
            models.Index(fields=['DiseaseName', 'TriggerDistrict', 'TriggerAltitudeTier']),
            models.Index(fields=['DiseaseName', 'TriggerSoilType', 'TriggerIrrigation']),
            models.Index(fields=['DiseaseName', 'TriggerSeason', 'TriggerRainfallLevel']),
        ]
        ordering = ['-priority_score']

    def __str__(self):
        parts = [self.DiseaseName]
        if self.TriggerDistrict: parts.append(self.TriggerDistrict)
        if self.TriggerAltitudeTier != 'any': parts.append(self.TriggerAltitudeTier)
        if self.TriggerSoilType: parts.append(self.TriggerSoilType)
        return f"Rule: {' | '.join(parts)}"


# ============================================================
# --- 11. RULE MATCHING SERVICE ---
# ============================================================
class RuleMatchingService:
    SEASON_MAP = {
        1:'wet',2:'wet',3:'wet',4:'wet',
        5:'dry',6:'dry',7:'dry',8:'dry',9:'dry',
        10:'wet',11:'wet',12:'wet',
    }

    @staticmethod
    def _classify_rainfall(mm: float) -> str:
        if mm < 10: return 'low'
        elif mm <= 30: return 'moderate'
        return 'high'

    @staticmethod
    def _classify_altitude(meters) -> str:
        if meters is None: return 'any'
        try:
            m = float(meters)
        except (TypeError, ValueError):
            return 'any'
        if m < 1800: return 'lowland'
        elif m < 2200: return 'midland'
        elif m < 2800: return 'highland'
        return 'alpine'

    @classmethod
    def get_best_match(cls, disease_name, farmer, crop_profile,
                       gps_district, rainfall_mm=0.0, altitude_meters=None) -> dict:
        from django.db.models import Q

        current_season = cls.SEASON_MAP.get(timezone.now().month, 'any')
        rainfall_level = cls._classify_rainfall(rainfall_mm)
        altitude_tier = cls._classify_altitude(altitude_meters)
        days_planted = crop_profile.days_since_planting or 0

        matching_rules = PersonalizedRule.objects.filter(
            Q(DiseaseName__iexact=disease_name)
            & (Q(TriggerDistrict__iexact=gps_district) | Q(TriggerDistrict__isnull=True) | Q(TriggerDistrict=''))
            & (Q(TriggerAltitudeTier=altitude_tier) | Q(TriggerAltitudeTier='any'))
            & (Q(TriggerSoilType=crop_profile.SoilEnvironment) | Q(TriggerSoilType__isnull=True) | Q(TriggerSoilType=''))
            & (Q(TriggerIrrigation=crop_profile.irrigation_method) | Q(TriggerIrrigation__isnull=True) | Q(TriggerIrrigation=''))
            & Q(MinDaysSincePlanting__lte=days_planted)
            & Q(MaxDaysSincePlanting__gte=days_planted)
            & (Q(TriggerCropVariety__iexact=crop_profile.seed_variety) | Q(TriggerCropVariety__isnull=True) | Q(TriggerCropVariety=''))
            & (Q(TriggerSeason=current_season) | Q(TriggerSeason='any'))
            & (Q(TriggerRainfallLevel=rainfall_level) | Q(TriggerRainfallLevel='any'))
        ).order_by('-priority_score')

        best_rule = matching_rules.first()
        if not best_rule:
            return {"found": False, "advice": None, "category": "General"}

        use_simple = (farmer.experience_level == 'beginner' and best_rule.advice_beginner)
        advice_text = best_rule.advice_beginner if use_simple else best_rule.ExpertAdvice

        variety_label = crop_profile.seed_variety or crop_profile.VegetableType
        context = {
            'district': gps_district or 'your district',
            'altitude_tier': altitude_tier if altitude_tier != 'any' else 'your altitude',
            'altitude_m': f"{int(float(altitude_meters))}m" if altitude_meters else 'unknown altitude',
            'soil': crop_profile.SoilEnvironment or 'your soil',
            'irrigation': crop_profile.irrigation_method or 'your irrigation',
            'growth_stage': crop_profile.growth_stage_label,
            'variety': variety_label,
            'crop': crop_profile.VegetableType,
            'season': current_season,
            'rainfall': rainfall_level,
        }
        try:
            advice_text = advice_text.format(**context)
        except (KeyError, ValueError):
            pass

        return {
            "found": True,
            "rule_id": best_rule.RuleID,
            "advice": advice_text,
            "category": best_rule.RecommendationCategory,
            "matched_on": {
                "district": gps_district,
                "altitude_tier": altitude_tier,
                "altitude_m": altitude_meters,
                "soil": crop_profile.SoilEnvironment,
                "irrigation": crop_profile.irrigation_method,
                "variety": crop_profile.seed_variety,
                "growth_stage": crop_profile.growth_stage_label,
                "season": current_season,
                "rainfall": rainfall_level,
            },
        }


# ============================================================
# --- 12. FARMER INSIGHT ---
# ============================================================
class FarmerInsight(models.Model):
    InsightID = models.AutoField(primary_key=True)
    FarmerID = models.OneToOneField(Farmer, on_delete=models.CASCADE, related_name="insight")
    total_scans = models.IntegerField(default=0)
    total_diseases_detected = models.IntegerField(default=0)
    total_healthy_scans = models.IntegerField(default=0)
    most_scanned_crop = models.CharField(max_length=100, blank=True, null=True)
    most_common_disease = models.CharField(max_length=255, blank=True, null=True)
    highest_risk_month = models.IntegerField(blank=True, null=True,
        validators=[MinValueValidator(1), MaxValueValidator(12)])
    last_scan_date = models.DateTimeField(blank=True, null=True)
    streak_healthy_days = models.IntegerField(default=0)
    last_updated = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Insights: {self.FarmerID.username} | {self.total_scans} scans"


# ============================================================
# --- 13. GROWTH JOURNAL ---
# ============================================================
class GrowthJournalEntry(models.Model):
    EntryID = models.AutoField(primary_key=True)
    CropProfile = models.ForeignKey(CropProfile, on_delete=models.CASCADE, related_name="journal_entries")
    FarmerID = models.ForeignKey(Farmer, on_delete=models.CASCADE, related_name="journal_entries")
    entry_date = models.DateField(default=timezone.now)
    title = models.CharField(max_length=200)
    body = models.TextField()
    photo_url = models.CharField(max_length=500, blank=True, null=True)
    mood = models.CharField(
        max_length=20,
        choices=[('great','Great'),('ok','OK'),('concerned','Concerned'),('bad','Bad')],
        default='ok',
    )
    DateCreated = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-entry_date']

    def __str__(self):
        return f"Journal: {self.CropProfile.VegetableType} - {self.entry_date}"


# ============================================================
# --- 14. COMMUNITY POST ---
# ============================================================
class CommunityPost(models.Model):
    POST_TYPE_CHOICES = [
        ('question', 'Question'),
        ('tip', 'Farming Tip'),
        ('success', 'Success Story'),
        ('general', 'General'),
    ]
    
    id = models.AutoField(primary_key=True)
    farmer = models.ForeignKey(Farmer, on_delete=models.CASCADE, related_name="community_posts")
    content = models.TextField()
    image_url = models.CharField(max_length=500, blank=True, null=True)
    post_type = models.CharField(max_length=20, choices=POST_TYPE_CHOICES, default='general')
    crop_type = models.CharField(max_length=100, blank=True, null=True)
    likes_count = models.IntegerField(default=0)
    comments_count = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
        db_table = 'api_communitypost'
        indexes = [
            models.Index(fields=['-created_at']),
            models.Index(fields=['farmer', '-created_at']),
            models.Index(fields=['crop_type']),
            models.Index(fields=['post_type']),
        ]
    
    def __str__(self):
        return f"{self.farmer.username}: {self.content[:50]}"


# ============================================================
# --- 15. POST LIKE ---
# ============================================================
class PostLike(models.Model):
    post = models.ForeignKey(CommunityPost, on_delete=models.CASCADE, related_name="likes")
    farmer = models.ForeignKey(Farmer, on_delete=models.CASCADE, related_name="post_likes")
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ['post', 'farmer']
        db_table = 'api_postlike'
        indexes = [
            models.Index(fields=['post', 'farmer']),
            models.Index(fields=['farmer']),
        ]
    
    def __str__(self):
        return f"{self.farmer.username} liked post {self.post.id}"


# ============================================================
# --- 16. COMMUNITY COMMENT ---
# ============================================================
class CommunityComment(models.Model):
    post = models.ForeignKey(CommunityPost, on_delete=models.CASCADE, related_name="comments")
    farmer = models.ForeignKey(Farmer, on_delete=models.CASCADE, related_name="community_comments")
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['created_at']
        db_table = 'api_communitycomment'
        indexes = [
            models.Index(fields=['post', 'created_at']),
            models.Index(fields=['farmer']),
        ]
    
    def __str__(self):
        return f"{self.farmer.username} commented on post {self.post.id}"


# ============================================================
# --- 17. MARKET PRICE ---
# ============================================================
class MarketPrice(models.Model):
    PriceID = models.AutoField(primary_key=True)
    vegetable_name = models.CharField(max_length=100)
    market_name = models.CharField(max_length=100)
    district = models.CharField(max_length=100)
    price_per_kg = models.DecimalField(max_digits=6, decimal_places=2)
    currency = models.CharField(max_length=5, default='LSL')
    date_recorded = models.DateField(default=timezone.now)
    price_trend = models.CharField(
        max_length=10,
        choices=[('rising','Rising'),('stable','Stable'),('falling','Falling')],
        default='stable',
    )

    class Meta:
        ordering = ['-date_recorded']

    def __str__(self):
        return f"{self.vegetable_name} @ {self.market_name}: LSL {self.price_per_kg}/kg"
