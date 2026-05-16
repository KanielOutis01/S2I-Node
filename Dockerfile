# ==========================================
# Stage 1 - Angular Build
# ==========================================

FROM docker-registry.default.svc:5000/openshift/adibnodejs:latest-ora AS build

WORKDIR /app

COPY package*.json ./

RUN npm ci

COPY . .

RUN npm run build -- --configuration production


# ==========================================
# Stage 2 - NGINX Runtime
# ==========================================

FROM docker-registry.default.svc:5000/openshift/adibnginx:latest

COPY nginx.conf /etc/nginx/nginx.conf

COPY --from=build /app/dist/adib-pro-01/browser /usr/share/nginx/html

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]