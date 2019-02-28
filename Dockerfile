FROM ubuntu:18.04

ENV BIND_USER=bind \
    DATA_DIR=/data

RUN echo 'APT::Install-Recommends 0;' >> /etc/apt/apt.conf.d/01norecommends && \
    echo 'APT::Install-Suggests 0;' >> /etc/apt/apt.conf.d/01norecommends && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y curl net-tools ca-certificates apt-transport-https && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y bind9 bind9-host dnsutils && \
    mkdir -p /var/named/log /var/named/data && \
    chown -R bind:bind /var/named && \
    rm -rf /var/lib/apt/lists/*

COPY /etc/bind /etc/bind
COPY bin/docker-entrypoint.sh /sbin/docker-entrypoint.sh

EXPOSE 53/udp 53/tcp 8053/tcp
ENTRYPOINT ["/sbin/docker-entrypoint.sh"]
CMD ["/usr/sbin/named", "-g"]
