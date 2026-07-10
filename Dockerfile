# Multi-stage build for PHP application
FROM php:8.2-apache AS base

RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install pdo pdo_mysql mysqli


# Enable required PHP extensions
RUN docker-php-ext-install pdo pdo_mysql mysqli

# Ensure only mpm_prefork is active (required for mod_php)
RUN a2dismod mpm_event || true
RUN a2dismod mpm_worker || true
RUN a2dismod mpm_prefork || true
RUN a2enmod mpm_prefork

# Enable other required modules
RUN a2enmod rewrite
RUN a2enmod ssl

# Diagnostic: confirm which MPM modules are enabled (visible in build logs)
RUN ls -la /etc/apache2/mods-enabled/ | grep mpm

# Set working directory
WORKDIR /var/www/html

# Copy application files
COPY php/ /var/www/html/php/
COPY html/ /var/www/html/html/
COPY css/ /var/www/html/css/
COPY js/ /var/www/html/js/

# Create reports directory if it doesn't exist
RUN mkdir -p /var/www/html/reports

# Set permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html \
    && chmod -R 775 /var/www/html/reports

# Configure Apache to serve from the correct directory
RUN sed -i 's|DocumentRoot /var/www/html|DocumentRoot /var/www/html|g' /etc/apache2/sites-available/000-default.conf

RUN echo '<FilesMatch "^\.">\n\
    Require all denied\n\
</FilesMatch>\n\
<FilesMatch "\.(env|sql|md|yml|yaml|txt)$">\n\
    Require all denied\n\
</FilesMatch>' >> /etc/apache2/apache2.conf

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# Set Apache to run in foreground
CMD sh -c "PORT=\${PORT:-80}; sed -i \"s/Listen 80/Listen \$PORT/\" /etc/apache2/ports.conf && sed -i \"s/:80/:\$PORT/\" /etc/apache2/sites-available/000-default.conf && rm -f /etc/apache2/mods-enabled/mpm_event.* /etc/apache2/mods-enabled/mpm_worker.*; a2enmod mpm_prefork; apache2-foreground"
