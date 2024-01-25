ARG TAG=main
ARG CVE=2016-9827
ARG PREFIX

FROM ${PREFIX}afl1007-artifact/aflgo/${CVE}:${TAG} AS builder

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    gdb \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /libming

RUN CXX=$(which clang++) && \
    CC=$(which clang) && \
    LLVM_CONFIG=$(which llvm-config) && \
    export CXX && \
    export CC && \
    export LLVM_CONFIG && \
    export CFLAGS="-fcommon -g -fsanitize=address" && \
    export CXXFLAGS="-fcommon -g -fsanitize=address" && \
    make clean && \
    ./autogen.sh && \
    ./configure --disable-shared --disable-freetype && \
    make -j "$(nproc)"

WORKDIR /

COPY docker/triage/entrypoint /bin/entrypoint
COPY docker/triage/triage.gdb /triage.gdb

RUN chmod +x /bin/entrypoint

FROM builder as entrypoint-2016-9827

ENTRYPOINT ["/bin/entrypoint", "2016-9827"]

FROM builder as entrypoint-2016-9829

ENTRYPOINT ["/bin/entrypoint", "2016-9829"]

FROM builder as entrypoint-2016-9831

ENTRYPOINT ["/bin/entrypoint", "2016-9831"]

FROM builder as entrypoint-2017-9988

ENTRYPOINT ["/bin/entrypoint", "2017-9988"]

# hadolint ignore=DL3006
FROM entrypoint-${CVE}
