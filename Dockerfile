FROM alpine:3.6
MAINTAINER Zane Williamson <zane.williamson@gmail.com>

# Install apk packages
RUN apk update && \
    apk add build-base \
    git \
    openssl \
    ruby \
    ruby-dev \
    ruby-bundler \
    ruby-rdoc \
    ruby-bigdecimal \
    ruby-irb \
    ruby-json \
    ruby-io-console \
    --no-cache

ADD . /app/
ADD lib /app/lib

VOLUME /app
WORKDIR /app

RUN gem install bundler && \
    bundle install && \
    rake install

ENTRYPOINT ["deadman-check"]
