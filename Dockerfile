FROM debian:stable-slim as xdm-builder
# defined from build kit
# DOCKER_BUILDKIT=1 docker build . -t ...
ARG TARGETARCH

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt update && \
    apt install -y -q --no-install-recommends \
    git curl gnupg2 build-essential coreutils \
    intltool libglib2.0-0 libglib2.0-dev flex \
    libglade2-0 libglade2-dev guile-3.0-libs \
    guile-3.0-dev \
    ca-certificates apt-transport-https \
    python3 && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /build
ADD https://ftp.gnu.org/gnu/mdk/v1.3.0/mdk-1.3.0.tar.gz mdk-1.3.0.tar.gz
ADD https://ftp.gnu.org/gnu/mdk/v1.3.0/mdk-1.3.0.tar.gz.sig mdk-1.3.0.tar.gz.sig

ADD https://ftp.gnu.org/gnu/gnu-keyring.gpg gnu-keyring.gpg

RUN gpg --quiet --import gnu-keyring.gpg
RUN gpg --verify mdk-1.3.0.tar.gz.sig

RUN tar -zxf mdk-1.3.0.tar.gz

WORKDIR /build/mdk-1.3.0

RUN ./configure
RUN make -j
RUN make install


FROM debian:stable-slim

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt update && \
    apt install -y -q --no-install-recommends \
    git curl gnupg2 build-essential coreutils \
    intltool libglib2.0-0 flex \
    libglade2-0 guile-3.0-libs \
    ca-certificates apt-transport-https \
    python3 && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

RUN useradd --create-home -s /bin/bash mix
RUN usermod -a -G sudo mix
RUN echo '%mix ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

COPY --from=xdm-builder /usr/local/share/info/mdk.info /usr/local/share/info/mdk.info
COPY --from=xdm-builder /usr/local/bin/mixvm /usr/local/bin/
COPY --from=xdm-builder /usr/local/bin/mixasm /usr/local/bin/
COPY --from=xdm-builder /usr/local/bin/mixguile /usr/local/bin/mixguile
COPY --from=xdm-builder /usr/local/share/mdk /usr/local/share/mdk
