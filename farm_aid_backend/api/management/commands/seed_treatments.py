# from django.core.management.base import BaseCommand
# from api.models import Treatment

# class Command(BaseCommand):
#     help = 'Seeds the Treatment table with data for all labels in labels.txt'

#     def handle(self, *args, **kwargs):
#         # Dictionary mapping keywords to specific treatments
#         # This covers all categories in your labels.txt
#         treatment_map = {
#             "healthy": ["None", "0", "Keep up the good work! Maintain regular watering and weeding."],
#             "Blight": ["Mancozeb + Metalaxyl", "3g per 1L water", "Remove infected leaves immediately. Spray every 7 days during rainy periods."],
#             "Mildew": ["Wettable Sulphur", "3g per 1L water", "Spray in the early morning. Ensure full coverage of both sides of leaves."],
#             "Rot": ["Copper Hydroxide", "2g per 1L water", "Reduce irrigation. Remove and burn infected plant parts."],
#             "Virus": ["Imidacloprid (for vectors)", "0.5ml per 1L water", "Control aphids/whiteflies. Remove infected plants to stop spread."],
#             "Wilt": ["Crop Rotation", "N/A", "Stop planting in this area for 2 seasons. Improve soil drainage."],
#             "Aphids": ["Cypermethrin", "1ml per 1L water", "Spray directly on insect colonies. Use a soapy water mix as a sticker."],
#             "Pest": ["Lambda-Cyhalothrin", "1.5ml per 1L water", "Apply in late afternoon when pests are active."],
#             "Anthracnose": ["Carbendazim", "1g per 1L water", "Avoid overhead watering. Spray at 14-day intervals."],
#             "Spot": ["Chlorothalonil", "2ml per 1L water", "Apply at first sign of spots. Repeat every 10-14 days."],
#             "Mosaic": ["Sanitation", "N/A", "Disinfect tools. No chemical cure for the virus itself. Remove hosts."],
#         }

#         labels = [
#             "Beans_Als", "Beans_Bean_rust", "Beans_healthy", "Bitter_Gourd_Downey_mildew", 
#             "Bitter_Gourd_Fusarium_wilt", "Bitter_Gourd_Mosaic_virus", "Bitter_Gourd_healthy", 
#             "Bottle_gourd_Anthracnose", "Bottle_gourd_Downey_mildew", "Bottle_gourd_healthy", 
#             "Cabbage_Alternaria_Leaf_Spot", "Cabbage_Bacterial_spot_rot", "Cabbage_Black_Rot", 
#             "Cabbage_Cabbage_aphid_colony", "Cabbage_Club_root", "Cabbage_Downy_Mildew", 
#             "Cabbage_Ring_spot", "Cabbage_healthy", "Cauliflower_Black_Rot", "Cauliflower_Downy_mildew", 
#             "Cauliflower_healthy", "Cucumber_Anthracnose_lesions", "Cucumber_Downy_mildew", 
#             "Cucumber_Powdery_mildew", "Cucumber_healthy", "Eggplant_Eggplant_Cercopora_leaf_spot", 
#             "Eggplant_Eggplant_begomovirus", "Eggplant_Eggplant_verticillium_wilt", "Eggplant_healthy", 
#             "Lettuce_Bacterial", "Lettuce_Fungal", "Lettuce_healthy", "Potato_Bacteria", 
#             "Potato_Fungi", "Potato_Nematode", "Potato_Pest", "Potato_Phytopthora", "Potato_Virus", 
#             "Potato_healthy", "Pumkin_Alternaria_cucumerina", "Pumkin_Alternaria_leaf_blight", 
#             "Pumkin_Aphids", "Pumkin_Armyworms", "Pumkin_Bacterial_leaf_spot", "Pumkin_Bacterial_wilt", 
#             "Pumkin_Cabbage_looper", "Pumkin_Cucumber_beetles", "Pumkin_Flea_beetles", "Pumkin_Fusarium", 
#             "Pumkin_Gummy_stem_blight", "Pumkin_Phytophthora_bligh", "Pumkin_Powdery_mildew", 
#             "Pumkin_Southern_blight", "Pumkin_Squash_bug", "Pumkin_Squash_vine_borer", 
#             "Pumkin_Thrips_Western_flower_thrips", "Pumkin_healthy", "Pumkin_mosaic", 
#             "Radish_Radish_Black_leaf_spot", "Radish_Radish_Downey_mildew", "Radish_Radish_Mosaic_virus", 
#             "Radish_Radish_flea_beetle", "Radish_healthy", "Tomato_Tomato_Bacterial_spot", 
#             "Tomato_Tomato___Bacterial_spot", "Tomato_Tomato___Early_blight", "Tomato_Tomato___Late_blight", 
#             "Tomato_Tomato___Leaf_Mold", "Tomato_Tomato___Septoria_leaf_spot", 
#             "Tomato_Tomato___Spider_mites Two-spotted_spider_mite", "Tomato_Tomato___Target_Spot", 
#             "Tomato_Tomato___Tomato_Yellow_Leaf_Curl_Virus", "Tomato_Tomato___Tomato_mosaic_virus", 
#             "Tomato_Tomato_leaf_curl_virus", "Tomato_Tomato_spotted_wilt", "Tomato_healthy"
#         ]

#         count = 0
#         for label in labels:
#             # Logic to pick the best treatment based on keywords in the label
#             pesticide, dosage, steps = ["General Fungicide", "2g/L", "Contact extension office for specific advice."]
            
#             for key, val in treatment_map.items():
#                 if key.lower() in label.lower():
#                     pesticide, dosage, steps = val
#                     break

#             # Create or Update based on the label name
#             Treatment.objects.update_or_create(
#                 DiseaseName=label,
#                 defaults={
#                     'RecommendedPesticide': pesticide,
#                     'Dosage': dosage,
#                     'ApplicationSteps': steps
#                 }
#             )
#             count += 1

#         self.stdout.write(self.style.SUCCESS(f'Successfully seeded {count} treatments!'))