FROM debian:stable

MAINTAINER Florian JUDITH <florian.judith.b@gmail.com>

ENV TERM=xterm

ENV DEBIAN_FRONTEND noninteractive

ENV GUEST_USERNAME=ftp

RUN groupadd --system --gid 1234 waarp && \
	useradd --system --create-home --shell /bin/bash --gid 1234 --uid 1234 waarp

RUN set -x && \
    apt-get -y update && \
    apt-get -y --no-install-recommends install \
        vim \
        nano \
        crudini \
        supervisor \
        krb5-user \
        winbind \
        samba-dsdb-modules \
        samba


RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN chmod g+rwx /home

RUN env --unset=DEBIAN_FRONTEND

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
COPY assets/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 137 138 139 445

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["bash"]
