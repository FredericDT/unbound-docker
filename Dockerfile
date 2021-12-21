FROM library/ubuntu:focal AS builder
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
RUN apt clean
RUN sed -i -E 's/(archive|security).ubuntu.com/mirrors.bupt.edu.cn/g' /etc/apt/sources.list
RUN apt update && apt install -y wget tar 
WORKDIR /opt
RUN wget https://www.nlnetlabs.nl/downloads/unbound/unbound-1.13.2.tar.gz && tar -zxf unbound-1.13.2.tar.gz
RUN apt install -y build-essential file \
    libldns-dev libevent-dev libssl-dev libexpat1-dev \
    libhiredis-dev libnghttp2-dev libprotobuf-c-dev \
    protobuf-c-compiler libsodium-dev libmnl-dev \
    libpthread-stubs0-dev
RUN useradd -s /bin/false unbound
RUN cd unbound-1.13.2 && ./configure --prefix=/ \
    --enable-subnet \
    --enable-tfo-client \
    --enable-tfo-server \
    --enable-cachedb \
    --enable-ipsecmod \
    --enable-ipset \
    --without-pyunbound \
    --without-pythonmodule \
    --with-username=unbound \
    --with-pthreads \
    --with-ssl \
    --with-deprecate-rsa-1024 \
    --with-libevent \
    --with-libhiredis \
    --with-libnghttp2 \
    --with-protobuf-c \
    --with-libsodium \
    --with-libmnl \
    && make -j 

FROM library/ubuntu:focal 
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
RUN apt clean
RUN sed -i -E 's/(archive|security).ubuntu.com/mirrors.bupt.edu.cn/g' /etc/apt/sources.list
RUN apt update && apt install -y libldns2 libevent-2.1-7 \
    libhiredis0.14 libnghttp2-14 libprotobuf-c1 \
    libsodium23 libmnl0 libpthread-workqueue0 libexpat1
RUN useradd -s /bin/false unbound
COPY --from=builder /opt/unbound-1.13.2/unbound /sbin/unbound
COPY --from=builder /opt/unbound-1.13.2/unbound-checkconf /sbin/unbound-checkconf
COPY --from=builder /opt/unbound-1.13.2/unbound-control /sbin/unbound-control
COPY --from=builder /opt/unbound-1.13.2/unbound-host /sbin/unbound-host
COPY --from=builder /opt/unbound-1.13.2/unbound-anchor /sbin/unbound-anchor
COPY unbound.conf /etc/unbound/unbound.conf
ENTRYPOINT /sbin/unbound
CMD [""]
EXPOSE 53
