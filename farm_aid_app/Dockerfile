# Stage 1: Build the Flutter Web app
FROM debian:stable-slim AS build-env

RUN apt-get update && apt-get install -y \
    curl git wget unzip libstdc++6 python3 \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Force the tool to be web-only before we even touch your code
RUN flutter config --no-analytics
RUN flutter config --no-enable-android --no-enable-ios --enable-web

# Clean any half-downloaded junk that might cause ownership errors
RUN rm -rf /usr/local/flutter/bin/cache/artifacts/gradle_wrapper

COPY . /app
WORKDIR /app

# Final Build - forcing only web and skipping pub get if already resolved
ARG BACKEND_URL
RUN flutter pub get
RUN flutter build web --release --dart-define=BASE_URL=$BACKEND_URL

# Stage 2: Serve using Nginx
FROM nginx:alpine
COPY --from=build-env /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
