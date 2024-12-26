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

FROM debian:bookworm-slim AS libcamera_apps_builder

# Build libcamera and rpicam-apps for libcamera-hello
# https://www.raspberrypi.com/documentation/computers/camera_software.html#building-libcamera
RUN apt-get update \
    && apt-get install -y \
        build-essential python3-pip git python3-jinja2 \
        libboost-dev \
        libgnutls28-dev openssl libtiff5-dev pybind11-dev \
        qtbase5-dev libqt5core5a libqt5gui5 libqt5widgets5 \
        meson cmake \
        python3-yaml python3-ply \
        libglib2.0-dev libgstreamer-plugins-base1.0-dev \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/raspberrypi/libcamera.git

RUN cd libcamera \
    && meson setup build --buildtype=release -Dpipelines=rpi/vc4,rpi/pisp -Dipas=rpi/vc4,rpi/pisp -Dv4l2=true -Dgstreamer=disabled -Dtest=false -Dlc-compliance=disabled -Dcam=disabled -Dqcam=disabled -Ddocumentation=disabled -Dpycamera=enabled \
    && ninja -C build \
    && ninja -C build install

# https://www.raspberrypi.com/documentation/computers/camera_software.html#building-rpicam-apps
RUN apt-get update \
    && apt-get install -y \
        build-essential \
        pkg-config \
        git \
        cmake libboost-program-options-dev libdrm-dev libexif-dev \
        libcamera-dev libepoxy-dev libjpeg-dev libtiff5-dev libpng-dev \
        meson ninja-build \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/raspberrypi/rpicam-apps.git

RUN cd rpicam-apps \
    && meson setup build -Denable_libav=disabled -Denable_drm=disabled -Denable_egl=disabled -Denable_qt=disabled -Denable_opencv=disabled -Denable_tflite=disabled \
    && meson compile -C build \
    && meson install -C build

# Start building runtime container
FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y \
        python3-pip \
        libmagic1 \
        libturbojpeg0 \
        fswebcam \
        iptables \
        v4l-utils \
        libboost-program-options1.74 libexif12 libdw1 libunwind8 \
    && rm -rf /var/lib/apt/lists/*

# Add libcamera
COPY --from=libcamera_apps_builder /usr/local/ /usr/local/
RUN ldconfig
# Add prusalink
COPY --from=prusalink_builder /usr/local/ /usr/local/
RUN mkdir -p /etc/prusalink

RUN groupadd -g 1000 pi \
    && useradd -rm -u 1000 -d /home/pi -s /bin/bash -g pi -G dialout,video pi \
    && usermod -aG video pi

USER pi
WORKDIR /home/pi

# For debugging
#CMD ["prusalink", "-f", "-d"]
#CMD ["prusalink", "-f", "-i"]
#CMD ["libcamera-hello", "--list-cameras"]
CMD ["prusalink", "-f"]
