from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('api', '0013_treatment_structured_dosage'),
    ]

    operations = [
        migrations.AddField(
            model_name='personalizedrule',
            name='TriggerAltitudeTier',
            field=models.CharField(
                choices=[
                    ('lowland',  'Lowland — below 1800m'),
                    ('midland',  'Midland — 1800–2200m'),
                    ('highland', 'Highland — 2200–2800m'),
                    ('alpine',   'Alpine — above 2800m'),
                    ('any',      'Any altitude'),
                ],
                default='any',
                max_length=10,
            ),
        ),
        migrations.AlterModelOptions(
            name='personalizedrule',
            options={'ordering': ['-priority_score']},
        ),
        migrations.RenameIndex(
            model_name='personalizedrule',
            new_name='api_persona_Disease_ea84bb_idx',
            old_name='api_persona_Disease_seasonal_idx',
        ),
        migrations.AddIndex(
            model_name='personalizedrule',
            index=models.Index(
                fields=['DiseaseName', 'TriggerDistrict', 'TriggerAltitudeTier'],
                name='api_persona_Disease_2e7913_idx',
            ),
        ),
        migrations.AddIndex(
            model_name='personalizedrule',
            index=models.Index(
                fields=['DiseaseName', 'TriggerSoilType', 'TriggerIrrigation'],
                name='api_persona_Disease_608ce7_idx',
            ),
        ),
    ]