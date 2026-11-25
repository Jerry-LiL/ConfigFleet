FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        systemd \
        systemd-sysv \
        dbus \
        sudo \
        python3 \
        python3-apt \
        ca-certificates \
        openssh-server \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf /dev/null /etc/systemd/system/systemd-udevd.service \
    && mkdir -p /var/run/sshd /bootstrap

COPY scripts/node-bootstrap.sh /usr/local/sbin/node-bootstrap.sh
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod 0755 /usr/local/sbin/node-bootstrap.sh /entrypoint.sh

STOPSIGNAL SIGRTMIN+3
ENTRYPOINT ["/entrypoint.sh"]
