# FarmAid/farm_aid_backend/api/management/commands/fetch_weather.py

import requests
from django.core.management.base import BaseCommand
from api.models import WeatherData

class Command(BaseCommand):
    help = 'Fetches real-time weather from OpenWeatherMap and triggers alerts'

    def handle(self, *args, **options):
        API_KEY = "9ccb07032dd4d3480d8e3d0dbadbe8a5"
        CITY = "Maseru,LS"
        URL = f"https://api.openweathermap.org/data/2.5/weather?q={CITY}&appid={API_KEY}&units=metric"

        self.stdout.write(f"Fetching live weather for {CITY}...")

        try:
            response = requests.get(URL, timeout=10)
            data = response.json()

            if response.status_code == 200:
                temp = data['main']['temp']
                humidity = data['main']['humidity']
                rain = data.get('rain', {}).get('1h', 0.0)

                # Save to WeatherData table
                # This triggers signals.py automatically
                WeatherData.objects.create(
                    Temperature=temp,
                    Humidity=humidity,
                    Rainfall=rain,
                    AlertMessage=f"Weather: {data['weather'][0]['description']}"
                )
                
                self.stdout.write(self.style.SUCCESS(
                    f'Successfully updated: {temp}°C and {humidity}% humidity.'
                ))
            else:
                self.stdout.write(self.style.ERROR(f"API Error: {data.get('message')}"))

        except requests.exceptions.RequestException as e:
            self.stdout.write(self.style.ERROR(f"Network Error: {str(e)}"))