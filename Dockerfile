FROM centos:7

RUN yum install -y bind && \
    yum clean all && \
    rm -rf /var/cache/*/var/lib/yum/lists/* /tmp/* /var/tmp/

COPY etc /etc

RUN chown named:named /etc/named.conf /etc/named/*

EXPOSE 53/tcp 53/udp

CMD ["/usr/sbin/named", "-u", "named", "-g"]
