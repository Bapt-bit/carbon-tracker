# Multi-stage build for PHP application
FROM php:8.2-apache AS base

# Enable required PHP extensions and Apache modules
RUN docker-php-ext-install pdo pdo_mysql mysqli \
   && a2dismod mpm_event mpm_worker 2>/dev/null; \
    a2enmod mpm_prefork \
    && a2enmod rewrite \
    && a2enmod ssl

# Set working directory
WORKDIR /var/www/html

# Copy application files
COPY . .

# Create reports directory if it doesn't exist
RUN mkdir -p /var/www/html/reports

# Set permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html \
    && chmod -R 775 /var/www/html/reports

# Configure Apache to serve from the correct directory
RUN sed -i 's|DocumentRoot /var/www/html|DocumentRoot /var/www/html|g' /etc/apache2/sites-available/000-default.conf

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# Set Apache to run in foreground
CMD ["apache2-foreground"]
