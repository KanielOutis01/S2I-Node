# =========================================
# Stage 1 - Angular Build
# =========================================

FROM image-registry.openshift-image-registry.svc:5000/openshift/nodejs:20-minimal AS build

# OpenShift writable directory
WORKDIR /opt/app-root/src

# Copy package files first
COPY package*.json ./

# OpenShift permission handling
RUN chgrp -R 0 /opt/app-root/src && \
    chmod -R g=u /opt/app-root/src

# Copy internal CA certificate
COPY adib-ca.pem /opt/app-root/src/adib-ca.pem

# Configure CA
ENV NODE_EXTRA_CA_CERTS=/opt/app-root/src/adib-ca.pem

RUN npm config set cafile /opt/app-root/src/adib-ca.pem

# Configure internal JFrog registry
RUN npm config set registry "https://artifactory.adib.co.ae:443/artifactory/npm-vi/"

# Optional npm optimizations
RUN npm config set fund false && \
    npm config set audit false && \
    npm config set prefer-offline true && \
    npm config set fetch-retries 2 && \
    npm config set fetch-timeout 200000

# Clean npm cache
RUN npm cache clean --force

# Install dependencies
RUN npm install --legacy-peer-deps

# Copy remaining source code
COPY . .

# Fix permissions again after COPY
RUN chgrp -R 0 /opt/app-root/src && \
    chmod -R g=u /opt/app-root/src

# Build Angular app
RUN npm exec ng build -- --configuration production

# =========================================
# Stage 2 - NGINX Runtime
# =========================================

FROM image-registry.openshift-image-registry.svc:5000/openshift/adibnginx:latest

# Copy nginx config
COPY nginx.conf /etc/nginx/nginx.conf

# Copy Angular dist files
COPY --from=build /opt/app-root/src/dist/adib-pro-01/browser /usr/share/nginx/html

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]