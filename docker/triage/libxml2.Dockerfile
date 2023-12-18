ARG TAG=main
ARG CVE=2017-5969
ARG FUZZER=aflgo
ARG PREFIX

FROM ${PREFIX}afl1007-artifact/${FUZZER}/${CVE}:${TAG} AS builder

WORKDIR /libxml2

RUN CXX=$(which clang++) && \
    CC=$(which clang) && \
    LLVM_CONFIG=$(which llvm-config) && \
    export CXX && \
    export CC && \
    export LLVM_CONFIG && \
    export CFLAGS="-g" && \
    export CXXFLAGS="-g" && \
    LDFLAGS="-lpthread" \
    ./autogen.sh && \
    ./configure --disable-shared --without-debug --without-ftp --without-http --without-legacy --without-modules --without-python && \
    make clean && \
    make -j "$(nproc)" xmllint

WORKDIR /

COPY docker/triage/entrypoint /bin/entrypoint

RUN chmod +x /bin/entrypoint

ENTRYPOINT ["/bin/entrypoint"]
