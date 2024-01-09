ARG TAG=main
ARG CVE=2017-8392
ARG PREFIX

FROM ${PREFIX}afl1007-artifact/aflgo/${CVE}:${TAG} AS builder

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    gdb \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /binutils

RUN CXX=$(which clang++) && \
    CC=$(which clang) && \
    LLVM_CONFIG=$(which llvm-config) && \
    export CXX && \
    export CC && \
    export LLVM_CONFIG && \
    export CFLAGS="-g -fsanitize=address" && \
    export CXXFLAGS="-g -fsanitize=address" && \
    make distclean && \
    ./configure --disable-shared --disable-libdecnumber --disable-readline --disable-sim --disable-ld && \
    # ignore LeakSanitizer error
    make -j "$(nproc)" || true && \
    make -j "$(nproc)"

WORKDIR /

COPY docker/triage/entrypoint /bin/entrypoint

RUN chmod +x /bin/entrypoint

FROM builder AS entrypoint-2017-8392

ENTRYPOINT ["/bin/entrypoint", "/binutils/binutils/objdump -SD @@"]

FROM builder AS entrypoint-2017-8393

ENTRYPOINT ["/bin/entrypoint", "/binutils/binutils/objcopy --compress-debug-sections @@ out"]

FROM builder AS entrypoint-2017-8394

ENTRYPOINT ["/bin/entrypoint", "/binutils/binutils/objcopy -Gs @@ out"]

FROM builder AS entrypoint-2017-8395

ENTRYPOINT ["/bin/entrypoint", "/binutils/binutils/objcopy --compress-debug-sections @@ out"]

FROM builder AS entrypoint-2017-8396

ENTRYPOINT ["/bin/entrypoint", "/binutils/binutils/objdump -W @@"]

FROM builder AS entrypoint-2017-8397

ENTRYPOINT ["/bin/entrypoint", "/binutils/binutils/objdump -W @@"]

FROM builder AS entrypoint-2017-8398

ENTRYPOINT ["/bin/entrypoint", "/binutils/binutils/objdump -W @@"]

# hadolint ignore=DL3006
FROM entrypoint-${CVE}
