FROM ubuntu:18.04

####
# DEPENDENCIES AND TOOLS
####

# Fix some apt install complaints
ENV DEBIAN_FRONTEND=noninteractive

# Install Dependencies ( and busybox for vi )
RUN apt-get update && \
    apt-get install --no-install-suggests -y \
        busybox \
        curl \
        nginx \
        php7.2-fpm \
        php7.2-curl \
        php7.2-ldap \
        php7.2-mbstring \
        php7.2-xml && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create missing PHP run dir
RUN mkdir -p /run/php

# Make an alias for vi
RUN echo "alias vi='busybox vi'" >> /root/.bashrc

# Download Self Service Password
RUN cd /var/www/html && \
    curl -L https://github.com/ltb-project/self-service-password/archive/v1.3.tar.gz > ssp.tgz && \
    tar -xf ssp.tgz && \
    rm ssp.tgz && \
    mv self-service-password-*/* . && \
    rm -rf self-service-password-*/ && \
    chown -R www-data .

# Install Gomplate template tool
RUN curl -L https://github.com/hairyhenderson/gomplate/releases/download/v3.0.0/gomplate_linux-amd64-slim > /usr/local/bin/gomplate && \
    chmod +x /usr/local/bin/gomplate

####
# CONFIGURATION ENVIRONMENT VARIABLES
####

# Set Default environment variables
ENV DEBUG false
ENV LDAP_URL ldap://localhost
ENV LDAP_STARTTLS false
ENV LDAP_BINDDN cn=manager,dc=example,dc=com
ENV LDAP_BINDPW secret
ENV LDAP_BASE dc=exmple,dc=com
ENV LDAP_LOGIN_ATTRIBUTE uid
ENV LDAP_FULLNAME_ATTRIBUTE cn
ENV LDAP_OBJECT_CLASS person
# If LDAP_FILTER is set, LDAP_LOGIN_ATTRIBUTE and LDAP_OBJECT_CLASS will be
# ignored
ENV LDAP_FILTER ""

ENV AD_MODE false

ENV WHO_CHANGE_PASSWORD user
ENV USE_QUESTIONS true

ENV MAIL_PROTOCOL smtp
ENV MAIL_SMTP_DEBUG 0
ENV MAIL_FROM admin@example.com
ENV MAIL_FROM_NAME Self Service Password
ENV NOTIFY_ON_CHANGE false
ENV MAIL_SMTP_HOST localhost
ENV MAIL_SMTP_AUTH false
ENV MAIL_SMTP_USER ""
ENV MAIL_SMTP_PASS ""
ENV MAIL_SMTP_PORT 25
ENV MAIL_SMTP_SECURE tls;

ENV USE_SMS true

# Random secret key used for recovery email link generation
ENV KEYPHRASE secret

ENV REVERSE_PROXY_MODE false

####
# CONFIGURATION FILES AND INIT
####

# Remove the default nginx configuration
RUN rm /etc/nginx/sites-enabled/default

# Add our nginx configuration
COPY ssp-site /etc/nginx/sites-enabled/ssp-site

# Add our SSP configuration template and script
COPY ssp-config.inc.local.php.template /var/www/html/conf/config.inc.local.php.template

# Copy in our container-start and container-start scripts
COPY start-container.sh /start-container.sh
RUN chmod 744 /start-container.sh

COPY stop-container.sh /stop-container.sh
RUN chmod 744 /stop-container.sh

# Copy in our docker-cmd script
COPY docker-cmd.sh /docker-cmd.sh
RUN chmod 744 /docker-cmd.sh

# Set entrypoint to init system that came with justcontainers's s6-overlay
CMD ["/docker-cmd.sh"]
