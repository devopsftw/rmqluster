FROM quay.io/justcontainers/base-alpine:v0.12.2
MAINTAINER Danila Shtan <danila@brainkeys.ru>

# Download and install Consul (and python3 needed for our discovery script)
ENV CONSUL_VERSION=0.7.0
RUN apk upgrade --update --update-cache && \
    apk add --update-cache curl python3 && \
    curl -sSLo /tmp/consul.zip https://releases.hashicorp.com/consul/{$CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip && \
    unzip -d /bin /tmp/consul.zip && \
    rm /tmp/consul.zip && \
    addgroup consul && \
    adduser -D -g "" -s /bin/sh -G consul consul && \
    mkdir -p /data/consul && \
    chown -R consul:consul /data/consul
VOLUME ["/data/consul"]

# Download and install RabbitMQ and it's dependencies
# /srv because fucking erlang is fucking buggy — https://github.com/erlang/otp/pull/1128
ENV RABBITMQ_VERSION=3.6.1
ENV RABBITMQ_HOME=/srv/rabbitmq \
	PLUGINS_DIR=/srv/rabbitmq/plugins \
    ENABLED_PLUGINS_FILE=/srv/rabbitmq/etc/rabbitmq/enabled_plugins \
    RABBITMQ_MNESIA_BASE=/var/lib/rabbitmq
ENV	PATH=$PATH:/srv/rabbitmq/sbin
RUN echo "http://dl-4.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories && \
    echo "http://dl-4.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    echo "http://dl-4.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    apk add bash tar xz erlang erlang erlang-mnesia erlang-public-key erlang-crypto erlang-ssl \
        erlang-sasl erlang-asn1 erlang-inets erlang-os-mon erlang-xmerl erlang-eldap \
        erlang-syntax-tools --update --update-cache --allow-untrusted && \
    rmq_zip_url=https://github.com/rabbitmq/rabbitmq-server/releases/download && \
        rmq_zip_url=${rmq_zip_url}/rabbitmq_v$(echo $RABBITMQ_VERSION | tr '.' '_') && \
        rmq_zip_url=${rmq_zip_url}/rabbitmq-server-generic-unix-${RABBITMQ_VERSION}.tar.xz && \
    curl -sSLo /tmp/rmq.tar.xz $rmq_zip_url && \
    tar -xvf /tmp/rmq.tar.xz -C / && rm -f /tmp/rmq.tar.xz && \
    mv /rabbitmq_server-${RABBITMQ_VERSION} /srv/rabbitmq && \
    touch /srv/rabbitmq/etc/rabbitmq/enabled_plugins && \
    apk del --purge tar xz && rm -Rf /var/cache/apk/*
COPY	rabbitmq/rabbitmq.config /srv/rabbitmq/etc/rabbitmq/

RUN rabbitmq-plugins enable --offline rabbitmq_management 

ENV RABBITMQ_LOGS=- RABBITMQ_SASL_LOGS=-
RUN addgroup rabbitmq && \
    adduser -DS -g "" -G rabbitmq -s /bin/sh -h /var/lib/rabbitmq rabbitmq && \
    mkdir -p /data/rabbitmq && \
    chown -R rabbitmq:rabbitmq /data/rabbitmq

ENV HOME /var/lib/rabbitmq

# Add configs
ADD root /