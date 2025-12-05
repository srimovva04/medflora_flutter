# Dockerfile for the Flutter frontend

# Stage 1: Build the Flutter app
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app
COPY . .
RUN flutter build web

# Stage 2: Serve the app with Nginx
FROM nginx:alpine

# Copy the custom Nginx configuration
# This comes from the nginx folder in your project root
COPY ../nginx/default.conf /etc/nginx/conf.d/default.conf

# Copy the built web files
COPY --from=builder /app/build/web /usr/share/nginx/html