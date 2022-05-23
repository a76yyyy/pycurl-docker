# 基础镜像
FROM a76yyyy/ddddocr:latest

# 维护者信息
LABEL maintainer "a76yyyy <q981331502@163.com>"
LABEL org.opencontainers.image.source=https://github.com/qiandao-today/pycurl-docker

# Envirenment for pycurl
ENV PYCURL_SSL_LIBRARY=openssl
ENV CURL_VERSION=7.83.1

# Install packages & Install openssl ngtcp2 nghttp3 curl & Pip install pycurl
RUN apk update && \
    apk add --update --no-cache bash git tzdata nano openssh-client ca-certificates\
    python3 py3-pip py3-setuptools py3-wheel && \
    apk add --update --no-cache --virtual .build_deps cmake make perl autoconf g++ automake linux-headers libtool util-linux file libidn2-dev libgsasl-dev krb5-dev zstd-dev nghttp2-dev zlib-dev brotli-dev python3-dev c-ares-dev && \
    file /bin/busybox && \
    [[ $(getconf LONG_BIT) = "32" && -z $(file /bin/busybox | grep -i "arm") ]] && configtmp="setarch i386 ./config -m32" || configtmp="./config " && \
    wget https://curl.haxx.se/download/curl-$CURL_VERSION.tar.bz2 && \
    tar xjvf curl-$CURL_VERSION.tar.bz2 && \
    rm curl-$CURL_VERSION.tar.bz2 && \
    git clone --depth 1 -b OpenSSL_1_1_1o+quic https://github.com/quictls/openssl && \
    git clone --depth 1 https://github.com/ngtcp2/nghttp3 && \
    git clone --depth 1 https://github.com/ngtcp2/ngtcp2 && \
    cd openssl && \
    echo $configtmp enable-tls1_3 --prefix=/usr && \
    $configtmp enable-tls1_3 --prefix=/usr && \
    make -j$(($(grep -c ^processor /proc/cpuinfo) - 0)) && \
    make install_sw && \
    cd .. && \
    rm -rf openssl && \
    cd nghttp3 && \
    autoreconf -i && \
    ./configure --prefix=/usr --enable-lib-only && \
    make -j$(($(grep -c ^processor /proc/cpuinfo) - 0)) check && \
    make install && \
    cd .. && \
    rm -rf nghttp3 && \
    cd ngtcp2 && \
    autoreconf -i && \
    ./configure PKG_CONFIG_PATH=/usr/lib/pkgconfig LDFLAGS="-Wl,-rpath,/usr/lib" --prefix=/usr --enable-lib-only && \
    make -j$(($(grep -c ^processor /proc/cpuinfo) - 0)) check && \
    make install && \
    cd .. && \
    rm -rf ngtcp2 && \
    cd curl-$CURL_VERSION && \
    autoreconf -fi && \
    LDFLAGS="-Wl,-rpath,/usr/lib" ./configure \
        --with-openssl=/usr \
        --with-nghttp2=/usr \
        --with-nghttp3=/usr \
        --with-ngtcp2=/usr \
        --prefix=/usr \
        --enable-ipv6 \
        --enable-unix-sockets \
        --with-libidn2 \
        --disable-static \
        --disable-ldap \
        --with-pic \
        --with-gssapi \
        --enable-ares && \
    make -j$(($(grep -c ^processor /proc/cpuinfo) - 0)) && \
    make install && \
    cd .. && \
    rm -rf ./curl-$CURL_VERSION && \
    pip install --no-cache-dir --compile pycurl && \
    apk del .build_deps && \
    apk add --update --no-cache libidn2 libgsasl krb5 zstd-dev nghttp2 zlib brotli c-ares && \
    rm -rf /var/cache/apk/* && \
    rm -rf /usr/share/man/* 
