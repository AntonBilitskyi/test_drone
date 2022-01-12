FROM arm64v8/ubuntu:bionic

WORKDIR /home

RUN apt-get update -y
RUN apt purge --auto-remove cmake -y
RUN apt install -y libprotobuf-dev protobuf-compiler wget
RUN wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | sudo tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null
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
RUN cmake --build build/default --target install -- -j 4
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

CMD ["/bin/bash"]
