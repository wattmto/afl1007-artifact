ARG TAG=main
ARG CVE=2017-5969
ARG PREFIX

FROM ${PREFIX}afl1007-artifact/aflgo/${CVE}:${TAG} AS builder

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    gdb \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /libxml2

RUN CXX=$(which clang++) && \
    CC=$(which clang) && \
    LLVM_CONFIG=$(which llvm-config) && \
    export CXX && \
    export CC && \
    export LLVM_CONFIG && \
    export CFLAGS="-g -fsanitize=address" && \
    export CXXFLAGS="-g -fsanitize=address" && \
    LDFLAGS="-lpthread" \
    ./autogen.sh && \
    ./configure --disable-shared --without-ftp --without-http --without-legacy --without-modules --without-python && \
    make clean && \
    make -j "$(nproc)" xmllint

WORKDIR /

COPY docker/triage/entrypoint /bin/entrypoint
COPY docker/triage/triage.gdb /triage.gdb

RUN chmod +x /bin/entrypoint

FROM builder as entrypoint-2017-5969

ENTRYPOINT ["/bin/entrypoint", "2017-5969"]

FROM builder as entrypoint-2017-9047

ENTRYPOINT ["/bin/entrypoint", "2017-9047"]

FROM builder as entrypoint-2017-9048

ENTRYPOINT ["/bin/entrypoint", "2017-9048"]

# hadolint ignore=DL3006
FROM entrypoint-${CVE}
