FROM quay.io/centos/centos:stream8

# Corrigir repositórios
RUN sed -i 's|mirrorlist=|#mirrorlist=|g' /etc/yum.repos.d/*.repo && \
    sed -i 's|#baseurl=http://mirror.centos.org|baseurl=https://vault.centos.org|g' /etc/yum.repos.d/*.repo

RUN dnf -y install epel-release && \
    dnf -y install openvpn iproute net-tools && \
    dnf clean all

COPY ./server.conf /etc/openvpn/server.conf
COPY ./static.key /etc/openvpn/static.key

EXPOSE 1194/udp

CMD openvpn --config /etc/openvpn/server.conf