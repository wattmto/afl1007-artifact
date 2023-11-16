FROM ubuntu:focal

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    cmake \
    git \
    gnupg \
    jq \
    lsb-release \
    make \
    sudo \
    unzip \
    wget \
    zsh \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key | tee /etc/apt/keyrings/llvm-snapshot.asc > /dev/null && \
    echo "deb [signed-by=/etc/apt/keyrings/llvm-snapshot.asc] http://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs)-11 main" | tee /etc/apt/sources.list.d/llvm.list > /dev/null && \
    apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    clang-11 \
    clangd-11 \
    clang-format-11 \
    clang-tidy-11 \
    lld-11 \
    llvm-11 \
    llvm-11-dev \
    && rm -rf /var/lib/apt/lists/*


RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
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
    && rm -rf /var/lib/apt/lists/* && \
    python3 -m pip install --no-cache-dir networkx \
    pydot \
    pydotplus

RUN git clone https://github.com/aflgo/aflgo

WORKDIR /aflgo

RUN git reset --hard fa125da5d70621daf7141c6279877c97708c8c1f && \
    git clean -f -d

RUN ln -s /usr/bin/clang++-11 /usr/bin/clang++ && \
    ln -s /usr/bin/clang-11 /usr/bin/clang && \
    ln -s /usr/bin/llvm-config-11 /usr/bin/llvm-config && \
    ln -s /usr/bin/opt-11 /usr/bin/opt

WORKDIR /aflgo/afl-2.57b
RUN CXX=$(which clang++) && \
    CC=$(which clang) && \
    LLVM_CONFIG=$(which llvm-config) && \
    export CXX && \
    export CC && \
    export LLVM_CONFIG && \
    make clean all

WORKDIR /aflgo/instrument
RUN CXX=$(which clang++) && \
    CC=$(which clang) && \
    LLVM_CONFIG=$(which llvm-config-11) && \
    export CXX && \
    export CC && \
    export LLVM_CONFIG && \
    make clean all

WORKDIR /aflgo/distance/distance_calculator
RUN CXX=$(which clang++) && \
    CC=$(which clang) && \
    LLVM_CONFIG=$(which llvm-config-11) && \
    export CXX && \
    export CC && \
    export LLVM_CONFIG && \
    cmake ./ && \
    cmake --build ./

WORKDIR /

COPY entrypoint /bin/entrypoint
COPY postprocess /bin/postprocess

RUN chmod +x /bin/entrypoint && \
    chmod +x /bin/postprocess

ENTRYPOINT ["/bin/entrypoint"]
