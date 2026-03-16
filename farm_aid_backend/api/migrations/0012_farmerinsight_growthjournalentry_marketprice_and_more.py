import django.core.validators
import django.db.models.deletion
import django.utils.timezone
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('api', '0011_fix_translation_schema'),
    ]

    operations = [
        # ── Farmer field changes ──────────────────────────────────────────
        migrations.RemoveField(
            model_name='farmer',
            name='location',
        ),
        migrations.AddField(
            model_name='farmer',
            name='district',
            field=models.CharField(blank=True, max_length=100, null=True),
        ),
        migrations.AddField(
            model_name='farmer',
            name='experience_level',
            field=models.CharField(
                choices=[
                    ('beginner', 'Beginner'),
                    ('intermediate', 'Intermediate'),
                    ('expert', 'Expert'),
                ],
                default='beginner',
                max_length=20,
            ),
        ),
        migrations.AddField(
            model_name='farmer',
            name='farm_size_hectares',
            field=models.FloatField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='farmer',
            name='profile_photo_url',
            field=models.CharField(blank=True, max_length=500, null=True),
        ),
        migrations.AddField(
            model_name='farmer',
            name='last_active',
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='farmer',
            name='notification_diseases',
            field=models.BooleanField(default=True),
        ),
        migrations.AddField(
            model_name='farmer',
            name='notification_market',
            field=models.BooleanField(default=False),
        ),
        migrations.AddField(
            model_name='farmer',
            name='notification_weather',
            field=models.BooleanField(default=True),
        ),
        migrations.AddField(
            model_name='farmer',
            name='onboarding_complete',
            field=models.BooleanField(default=False),
        ),

        # ── CropProfile field changes ─────────────────────────────────────
        migrations.RemoveField(
            model_name='cropprofile',
            name='FarmLocation',
        ),
        migrations.AddField(
            model_name='cropprofile',
            name='expected_harvest_date',
            field=models.DateField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='cropprofile',
            name='irrigation_method',
            field=models.CharField(
                choices=[
                    ('rain', 'Rain-fed'),
                    ('drip', 'Drip Irrigation'),
                    ('flood', 'Flood Irrigation'),
                    ('sprinkler', 'Sprinkler'),
                ],
                default='rain',
                max_length=20,
            ),
        ),
        migrations.AddField(
            model_name='cropprofile',
            name='notes',
            field=models.TextField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='cropprofile',
            name='plot_size_hectares',
            field=models.FloatField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='cropprofile',
            name='seed_variety',
            field=models.CharField(blank=True, max_length=100, null=True),
        ),
        migrations.AlterField(
            model_name='cropprofile',
            name='SoilEnvironment',
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

        # ── Diagnosis field changes ───────────────────────────────────────
        migrations.AddField(
            model_name='diagnosis',
            name='farmer_feedback',
            field=models.CharField(
                blank=True,
                choices=[
                    ('correct', 'Correct'),
                    ('incorrect', 'Incorrect'),
                    ('unsure', 'Not Sure'),
                ],
                max_length=20,
                null=True,
            ),
        ),
        migrations.AddField(
            model_name='diagnosis',
            name='follow_up_date',
            field=models.DateField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='diagnosis',
            name='severity',
            field=models.CharField(
                blank=True,
                choices=[
                    ('mild', 'Mild'),
                    ('moderate', 'Moderate'),
                    ('severe', 'Severe'),
                ],
                max_length=20,
                null=True,
            ),
        ),
        migrations.AddField(
            model_name='diagnosis',
            name='treatment_applied',
            field=models.BooleanField(default=False),
        ),
        migrations.AddField(
            model_name='diagnosis',
            name='treatment_outcome',
            field=models.CharField(
                blank=True,
                choices=[
                    ('recovered', 'Recovered'),
                    ('no_change', 'No Change'),
                    ('worsened', 'Worsened'),
                ],
                max_length=20,
                null=True,
            ),
        ),

        # ── Plant field changes ───────────────────────────────────────────
        migrations.AddField(
            model_name='plant',
            name='altitude_meters',
            field=models.FloatField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='plant',
            name='gps_district',
            field=models.CharField(blank=True, max_length=100, null=True),
        ),
        migrations.AddField(
            model_name='plant',
            name='latitude',
            field=models.FloatField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='plant',
            name='longitude',
            field=models.FloatField(blank=True, null=True),
        ),

        # ── WeatherData field changes ─────────────────────────────────────
        migrations.AddField(
            model_name='weatherdata',
            name='district',
            field=models.CharField(blank=True, max_length=100, null=True),
        ),
        migrations.AddField(
            model_name='weatherdata',
            name='rainfall_last_7_days',
            field=models.FloatField(default=0.0),
        ),

        # ── AppAlert field changes ────────────────────────────────────────
        migrations.AlterField(
            model_name='appalert',
            name='alert_type',
            field=models.CharField(
                choices=[
                    ('weather', 'Weather'),
                    ('disease', 'Disease Outbreak'),
                    ('market', 'Market Price'),
                    ('reminder', 'Crop Reminder'),
                    ('system', 'System'),
                ],
                default='weather',
                max_length=50,
            ),
        ),
        migrations.AddField(
            model_name='appalert',
            name='district_target',
            field=models.CharField(blank=True, max_length=100, null=True),
        ),
        migrations.AddField(
            model_name='appalert',
            name='expires_at',
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='appalert',
            name='priority',
            field=models.CharField(
                choices=[
                    ('low', 'Low'),
                    ('medium', 'Medium'),
                    ('high', 'High — Urgent'),
                ],
                default='medium',
                max_length=10,
            ),
        ),

        # ── PersonalizedRule field changes ────────────────────────────────
        migrations.RemoveField(
            model_name='personalizedrule',
            name='TriggerLocation',
        ),
        migrations.AddField(
            model_name='personalizedrule',
            name='TriggerCropVariety',
            field=models.CharField(blank=True, max_length=100, null=True),
        ),
        migrations.AddField(
            model_name='personalizedrule',
            name='TriggerDistrict',
            field=models.CharField(blank=True, max_length=100, null=True),
        ),
        migrations.AddField(
            model_name='personalizedrule',
            name='TriggerIrrigation',
            field=models.CharField(blank=True, max_length=20, null=True),
        ),
        migrations.AddField(
            model_name='personalizedrule',
            name='TriggerRainfallLevel',
            field=models.CharField(default='any', max_length=10),
        ),
        migrations.AddField(
            model_name='personalizedrule',
            name='TriggerSeason',
            field=models.CharField(default='any', max_length=10),
        ),
        migrations.AddField(
            model_name='personalizedrule',
            name='advice_beginner',
            field=models.TextField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='personalizedrule',
            name='priority_score',
            field=models.IntegerField(default=1),
        ),
        migrations.AlterField(
            model_name='personalizedrule',
            name='RecommendationCategory',
            field=models.CharField(default='General', max_length=50),
        ),
        migrations.AlterField(
            model_name='personalizedrule',
            name='TriggerSoilType',
            field=models.CharField(blank=True, max_length=20, null=True),
        ),

        # ── New models ────────────────────────────────────────────────────
        migrations.CreateModel(
            name='FarmerInsight',
            fields=[
                ('InsightID', models.AutoField(primary_key=True, serialize=False)),
                ('total_scans', models.IntegerField(default=0)),
                ('total_diseases_detected', models.IntegerField(default=0)),
                ('total_healthy_scans', models.IntegerField(default=0)),
                ('most_scanned_crop', models.CharField(blank=True, max_length=100, null=True)),
                ('most_common_disease', models.CharField(blank=True, max_length=255, null=True)),
                ('highest_risk_month', models.IntegerField(
                    blank=True, null=True,
                    validators=[
                        django.core.validators.MinValueValidator(1),
                        django.core.validators.MaxValueValidator(12),
                    ],
                )),
                ('last_scan_date', models.DateTimeField(blank=True, null=True)),
                ('streak_healthy_days', models.IntegerField(default=0)),
                ('last_updated', models.DateTimeField(auto_now=True)),
                ('FarmerID', models.OneToOneField(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='insight',
                    to=settings.AUTH_USER_MODEL,
                )),
            ],
        ),
        migrations.CreateModel(
            name='GrowthJournalEntry',
            fields=[
                ('EntryID', models.AutoField(primary_key=True, serialize=False)),
                ('entry_date', models.DateField(default=django.utils.timezone.now)),
                ('title', models.CharField(max_length=200)),
                ('body', models.TextField()),
                ('photo_url', models.CharField(blank=True, max_length=500, null=True)),
                ('mood', models.CharField(
                    choices=[
                        ('great', 'Great'),
                        ('ok', 'OK'),
                        ('concerned', 'Concerned'),
                        ('bad', 'Bad'),
                    ],
                    default='ok',
                    max_length=20,
                )),
                ('DateCreated', models.DateTimeField(auto_now_add=True)),
                ('CropProfile', models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='journal_entries',
                    to='api.cropprofile',
                )),
                ('FarmerID', models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='journal_entries',
                    to=settings.AUTH_USER_MODEL,
                )),
            ],
            options={'ordering': ['-entry_date']},
        ),
        migrations.CreateModel(
            name='MarketPrice',
            fields=[
                ('PriceID', models.AutoField(primary_key=True, serialize=False)),
                ('vegetable_name', models.CharField(max_length=100)),
                ('market_name', models.CharField(max_length=100)),
                ('district', models.CharField(max_length=100)),
                ('price_per_kg', models.DecimalField(decimal_places=2, max_digits=6)),
                ('currency', models.CharField(default='LSL', max_length=5)),
                ('date_recorded', models.DateField(default=django.utils.timezone.now)),
                ('price_trend', models.CharField(
                    choices=[
                        ('rising', 'Rising'),
                        ('stable', 'Stable'),
                        ('falling', 'Falling'),
                    ],
                    default='stable',
                    max_length=10,
                )),
            ],
            options={'ordering': ['-date_recorded']},
        ),
    ]