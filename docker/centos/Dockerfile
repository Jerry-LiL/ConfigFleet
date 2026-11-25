FROM quay.io/centos/centos:stream9

RUN dnf -y install \
        systemd \
        sudo \
        python3 \
        ca-certificates \
        openssh-server \
    && dnf clean all \
    && ln -sf /dev/null /etc/systemd/system/systemd-udevd.service \
    && ssh-keygen -A \
    && mkdir -p /var/run/sshd /bootstrap /etc/systemd/system/multi-user.target.wants \
    && ln -sf /usr/lib/systemd/system/sshd.service \
        /etc/systemd/system/multi-user.target.wants/sshd.service

COPY scripts/node-bootstrap.sh /usr/local/sbin/node-bootstrap.sh
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod 0755 /usr/local/sbin/node-bootstrap.sh /entrypoint.sh

STOPSIGNAL SIGRTMIN+3
ENTRYPOINT ["/entrypoint.sh"]
