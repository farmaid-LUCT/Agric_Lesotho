import os
import sys
import django

# Set up the project path and settings module
project_path = os.path.dirname(os.path.abspath(__file__))
sys.path.append(project_path)
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'farm_aid_backend.settings')

# Initialize Django
django.setup()

from api.models import PersonalizedRule

def seed_personalized_rules():
    rules = [
        # --- VEGETABLE RULES (Personalized for Lesotho) ---
        {
            "DiseaseName": "Potato_Virus",
            "TriggerSoilType": "Sandy",
            "MinDaysSincePlanting": 0,
            "MaxDaysSincePlanting": 999,
            "RecommendationCategory": "Pest Control",
            "ExpertAdvice": "Potato Virus detected. In sandy soils, aphids move easily. Use reflective mulches and remove infected plants immediately."
        },
        {
            "DiseaseName": "Cabbage_Black_Rot",
            "TriggerLocation": "Leribe",
            "MinDaysSincePlanting": 0,
            "MaxDaysSincePlanting": 999,
            "RecommendationCategory": "Disease Management",
            "ExpertAdvice": "Black Rot thrives in Leribe's humidity. Avoid overhead irrigation; water at the base to keep leaves dry."
        },
        {
            "DiseaseName": "Tomato_Tomato_Late_blight",
            "TriggerSoilType": "Clayey",
            "MinDaysSincePlanting": 30,
            "MaxDaysSincePlanting": 999,
            "RecommendationCategory": "Drainage",
            "ExpertAdvice": "Late Blight alert! In Clayey soil, moisture stays trapped. Use high ridges to prevent 'wet feet' which accelerates blight."
        },
        {
            "DiseaseName": "Onion_Purple_Blotch",
            "TriggerLocation": "Maseru",
            "MinDaysSincePlanting": 0,
            "MaxDaysSincePlanting": 999,
            "RecommendationCategory": "Nutrition",
            "ExpertAdvice": "Purple Blotch detected. Strengthening your onions with Potassium can help. Ensure your Maseru farm has well-draining soil."
        },
        {
            "DiseaseName": "Tomato_healthy",
            "TriggerSoilType": "Duplex (Lesotho Special)",
            "MinDaysSincePlanting": 0,
            "MaxDaysSincePlanting": 999,
            "RecommendationCategory": "General",
            "ExpertAdvice": "Healthy tomatoes! Duplex soil can form a hard crust; gently loosen the topsoil surface frequently to allow air to reach roots."
        },
    ]

    # --- REJECTION RULES (Based on your Background list) ---
    # These rules ensure the system knows how to handle non-vegetable scans
    rejection_classes = [
        "Background_car", "Background_person", "Background_dog", 
        "Background_airplane", "Background_motorbike", "Background_cat"
    ]

    for bg in rejection_classes:
        rules.append({
            "DiseaseName": bg,
            "TriggerSoilType": None,
            "TriggerLocation": None,
            "MinDaysSincePlanting": 0,
            "MaxDaysSincePlanting": 999,
            "RecommendationCategory": "System",
            "ExpertAdvice": "This is not a vegetable. The app has identified this as a background object. Please scan a clear vegetable leaf."
        })

    # Execution loop
    for rule_data in rules:
        rule, created = PersonalizedRule.objects.update_or_create(
            DiseaseName=rule_data['DiseaseName'],
            TriggerSoilType=rule_data.get('TriggerSoilType'),
            TriggerLocation=rule_data.get('TriggerLocation'),
            MinDaysSincePlanting=rule_data['MinDaysSincePlanting'],
            MaxDaysSincePlanting=rule_data['MaxDaysSincePlanting'],
            defaults={
                "ExpertAdvice": rule_data['ExpertAdvice'], 
                "RecommendationCategory": rule_data['RecommendationCategory']
            }
        )
        status = "Created" if created else "Updated"
        print(f"[{status}] Rule for {rule.DiseaseName}")

if __name__ == "__main__":
    seed_personalized_rules()