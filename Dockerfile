FROM ubuntu:20.04 as base

ENV DEBIAN_FRONTEND="noninteractive" MEGA_SDK_VERSION="3.9.5"

RUN apt-get -qqy update \
    && apt install -qqy --no-install-recommends \
    python3 python3-pip python3-lxml software-properties-common \
    && add-apt-repository -y ppa:qbittorrent-team/qbittorrent-stable \
    && apt install -qqy --no-install-recommends \
    qbittorrent-nox tzdata p7zip-full p7zip-rar xz-utils pv jq \
    ffmpeg locales unzip neofetch \
    && rm -rf /var/lib/apt/lists/* \
    && apt -qqy autoclean


FROM base as builder

RUN apt -qqy update \
    && apt install -qqy --no-install-recommends aria2 \
    make g++ gcc automake autoconf libtool libcurl4-openssl-dev qt5-default \
    git libsodium-dev libssl-dev libcrypto++-dev libc-ares-dev \
    libsqlite3-dev libfreeimage-dev swig libboost-all-dev \
    libpthread-stubs0-dev zlib1g-dev libpq-dev libffi-dev \
    && rm -rf /var/lib/apt/lists/* \
    && apt -qqy autoclean

# Installing Mega SDK Python Binding
RUN git clone https://github.com/meganz/sdk.git --depth=1 -b v$MEGA_SDK_VERSION ~/home/sdk \
    && cd ~/home/sdk && rm -rf .git \
    && autoupdate -fIv && ./autogen.sh \
    && ./configure --disable-silent-rules --enable-python --with-sodium --disable-examples \
    && make -j$(nproc --all) \
    && cd bindings/python/ && python3 setup.py bdist_wheel


FROM base

COPY --from=builder /root/home/sdk/bindings/python/dist/ /root/mega-sdk

RUN pip3 install /root/mega-sdk/megasdk-$MEGA_SDK_VERSION-*.whl \
    && rm -rf /root/mega-sdk \
    && locale-gen en_US.UTF-8

ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8