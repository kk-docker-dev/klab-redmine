# Docker file to build Klab Redmine

# Base image
FROM ubuntu:focal

# About docker image
LABEL MAINTAINER="Kirubakaran Shanmugam <kribakarans@gmail.com>"
LABEL DESCRIPTION="Klab Redmine"

# Disable user prompt
ARG DEBIAN_FRONTEND=noninteractive

# Update and upgrade the system
RUN apt-get update && \
    apt-get upgrade -y --no-install-recommends

# Install base packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends locales tzdata

# Setting timezone
RUN ln -fs /usr/share/zoneinfo/Asia/Kolkata /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

# Setting locales
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8 && \
    locale-gen en_US.UTF-8

# Setting language
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Install required packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
            apache2 build-essential libapache2-mod-passenger libsqlite3-dev ruby-dev wget

# Download and extract Redmine binaries
RUN mkdir -p /opt/redmine && \
    wget https://www.redmine.org/releases/redmine-5.0.5.tar.gz && \
    tar -xf redmine-5.0.5.tar.gz -C /opt/redmine --strip=1 && \
    rm -f redmine-5.0.5.tar.gz

# Copy source
COPY src /klab

# Setup Redmine Gems
RUN cp -f /klab/configs/database.yml /opt/redmine/config/database.yml && \
    cd /opt/redmine && \
    gem install bundler && \
    bundle config set --local without 'development test'  && \
    bundle install && \
    bundle exec rake generate_secret_token && \
    RAILS_ENV=production bundle exec rake db:migrate && \
    RAILS_ENV=production REDMINE_LANG=en bundle exec rake redmine:load_default_data

# Setup Redmine Apache configs
RUN cp -f /klab/configs/passenger.conf /etc/apache2/mods-available/passenger.conf && \
    cat /klab/configs/redmine.conf >> /etc/apache2/sites-available/000-default.conf && \
    ln -sf /opt/redmine/public /var/www/html/redmine && \
    chown -R www-data:www-data /opt/redmine /var/www/html/redmine

USER root
WORKDIR /root

CMD [ "/klab/startup.sh" ]
