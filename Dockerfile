FROM arm64v8/ubuntu:bionic

WORKDIR /home

RUN apt-get update -y
RUN apt-get install gnupg gnupg2 lsb-release software-properties-common -y
RUN apt purge --auto-remove cmake -y
RUN apt install -y libprotobuf-dev protobuf-compiler wget
RUN wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null
RUN apt-add-repository "deb https://apt.kitware.com/ubuntu/ $(lsb_release -cs) main"
RUN apt update -y
RUN apt install kitware-archive-keyring
RUN rm /etc/apt/trusted.gpg.d/kitware.gpg
RUN apt update -y
RUN apt-get install cmake build-essential colordiff git doxygen -y
RUN apt-get install python3 python3-pip -y
RUN apt install git -y

RUN git clone https://github.com/mavlink/MAVSDK.git

WORKDIR /home/MAVSDK
RUN git checkout main
RUN git submodule update --init --recursive

RUN cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_MAVSDK_SERVER=ON -DBUILD_SHARED_LIBS=OFF -Bbuild/default -H.
RUN cmake --build build/default --target install -- -j4
RUN ldconfig

WORKDIR /home

RUN pip3 install --upgrade pip
RUN pip3 install mavsdk aioconsole
RUN git clone https://github.com/mavlink/MAVSDK-Python.git
WORKDIR /home/MAVSDK-Python
RUN git submodule update --init --recursive

WORKDIR /home
COPY camera.py .
COPY main.py .
COPY start-mavsdk-server.sh .

ENV OPENCV_VERSION="4.5.1"

RUN apt-get -qq update \
    && apt-get -qq install -y --no-install-recommends \
        unzip \
        yasm \
        pkg-config \
        libswscale-dev \
        libtbb2 \
        libtbb-dev \
        libjpeg-dev \
        libpng-dev \
        libtiff-dev \
        libopenjp2-7-dev \
        libavformat-dev \
        libpq-dev \
    && pip install numpy \
    && wget -q https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.zip -O opencv.zip \
    && unzip -qq opencv.zip -d /opt \
    && rm -rf opencv.zip \
    && cmake \
        -D BUILD_TIFF=ON \
        -D BUILD_opencv_java=OFF \
        -D WITH_CUDA=OFF \
        -D WITH_OPENGL=ON \
        -D WITH_OPENCL=ON \
        -D WITH_IPP=ON \
        -D WITH_TBB=ON \
        -D WITH_EIGEN=ON \
        -D WITH_V4L=ON \
        -D BUILD_TESTS=OFF \
        -D BUILD_PERF_TESTS=OFF \
        -D CMAKE_BUILD_TYPE=RELEASE \
        -D CMAKE_INSTALL_PREFIX=$(python3 -c "import sys; print(sys.prefix)") \
        -D PYTHON_EXECUTABLE=$(which python3) \
        -D PYTHON_INCLUDE_DIR=$(python3 -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())") \
        -D PYTHON_PACKAGES_PATH=$(python3 -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())") \
        /opt/opencv-${OPENCV_VERSION} \
    && make -j$(nproc) \
    && make install \
    && rm -rf /opt/build/* \
    && rm -rf /opt/opencv-${OPENCV_VERSION} \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get -qq autoremove \
    && apt-get -qq clean
CMD ["/bin/bash"]
