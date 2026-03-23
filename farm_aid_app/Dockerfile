# Stage 1: Build the Flutter Web app
FROM debian:stable-slim AS build-env

# Install only the necessary build tools for Flutter Web
RUN apt-get update && apt-get install -y \
    curl git wget unzip libstdc++6 python3 \
    && rm -rf /var/lib/apt/lists/*

# Clone the Flutter SDK
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter

# Set the Flutter path
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Configuration to bypass the Gradle/Android errors (Critical for Render)
RUN flutter config --no-analytics
RUN flutter config --no-enable-android --no-enable-ios --enable-web

# Pre-download ONLY the Web artifacts to avoid filesystem permission issues
RUN flutter precache --web

# Copy the project files
COPY . /app
WORKDIR /app

# Accept the Backend URL as a build argument from Render
ARG BACKEND_URL
RUN flutter build web --release --dart-define=BASE_URL=$BACKEND_URL

# Stage 2: Serve the compiled app using a lightweight Nginx server
FROM nginx:alpine
COPY --from=build-env /app/build/web /usr/share/nginx/html

# Expose port 80 for the phone browser to access
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
