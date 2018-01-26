FROM ubuntu:16.04

ENV BIND_USER=bind \
    BIND_VERSION=1:9.10.3 \
    WEBMIN_VERSION=1.870 \
    DATA_DIR=/data

RUN echo 'APT::Install-Recommends 0;' >> /etc/apt/apt.conf.d/01norecommends && \
    echo 'APT::Install-Suggests 0;' >> /etc/apt/apt.conf.d/01norecommends && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y wget net-tools ca-certificates unzip apt-transport-https && \
    rm -rf /var/lib/apt/lists/*

RUN wget http://www.webmin.com/jcameron-key.asc -qO - | apt-key add - && \
    echo "deb http://download.webmin.com/download/repository sarge contrib" >> /etc/apt/sources.list && \
    rm -rf /etc/apt/apt.conf.d/docker-gzip-indexes && \
    rm -rf /var/lib/apt/lists/*lz4 && \
    apt-get -o Acquire::GzipIndexes=false update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y bind9=${BIND_VERSION}* bind9-host=${BIND_VERSION}* webmin=${WEBMIN_VERSION}* dnsutils && \
    rm -rf /var/lib/apt/lists/*

RUN addgroup --gid 2000 webmin && \
    adduser webmin --uid 2000 --gid 2000 --disabled-password --gecos "" && \
    echo "webmin: acl adsl-client ajaxterm apache at backup-config bacula-backup bandwidth bind8 burner change-user cluster-copy cluster-cron cluster-passwd cluster-shell cluster-software cluster-useradmin cluster-usermin cluster-webmin cpan cron custom dfsadmin dhcpd dovecot exim exports fail2ban fdisk fetchmail file filemin filter firewall firewall6 firewalld fsdump grub heartbeat htaccess-htpasswd idmapd inetd init inittab ipfilter ipfw ipsec iscsi-client iscsi-server iscsi-target iscsi-tgtd jabber krb5 ldap-client ldap-server ldap-useradmin logrotate lpadmin lvm mailboxes mailcap man mon mount mysql net nis openslp package-updates pam pap passwd phpini postfix postgresql ppp-client pptp-client pptp-server proc procmail proftpd qmailadmin quota raid samba sarg sendmail servers shell shorewall shorewall6 smart-status smf software spam squid sshd status stunnel syslog-ng syslog system-status tcpwrappers telnet time tunnel updown useradmin usermin vgetty webalizer webmin webmincron webminlog wuftpd xinetd" > /etc/webmin/webmin.acl && \
    echo "webmin:x:2000" > /etc/webmin/miniserv.users && \
    sed 's/root/webmin/' /etc/webmin/webmin.acl >> /etc/webmin/webmin.acl

COPY /etc/bind /etc/bind
COPY bin/docker-entrypoint.sh /sbin/docker-entrypoint.sh

EXPOSE 53/udp 53/tcp 10000/tcp
ENTRYPOINT ["/sbin/docker-entrypoint.sh"]
CMD ["/usr/sbin/named", "-g"]
