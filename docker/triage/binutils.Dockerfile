ARG TAG=main
ARG CVE=2017-8392
ARG FUZZER=aflgo
ARG PREFIX

FROM ${PREFIX}afl1007-artifact/${FUZZER}/${CVE}:${TAG} AS builder

WORKDIR /binutils

RUN CXX=$(which clang++) && \
    CC=$(which clang) && \
    LLVM_CONFIG=$(which llvm-config) && \
    export CXX && \
    export CC && \
    export LLVM_CONFIG && \
    export CFLAGS="-g" && \
    export CXXFLAGS="-g" && \
    make distclean && \
    ./configure --disable-shared --disable-gdb --disable-libdecnumber --disable-readline --disable-sim --disable-ld && \
    make -j "$(nproc)"

COPY docker/triage/entrypoint /bin/entrypoint

RUN chmod +x /bin/entrypoint

ENTRYPOINT ["/bin/entrypoint"]
