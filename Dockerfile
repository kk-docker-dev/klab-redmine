# Docker file to build Redmine project manager

# Base image
FROM klab/ubuntu:latest

# About this docker image
LABEL MAINTAINER="Kirubakaran Shanmugam <kribakarans@gmail.com>"
LABEL DESCRIPTION="Klab Redmine project manager"

# Install required packages
RUN apt-get update && \
    apt-get upgrade -y --no-install-recommends && \
    apt-get install -y --no-install-recommends \
            apache2 build-essential libapache2-mod-passenger libsqlite3-dev ruby-dev wget

# Clean repositories
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy source
COPY src /klab

# Download required redmine archives
RUN mkdir -p /opt/redmine && \
    wget --no-verbose --show-progress \
         --quiet --progress=bar:force:noscroll \
           https://github.com/atomixcloud/archives/releases/download/redmine/redmine-5.0.5.tar.gz && \
    wget --no-verbose --show-progress \
         --quiet --progress=bar:force:noscroll \
           https://github.com/atomixcloud/archives/releases/download/redmine/redmine_agile-1.6.5.tgz && \
    wget --no-verbose --show-progress \
         --quiet --progress=bar:force:noscroll \
           https://github.com/atomixcloud/archives/releases/download/redmine/redmine_code_review-1.1.0.tgz && \
    wget --no-verbose --show-progress \
         --quiet --progress=bar:force:noscroll \
           https://github.com/atomixcloud/archives/releases/download/redmine/redmine_purple_theme-2-2.15.tgz

# Extract and install archives
RUN mkdir -p /opt/redmine/public/themes/Purple && \
    mkdir -p /opt/redmine/plugins/redmine_agile && \
    mkdir -p /opt/redmine/plugins/redmine_code_review && \
    tar -xf redmine-5.0.5.tar.gz -C /opt/redmine --strip=1 && \
    tar -xf redmine_agile-1.6.5.tgz -C /opt/redmine/plugins/redmine_agile --strip=1 && \
    tar -xf redmine_purple_theme-2-2.15.tgz -C /opt/redmine/public/themes/Purple --strip=1 && \
    tar -xf redmine_code_review-1.1.0.tgz -C /opt/redmine/plugins/redmine_code_review --strip=1 && \
    rm -f redmine-5.0.5.tar.gz redmine_agile-1.6.5.tgz redmine_code_review-1.1.0.tgz redmine_purple_theme-2-2.15.tgz

ENV REDMINE_LANG en
ENV RAILS_ENV production
# Setup Redmine database and gems
RUN cp -f /klab/configs/database.yml /opt/redmine/config/database.yml && \
    cd /opt/redmine && \
    gem install bundler && \
    bundle config set --local without 'development test'  && \
    bundle install && \
    bundle exec rake generate_secret_token && \
    bundle exec rake db:migrate && \
    bundle exec rake redmine:load_default_data && \
    bundle exec rake redmine:plugins NAME=redmine_agile && \
    bundle exec rake redmine:plugins NAME=redmine_code_review

# Setup Redmine Apache configs
RUN cp -f /klab/configs/passenger.conf /etc/apache2/mods-available/passenger.conf && \
    cat /klab/configs/redmine.conf >> /etc/apache2/sites-available/000-default.conf && \
    ln -sf /opt/redmine/public /var/www/html/redmine && \
    chown -R www-data:www-data /opt/redmine /var/www/html/redmine

USER root
WORKDIR /root

# Run entrypoint
ENTRYPOINT [ "/klab/init.sh" ]
