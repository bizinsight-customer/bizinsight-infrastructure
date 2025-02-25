FROM nginx:alpine

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Create directory for frontend files
RUN mkdir -p /usr/share/nginx/html

# Create directory for SSL certificates
RUN mkdir -p /etc/nginx/ssl

# Copy SSL certificates
COPY ssl/nginx.crt /etc/nginx/ssl/
COPY ssl/nginx.key /etc/nginx/ssl/

# Copy frontend build files (will be mounted via volume)
# The actual files will be mounted at runtime

EXPOSE 80
EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]