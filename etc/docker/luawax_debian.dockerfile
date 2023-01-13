FROM debian:stable

ARG DEBIAN_FRONTEND=noninteractive
ARG LR_VERSION=luarocks-3.9.0

RUN apt-get -y update;
RUN apt-get -y --no-install-recommends install \
	ncurses-bin \
	lua5.1 liblua5.1-0-dev \
	lua5.2 liblua5.2-dev \
	lua5.3 liblua5.3-dev \
	lua5.4 liblua5.4-dev \
	luajit libluajit-5.1-dev \
	curl ca-certificates \
	build-essential libreadline-dev unzip gcc;

RUN curl \
	"https://luarocks.github.io/luarocks/releases/$LR_VERSION.tar.gz" > /tmp/lr.tgz \
	&& cd /tmp \
	&& tar zxvf /tmp/lr.tgz \
	&& cd $LR_VERSION && ./configure && make install

RUN adduser \
	--home /home/testuser \
	--disabled-password \
	--uid 2000 testuser;
