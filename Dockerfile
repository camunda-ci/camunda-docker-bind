FROM centos:7

RUN yum install -y bind && \
    yum clean all && \
    rm -rf /var/cache/*/var/lib/yum/lists/* /tmp/* /var/tmp/

ADD etc/named.conf /etc/named.conf

RUN chown named:named /etc/named.conf

EXPOSE 53/tcp 53/udp

CMD ["/usr/sbin/named", "-u", "named", "-g"]
