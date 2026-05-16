# =========================================
# Stage 1 - Angular Build
# =========================================

FROM image-registry.openshift-image-registry.svc:5000/openshift/nodejs:20-minimal-ubi8 AS build

# Use OpenShift writable directory
WORKDIR /opt/app-root/src

# npm writable directories
ENV HOME=/opt/app-root/src
ENV NPM_CONFIG_CACHE=/opt/app-root/src/.npm

# Copy package files
COPY package*.json ./

# Copy internal CA certificate
COPY adib-ca.pem /opt/app-root/src/adib-ca.pem

# Configure internal CA
ENV NODE_EXTRA_CA_CERTS=/opt/app-root/src/adib-ca.pem

RUN npm config set cafile /opt/app-root/src/adib-ca.pem

# Configure internal JFrog registry
RUN npm config set registry "https://artifactory.adib.co.ae:443/artifactory/npm-vi/"

# npm optimizations
RUN npm config set fund false && \
    npm config set audit false && \
    npm config set prefer-offline true && \
    npm config set fetch-retries 2 && \
    npm config set fetch-timeout 200000

# Clean npm cache
RUN npm cache clean --force

# Install dependencies
RUN npm ci --legacy-peer-deps

# Copy source code
COPY . .

# Build Angular into NEW writable directory
RUN npm exec ng build -- \
    --configuration production \
    --output-path=/tmp/angular-build

# =========================================
# Stage 2 - NGINX Runtime
# =========================================

FROM image-registry.openshift-image-registry.svc:5000/openshift/adibnginx:latest

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Copy Angular build output
COPY --from=build /tmp/angular-build/browser /usr/share/nginx/html

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]