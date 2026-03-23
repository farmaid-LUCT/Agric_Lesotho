# Stage 1: Build the Flutter Web app for FarmAid
FROM debian:stable-slim AS build-env

# Install minimal build tools
RUN apt-get update && apt-get install -y \
    curl git wget unzip libstdc++6 python3 \
    && rm -rf /var/lib/apt/lists/*

# Clone a stable version of Flutter
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Force the tool to be web-only and bypass mobile environment checks
RUN flutter config --no-analytics
RUN flutter config --no-enable-android --no-enable-ios --enable-web

# Pre-download ONLY the Web engine to keep the build stable on Render's Free Tier
RUN flutter precache --web

# Copy the project files from your farm_aid_app directory
COPY . /app
WORKDIR /app

# Final Build using the Backend URL argument for your Django connection
ARG BACKEND_URL
RUN flutter pub get
RUN flutter build web --release --dart-define=BASE_URL=$BACKEND_URL

# Stage 2: Serve using a professional, lightweight Nginx server
FROM nginx:alpine
COPY --from=build-env /app/build/web /usr/share/nginx/html

# Expose port 80 for the phone browser access
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
