FROM ghcr.io/linuxserver/baseimage-alpine-nginx:3.15

# set version label
ARG BUILD_DATE
ARG VERSION
ARG LYCHEE_VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="hackerman"

RUN \
  echo "**** install build packages ****" && \
  apk add --no-cache --virtual=build-dependencies \
    composer && \
  echo "**** install runtime packages ****" && \
  apk add --no-cache \
    curl \
    exiftool \
    ffmpeg \
    gd \
    imagemagick \
    jpegoptim \
    php8-bcmath \
    php8-ctype \
    php8-dom \
    php8-exif \
    php8-gd \
    php8-intl \
    php8-json \
    php8-mbstring \
    php8-mysqli \
    php8-pdo_mysql \
    php8-pecl-imagick \
    php8-phar \
    php8-session \
    php8-tokenizer \
    php8-xml \
    php8-zip && \
  echo "**** configure php-fpm to pass env vars ****" && \
  sed -E -i 's/^;?clear_env ?=.*$/clear_env = no/g' /etc/php8/php-fpm.d/www.conf && \
  grep -qxF 'clear_env = no' /etc/php8/php-fpm.d/www.conf || echo 'clear_env = no' >> /etc/php8/php-fpm.d/www.conf && \
  echo "**** install lychee ****" && \
  if [ -z "${LYCHEE_VERSION}" ]; then \
    LYCHEE_VERSION=$(curl -sX GET "https://api.github.com/repos/LycheeOrg/Lychee/releases/latest" \
    | awk '/tag_name/{print $4;exit}' FS='[""]'); \
  fi && \
  mkdir /app/lychee && \
  git clone --recurse-submodules https://github.com/LycheeOrg/Lychee.git /app/lychee && \
  cd /app/lychee && \
  git checkout "${LYCHEE_VERSION}" && \
  echo "**** install composer dependencies ****" && \
  composer install \
    -d /app/lychee \
    --no-dev \
    --no-interaction && \
  echo "**** cleanup ****" && \
  apk del --purge \
    build-dependencies && \
  rm -rf \
    /root/.cache \
    /root/.composer \
    /tmp/*

# copy local files
COPY root/ /

# ports and volumes
EXPOSE 80 443
VOLUME /config
