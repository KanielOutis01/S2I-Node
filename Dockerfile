# =========================================
# Stage 1 - Angular Build
# =========================================

FROM image-registry.openshift-image-registry.svc:5000/openshift/nodejs:20-minimal-ubi8 AS build

# Use OpenShift writable directory
WORKDIR /opt/app-root/src

# npm writable dirs
ENV HOME=/opt/app-root/src
ENV NPM_CONFIG_CACHE=/opt/app-root/src/.npm

# Copy package files
COPY package*.json ./

# Copy internal CA
COPY adib-ca.pem /opt/app-root/src/adib-ca.pem

# Configure CA
ENV NODE_EXTRA_CA_CERTS=/opt/app-root/src/adib-ca.pem

RUN npm config set cafile /opt/app-root/src/adib-ca.pem

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

COPY --from=build /opt/app-root/src/dist/adib-pro-01/browser /usr/share/nginx/html

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]