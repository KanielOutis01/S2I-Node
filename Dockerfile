# =========================================
# Stage 1 - Angular Build
# =========================================

FROM image-registry.openshift-image-registry.svc:5000/openshift/nodejs:20-minimal-ubi8 AS build

WORKDIR /tmp/app

# npm writable directories
ENV HOME=/tmp
ENV NPM_CONFIG_CACHE=/tmp/.npm

# Copy package files
COPY package*.json ./

# Copy internal CA
COPY adib-ca.pem /tmp/app/adib-ca.pem

# Configure CA
ENV NODE_EXTRA_CA_CERTS=/tmp/app/adib-ca.pem

RUN npm config set cafile /tmp/app/adib-ca.pem

# Configure internal registry
RUN npm config set registry "https://artifactory.adib.co.ae:443/artifactory/npm-vi/"

RUN npm config set fund false && \
    npm config set audit false && \
    npm config set prefer-offline true && \
    npm config set fetch-retries 2 && \
    npm config set fetch-timeout 200000

# Clean cache
RUN npm cache clean --force

# Install dependencies
RUN npm install --legacy-peer-deps

# Copy source
COPY . .

# Build Angular
RUN npm exec ng build -- --configuration production

# =========================================
# Stage 2 - NGINX Runtime
# =========================================

FROM image-registry.openshift-image-registry.svc:5000/openshift/adibnginx:latest

COPY nginx.conf /etc/nginx/nginx.conf

COPY --from=build /tmp/app/dist/adib-pro-01/browser /usr/share/nginx/html

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]