# Stage 1: Build the Flutter Web app
FROM debian:stable-slim AS build-env

# Install minimal build tools only
RUN apt-get update && apt-get install -y \
    curl git wget unzip libstdc++6 python3 \
    && rm -rf /var/lib/apt/lists/*

# Clone Flutter SDK
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Configuration to bypass Gradle/Android downloads
RUN flutter config --no-analytics
RUN flutter config --no-enable-android --no-enable-ios --enable-web

# Copy project files from the farm_aid_app directory
COPY . /app
WORKDIR /app

# The build command will download only necessary web artifacts
ARG BACKEND_URL
RUN flutter build web --release --dart-define=BASE_URL=$BACKEND_URL

# Stage 2: Serve using Nginx
FROM nginx:alpine
COPY --from=build-env /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
