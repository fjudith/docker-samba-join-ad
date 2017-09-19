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
        dbus \
        realmd \
        krb5-user \
        libpam-krb5 \
        adcli \
        winbind \
        libnss-winbind \
        samba \
        samba-client \
        libpam-mount \
        policykit-1 \
        packagekit \
        sssd \
        sssd-tools \
        libnss-sss \
        libpam-sss \
        adcli \
        supervisor

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN systemctl enable sssd

RUN mkdir -p /var/lib/samba/private

RUN chmod 777 /home

RUN env --unset=DEBIAN_FRONTEND

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
COPY assets/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 137 138 139 445

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ['/usr/bin/supervisord', '-c','/etc/supervisor/conf.d/supervisord.conf']





