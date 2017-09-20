FROM debian:stable

MAINTAINER Florian JUDITH <florian.judith.b@gmail.com>

ENV TERM=xterm

ENV DEBIAN_FRONTEND noninteractive

RUN set -x && \
    apt-get -y update && \
    apt-get -y --no-install-recommends install \
        dnsutils \
        vim \
        nano \
        crudini \
        supervisor \
        krb5-user \
        libpam-krb5 \
        winbind \
        libnss-winbind \
        libpam-winbind \
        samba \
        samba-dsdb-modules \
        samba-client \
        samba-vfs-modules \
        logrotate \
        attr \
        libpam-mount


RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN chmod g+rwx /home

RUN env --unset=DEBIAN_FRONTEND

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
COPY assets/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 137 138 139 445

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/usr/bin/supervisord","-c","/etc/supervisor/conf.d/supervisord.conf"]