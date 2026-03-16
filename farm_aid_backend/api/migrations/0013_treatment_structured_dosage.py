from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('api', '0012_farmerinsight_growthjournalentry_marketprice_and_more'),
    ]

    operations = [
        # ── Treatment structured dosage fields ────────────────────────────
        migrations.AddField(
            model_name='treatment',
            name='dosage_per_hectare_g',
            field=models.FloatField(
                blank=True,
                null=True,
                help_text='Grams or ml of product needed per hectare (e.g. 25 for 25g/ha)',
            ),
        ),
        migrations.AddField(
            model_name='treatment',
            name='dosage_unit',
            field=models.CharField(
                choices=[('g', 'Grams (g)'), ('ml', 'Millilitres (ml)')],
                default='g',
                help_text="Unit for dosage_per_hectare_g — 'g' or 'ml'",
                max_length=5,
            ),
        ),
        migrations.AddField(
            model_name='treatment',
            name='water_per_hectare_l',
            field=models.FloatField(
                blank=True,
                null=True,
                help_text='Litres of water per hectare (e.g. 200 for standard field sprayer)',
            ),
        ),

        # ── PersonalizedRule field alterations ────────────────────────────
        migrations.AlterField(
            model_name='personalizedrule',
            name='TriggerIrrigation',
            field=models.CharField(
                blank=True,
                choices=[
                    ('rain', 'Rain-fed'),
                    ('drip', 'Drip Irrigation'),
                    ('flood', 'Flood Irrigation'),
                    ('sprinkler', 'Sprinkler'),
                ],
                max_length=20,
                null=True,
            ),
        ),
        migrations.AlterField(
            model_name='personalizedrule',
            name='TriggerRainfallLevel',
            field=models.CharField(
                choices=[
                    ('low', 'Low — < 10mm/week'),
                    ('moderate', 'Moderate — 10–30mm/week'),
                    ('high', 'High — > 30mm/week'),
                    ('any', 'Any'),
                ],
                default='any',
                max_length=10,
            ),
        ),
        migrations.AlterField(
            model_name='personalizedrule',
            name='TriggerSeason',
            field=models.CharField(
                choices=[
                    ('dry', 'Dry Season (May–Sep)'),
                    ('wet', 'Wet Season (Oct–Apr)'),
                    ('any', 'Any Season'),
                ],
                default='any',
                max_length=10,
            ),
        ),
        migrations.AlterField(
            model_name='personalizedrule',
            name='TriggerSoilType',
            field=models.CharField(
                blank=True,
                choices=[
                    ('sandy', 'Sandy'),
                    ('clay', 'Clay'),
                    ('loam', 'Loam'),
                    ('silt', 'Silt'),
                    ('sandy_loam', 'Sandy Loam'),
                    ('clay_loam', 'Clay Loam'),
                ],
                max_length=20,
                null=True,
            ),
        ),

        # ── PersonalizedRule index rename ─────────────────────────────────
        migrations.RenameIndex(
            model_name='personalizedrule',
            new_name='api_persona_Disease_ea84bb_idx',
            old_name='api_persona_Disease_seasonal_idx',
        ),
    ]