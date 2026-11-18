FROM quay.io/centos/centos:stream8

RUN sed -i 's|mirrorlist=|#mirrorlist=|g' /etc/yum.repos.d/*.repo && \
    sed -i 's|#baseurl=http://mirror.centos.org|baseurl=https://vault.centos.org|g' /etc/yum.repos.d/*.repo

RUN dnf -y install epel-release && \
    dnf -y install openvpn iproute net-tools && \
    dnf clean all

COPY ./client.conf /etc/openvpn/client.conf
COPY ./static.key /etc/openvpn/static.key

CMD openvpn --config /etc/openvpn/client.conf