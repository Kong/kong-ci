FROM debian:9

COPY setup_env.sh /

ENV DOWNLOAD_CACHE /download
ENV INSTALL_CACHE /install

ENV OPENSSL 1.0.2n
ENV OPENRESTY 1.13.6.2
ENV LUAROCKS 2.4.3

RUN apt-get update && \
	apt-get install -y build-essential zlib1g-dev curl git libpcre3-dev unzip

RUN /bin/bash -c 'source /setup_env.sh'
