FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive

# ===== PASO 2: UHD 4.10 =====

# Dependencias para compilar UHD
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential cmake git ca-certificates pkg-config \
        libboost-all-dev libusb-1.0-0-dev libncurses-dev \
        python3-dev python3-mako python3-numpy python3-requests \
        python3-ruamel.yaml python3-setuptools \
        iputils-ping iproute2 \
    && rm -rf /var/lib/apt/lists/*

# Bajar UHD 4.10 del repo de Ettus, compilarlo e instalarlo
ARG UHD_TAG=v4.10.0.0
RUN git clone --depth 1 --branch ${UHD_TAG} https://github.com/EttusResearch/uhd.git /tmp/uhd \
    && cmake -S /tmp/uhd/host -B /tmp/uhd/host/build \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DENABLE_PYTHON_API=ON \
        -DENABLE_TESTS=OFF \
    && cmake --build /tmp/uhd/host/build -j"$(nproc)" \
    && cmake --install /tmp/uhd/host/build \
    && ldconfig \
    && rm -rf /tmp/uhd

# Control: si no quedó UHD 4.10, el build se corta
RUN uhd_config_info --version | grep -q "4.10" \
    || (echo "ERROR: UHD no es 4.10" && exit 1)
# ===== PASO 3: GNU Radio compilado contra UHD 4.10 =====

# Dependencias para compilar GNU Radio (ninguna trae UHD)
RUN apt-get update && apt-get install -y --no-install-recommends \
        libgmp-dev libfftw3-dev libgsl-dev libvolk-dev libspdlog-dev \
        liblog4cpp5-dev libzmq3-dev libsndfile1-dev libsdl1.2-dev \
        libcodec2-dev libgsm1-dev libudev-dev \
        libqwt-qt5-dev libqt5opengl5-dev qtbase5-dev \
        pybind11-dev python3-pyqt5 python3-qtpy python3-matplotlib \
        python3-scipy python3-yaml python3-click python3-click-plugins \
        python3-zmq python3-lxml python3-packaging python3-jsonschema \
        python3-gi python3-gi-cairo gir1.2-gtk-3.0 \
    && rm -rf /var/lib/apt/lists/*

# Bajar GNU Radio, compilarlo (encuentra el UHD 4.10 de /usr/local) e instalarlo
ARG GR_TAG=v3.10.12.0
RUN git clone --depth 1 --branch ${GR_TAG} https://github.com/gnuradio/gnuradio.git /tmp/gnuradio \
    && cmake -S /tmp/gnuradio -B /tmp/gnuradio/build \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DPYTHON_EXECUTABLE=/usr/bin/python3 \
        -DENABLE_GR_UHD=ON \
        -DENABLE_GR_SOAPY=OFF \
        -DENABLE_GR_IIO=OFF \
        -DENABLE_TESTING=OFF \
        -DENABLE_DOXYGEN=OFF \
    && cmake --build /tmp/gnuradio/build -j"$(nproc)" \
    && cmake --install /tmp/gnuradio/build \
    && ldconfig \
    && rm -rf /tmp/gnuradio

# Que Python encuentre los módulos instalados en /usr/local
ENV PYTHONPATH=/usr/local/lib/python3/dist-packages:/usr/local/lib/python3.12/dist-packages:/usr/local/lib/python3.12/site-packages

# Control 1: no tiene que haber ningún UHD instalado por apt
RUN ! dpkg -l | grep -q libuhd \
    || (echo "ERROR: hay un UHD de apt instalado" && exit 1)

# Control 2: el UHD que usa GNU Radio tiene que ser 4.10
RUN python3 -c "from gnuradio import uhd; v = uhd.get_version_string(); print('GNU Radio usa UHD', v); assert '4.10' in v"

# ===== PASO 4: imágenes FPGA de la X310 (misma versión que UHD) =====
RUN uhd_images_downloader -t x310
