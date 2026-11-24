FROM ghcr.io/cirruslabs/flutter:3.47.6 AS builder

WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

# Build with backend URL injected at build time
ARG BACKEND_URL=http://localhost:3000/api
RUN flutter build web --release --dart-define=BACKEND_URL=${BACKEND_URL}

# Serve with nginx
FROM nginx:alpine
COPY --from=builder /app/build/web /usr/share/nginx/html

COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
