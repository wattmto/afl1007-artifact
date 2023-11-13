FROM ubuntu:focal

ENV DEBIAN_FRONTEND=noninteractive

RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update && apt-get install -y \
    build-essential \
    curl \
    cmake \
    git \
    gnupg \
    jq \
    lsb-release \
    make \
    sudo \
    wget \
    zsh \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key | tee /etc/apt/keyrings/llvm-snapshot.asc > /dev/null \
    && echo "deb [signed-by=/etc/apt/keyrings/llvm-snapshot.asc] http://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs)-11 main" | tee /etc/apt/sources.list.d/llvm.list > /dev/null \
    && DEBIAN_FRONTEND=noninteractive \
    apt-get update && apt-get install -y \
    clang-11 \
    clangd-11 \
    clang-format-11 \
    clang-tidy-11 \
    lld-11 \
    && rm -rf /var/lib/apt/lists/*

RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update && apt-get install -y \
    graphviz \
    python3 \
    python3-dev \
    python3-pip \
    pkg-config \
    autoconf \
    automake \
    libtool-bin \
    gawk \
    libboost-all-dev \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install networkx \
    pydot \
    pydotplus

RUN git clone https://github.com/aflgo/aflgo && \
    cd /aflgo && \
    git reset --hard fa125da5d70621daf7141c6279877c97708c8c1f && \
    git clean -f -d

RUN ln -s /usr/bin/clang++-11 /usr/bin/clang++ && \
    ln -s /usr/bin/clang-11 /usr/bin/clang && \
    ln -s /usr/bin/llvm-config-11 /usr/bin/llvm-config && \
    ln -s /usr/bin/opt-11 /usr/bin/opt

RUN cd /aflgo/afl-2.57b && \
    CXX=`which clang++` \
    CC=`which clang` \
    LLVM_CONFIG=`which llvm-config` \
    bash -c 'make clean all'

RUN cd /aflgo/instrument && \
    CXX=`which clang++` \
    CC=`which clang` \
    LLVM_CONFIG=`which llvm-config-11` \
    bash -c 'make clean all'

RUN cd /aflgo/distance/distance_calculator && \
    CXX=`which clang++` \
    CC=`which clang` \
    LLVM_CONFIG=`which llvm-config-11` \
    bash -c 'cmake ./ && cmake --build ./'

COPY entrypoint /bin/entrypoint
COPY postprocess /bin/postprocess

RUN chmod +x /bin/entrypoint && \
    chmod +x /bin/postprocess

ENTRYPOINT ["/bin/entrypoint"]
