FROM docker.io/library/ubuntu:26.04
RUN apt-get update && \
    apt-get install -y --no-install-recommends bind9 bind9utils && \
    rm -rf /var/lib/apt/lists/*
COPY named.conf.options /etc/bind/
COPY named.conf.local /etc/bind/
COPY xfer.key /etc/bind/
RUN chown root:bind /etc/bind/xfer.key && chmod 640 /etc/bind/xfer.key
EXPOSE 53/tcp 53/udp
CMD ["/usr/sbin/named", "-g", "-u", "bind", "-c", "/etc/bind/named.conf"]
