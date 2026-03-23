# Stage 1: Build the Flutter Web app
FROM debian:stable-slim AS build-env

# Install only necessary build tools
RUN apt-get update && apt-get install -y \
    curl git wget unzip libstdc++6 python3 \
    && rm -rf /var/lib/apt/lists/*

# Clone Flutter
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Setup Flutter
RUN flutter config --no-analytics
RUN flutter doctor
RUN flutter config --enable-web

# Build the app
COPY . /app
WORKDIR /app
ARG BACKEND_URL
RUN flutter build web --release --dart-define=BASE_URL=$BACKEND_URL

# Stage 2: Serve using Nginx
FROM nginx:alpine
COPY --from=build-env /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
