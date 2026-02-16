# expert_system.py
from datetime import date

def run_vegetable_rules(profile, disease_name):
    tips = []
    if not profile:
        return tips

    # Convert everything to lowercase to avoid "Clay" vs "clay" errors
    soil = str(profile.SoilEnvironment).lower()
    location = str(profile.FarmLocation).lower()
    disease = str(disease_name).lower()

    # --- RULE 1: SOIL ---
    if "clay" in soil:
        if "blight" in disease or "rot" in disease or "mold" in disease:
            tips.append("💧 Clay soil holds too much water. Reduce watering by 30% to stop the fungus from spreading.")
    
    if "sand" in soil:
        tips.append("⏳ Sandy soil drains fast. Apply fertilizer in small amounts more frequently.")

    # --- RULE 2: LOCATION (Lesotho) ---
    highlands = ['mokhotlong', 'thaba-tseka', 'qacha', 'quthing']
    if any(dist in location for dist in highlands):
        tips.append(f"🏔️ Highland Alert: Night frost is common in {profile.FarmLocation}. Cover young plants at night.")

    # --- RULE 3: VEGETABLE TYPE ---
    if "tomato" in str(profile.VegetableType).lower() and "blight" in disease:
        tips.append("🍅 Tomato Expert Tip: Prune the bottom leaves (15cm from ground) to prevent soil-borne spores from splashing onto the plant.")

    return tips