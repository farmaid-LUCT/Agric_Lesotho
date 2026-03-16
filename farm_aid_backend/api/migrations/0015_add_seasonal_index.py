from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('api', '0014_personalizedrule_altitude_tier'),
    ]

    operations = [
        migrations.AddIndex(
            model_name='personalizedrule',
            index=models.Index(
                fields=['DiseaseName', 'TriggerSeason', 'TriggerRainfallLevel'],
                name='api_persona_Disease_ea84bb_idx',
            ),
        ),
    ]