from django.db.models.signals import post_save
from django.dispatch import receiver
from django.db.models import Q
from .models import WeatherData, CropProfile, AppAlert
print("Signals module loaded successfully!")

@receiver(post_save, sender=WeatherData)
def analyze_weather_for_alerts(sender, instance, created, **kwargs):
    if not created:
        return

    # --- CATEGORY 1: Fungal/Blight Risk (High Humidity) ---
    if instance.Humidity > 80:
        # Define all vegetables prone to blight or fungal issues
        blight_prone = ["Tomato", "Potato", "Pepper", "Eggplant", "Cucumber"]
        
        # Build a dynamic query to catch any of these varieties (Case-Insensitive)
        query = Q()
        for veg in blight_prone:
            query |= Q(VegetableType__icontains=veg)
        
        prone_crops = CropProfile.objects.filter(query, IsActive=True)
        
        for profile in prone_crops:
            AppAlert.objects.get_or_create(
                FarmerID=profile.FarmerID,
                Title="Fungal Disease Risk",
                Message=f"High humidity ({instance.Humidity}%) detected. Check your {profile.VegetableType} for signs of Blight.",
                alert_type="disease",
                RelatedCrop=profile
            )

    # --- CATEGORY 2: Frost Risk (Low Temperature) ---
    if instance.Temperature < 3.0:
        # Frost usually affects almost everything, but you can exclude hardy crops if needed
        # For now, we alert ALL active farmers
        active_profiles = CropProfile.objects.filter(IsActive=True)
        
        for profile in active_profiles:
            AppAlert.objects.get_or_create(
                FarmerID=profile.FarmerID,
                Title="Frost Warning",
                Message=f"Freezing temps ({instance.Temperature}°C) in Maseru. Protect your {profile.VegetableType}!",
                alert_type="weather",
                RelatedCrop=profile
            )

    # --- CATEGORY 3: Heat Stress (High Temperature) ---
    if instance.Temperature > 30.0:
        # Target leafy greens that wilt quickly
        leafy_greens = ["Cabbage", "Spinach", "Lettuce", "Kale", "Chard"]
        
        query = Q()
        for veg in leafy_greens:
            query |= Q(VegetableType__icontains=veg)
            
        heat_sensitive = CropProfile.objects.filter(query, IsActive=True)
        
        for profile in heat_sensitive:
            AppAlert.objects.get_or_create(
                FarmerID=profile.FarmerID,
                Title="Heat Stress Alert",
                Message=f"High heat ({instance.Temperature}°C) detected. Increase irrigation for your {profile.VegetableType}.",
                alert_type="weather",
                RelatedCrop=profile
            )