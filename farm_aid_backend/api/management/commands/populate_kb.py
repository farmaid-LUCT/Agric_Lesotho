from django.core.management.base import BaseCommand
from api.models import KnowledgeBase # Correct name

class Command(BaseCommand):
    help = 'Populates KnowledgeBase with agricultural advice for 76 labels'

    def handle(self, *args, **kwargs):
        # Specific data for key crops
        data = {
            "Beans_Als": {"s": "Small angular brown spots.", "t": "Use copper fungicides."},
            "Beans_Bean_rust": {"s": "Reddish-brown pustules.", "t": "Use sulfur dust."},
            "Beans_healthy": {"s": "Healthy green leaves.", "t": "Standard care."},
            "Cabbage_Black_Rot": {"s": "V-shaped yellow lesions.", "t": "Remove infected plants."},
            "Cabbage_healthy": {"s": "Firm healthy heads.", "t": "Regular watering."},
            "Tomato_Tomato___Early_blight": {"s": "Concentric rings on leaves.", "t": "Apply Chlorothalonil."},
            "Tomato_healthy": {"s": "Robust green growth.", "t": "Stake plants."},
        }

        all_labels = [
            "Beans_Als", "Beans_Bean_rust", "Beans_healthy", "Bitter_Gourd_Downey_mildew", 
            "Bitter_Gourd_Fusarium_wilt", "Bitter_Gourd_Mosaic_virus", "Bitter_Gourd_healthy", 
            "Bottle_gourd_Anthracnose", "Bottle_gourd_Downey_mildew", "Bottle_gourd_healthy", 
            "Cabbage_Alternaria_Leaf_Spot", "Cabbage_Bacterial_spot_rot", "Cabbage_Black_Rot", 
            "Cabbage_Cabbage_aphid_colony", "Cabbage_Club_root", "Cabbage_Downy_Mildew", 
            "Cabbage_Ring_spot", "Cabbage_healthy", "Cauliflower_Black_Rot", 
            "Cauliflower_Downy_mildew", "Cauliflower_healthy", "Cucumber_Anthracnose_lesions", 
            "Cucumber_Downy_mildew", "Cucumber_Powdery_mildew", "Cucumber_healthy", 
            "Eggplant_Eggplant_Cercopora_leaf_spot", "Eggplant_Eggplant_begomovirus", 
            "Eggplant_Eggplant_verticillium_wilt", "Eggplant_healthy", "Lettuce_Bacterial", 
            "Lettuce_Fungal", "Lettuce_healthy", "Potato_Bacteria", "Potato_Fungi", 
            "Potato_Nematode", "Potato_Pest", "Potato_Phytopthora", "Potato_Virus", 
            "Potato_healthy", "Pumkin_Alternaria_cucumerina", "Pumkin_Alternaria_leaf_blight", 
            "Pumkin_Aphids", "Pumkin_Armyworms", "Pumkin_Bacterial_leaf_spot", 
            "Pumkin_Bacterial_wilt", "Pumkin_Cabbage_looper", "Pumkin_Cucumber_beetles", 
            "Pumkin_Flea_beetles", "Pumkin_Fusarium", "Pumkin_Gummy_stem_blight", 
            "Pumkin_Phytophthora_bligh", "Pumkin_Powdery_mildew", "Pumkin_Southern_blight", 
            "Pumkin_Squash_bug", "Pumkin_Squash_vine_borer", "Pumkin_Thrips_Western_flower_thrips", 
            "Pumkin_healthy", "Pumkin_mosaic", "Radish_Radish_Black_leaf_spot", 
            "Radish_Radish_Downey_mildew", "Radish_Radish_Mosaic_virus", "Radish_Radish_flea_beetle", 
            "Radish_healthy", "Tomato_Tomato_Bacterial_spot", "Tomato_Tomato___Bacterial_spot", 
            "Tomato_Tomato___Early_blight", "Tomato_Tomato___Late_blight", "Tomato_Tomato___Leaf_Mold", 
            "Tomato_Tomato___Septoria_leaf_spot", "Tomato_Tomato___Spider_mites Two-spotted_spider_mite", 
            "Tomato_Tomato___Target_Spot", "Tomato_Tomato___Tomato_Yellow_Leaf_Curl_Virus", 
            "Tomato_Tomato___Tomato_mosaic_virus", "Tomato_Tomato_leaf_curl_virus", 
            "Tomato_Tomato_spotted_wilt", "Tomato_healthy"
        ]

        # Fill defaults
        for label in all_labels:
            if label not in data:
                data[label] = {
                    "s": f"Symptoms of {label.replace('_', ' ')}.",
                    "t": "Consult a local Lesotho agricultural extension officer."
                }

        # Seed Database
        count = 0
        for label, info in data.items():
            KnowledgeBase.objects.update_or_create(
                DiseaseName=label,
                defaults={'Symptoms': info['s'], 'TreatmentInfo': info['t']}
            )
            count += 1
        
        self.stdout.write(self.style.SUCCESS(f'Success! Seeded {count} KnowledgeBase entries.'))