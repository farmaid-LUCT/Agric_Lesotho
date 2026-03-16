from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('api', '0010_translationcache'),
    ]

    operations = [
        migrations.SeparateDatabaseAndState(
            database_operations=[],
            state_operations=[
                migrations.CreateModel(
                    name='TranslationCache',
                    fields=[
                        ('disease_name_en', models.CharField(
                            max_length=255,
                            primary_key=True,
                            serialize=False,
                        )),
                        ('pesticide_st', models.CharField(
                            max_length=255,
                            verbose_name='Moriana (Sesotho)',
                        )),
                        ('dosage_st', models.CharField(
                            max_length=255,
                            verbose_name='Tekanyetso (Sesotho)',
                        )),
                        ('steps_st', models.TextField(
                            verbose_name='Mekhoa ea Tšebeliso (Sesotho)',
                        )),
                        ('last_updated', models.DateTimeField(auto_now=True)),
                    ],
                ),
            ],
        ),
    ]