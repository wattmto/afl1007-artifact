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
COPY docker/triage/triage.gdb /triage.gdb

ENV ASAN_OPTIONS="detect_leaks=0:abort_on_error=1:allow_user_segv_handler=0:handle_abort=1:symbolize=0"

RUN chmod +x /bin/entrypoint

FROM builder AS entrypoint-2017-8392

ENTRYPOINT ["/bin/entrypoint", "2017-8392"]

FROM builder AS entrypoint-2017-8393

ENTRYPOINT ["/bin/entrypoint", "2017-8393"]

FROM builder AS entrypoint-2017-8394

ENTRYPOINT ["/bin/entrypoint", "2017-8394"]

FROM builder AS entrypoint-2017-8395

ENTRYPOINT ["/bin/entrypoint", "2017-8395"]

FROM builder AS entrypoint-2017-8396

ENTRYPOINT ["/bin/entrypoint", "2017-8396"]

FROM builder AS entrypoint-2017-8397

ENTRYPOINT ["/bin/entrypoint", "2017-8397"]

FROM builder AS entrypoint-2017-8398

ENTRYPOINT ["/bin/entrypoint", "2017-8398"]

# hadolint ignore=DL3006
FROM entrypoint-${CVE}
