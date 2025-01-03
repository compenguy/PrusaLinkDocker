# syntax=docker/dockerfile:1
FROM debian:bookworm-slim AS prusalink_builder

# From https://github.com/prusa3d/Prusa-Link/blob/master/image_builder/image_builder.py
# except for pi-only deps: pigpio python3-libcamera
RUN apt-get update \
    && apt-get install -y \
        build-essential \
        git \
        python3-pip \
        libcap-dev \
        libmagic1 \
        libturbojpeg0 \
        libatlas-base-dev \
        libffi-dev \
        cmake \
        iptables \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --break-system-packages PrusaLink

FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y \
        python3-pip \
        libmagic1 \
        libturbojpeg0 \
        iptables \
    && rm -rf /var/lib/apt/lists/*

COPY --from=prusalink_builder /usr/local/ /usr/local/
RUN mkdir -p /etc/prusalink

RUN groupadd -g 1000 prusalink \
    && useradd -rm -u 1000 -d /home/prusalink -s /bin/bash -g prusalink -G dialout,video prusalink \
    && usermod -aG video prusalink

USER prusalink
WORKDIR /home/prusalink

# For debugging
#CMD ["prusalink", "-f", "-i"]
CMD ["prusalink", "-f"]
