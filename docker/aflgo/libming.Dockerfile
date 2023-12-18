ARG TAG=main
ARG CVE=2016-9827
ARG PREFIX

FROM alpine:3 AS libming-4-7-downloader

# hadolint ignore=DL3018
RUN apk add --no-cache git && \
    git clone --branch ming-0_4_7 --depth 1 https://github.com/libming/libming.git

FROM libming-4-7-downloader AS downloader-2016-9827

FROM libming-4-7-downloader AS downloader-2016-9829

# hadolint ignore=DL3006
FROM downloader-${CVE} AS downloader

FROM ${PREFIX}afl1007-artifact/aflgo:${TAG} AS builder

ARG CVE

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY --from=downloader /libming /libming

RUN mkdir /inst-assist /in

COPY target/libming/$CVE /inst-assist/BBtargets.txt

ADD http://condor.depaul.edu/sjost/hci430/flash-examples/swf/bumble-bee1.swf /in/

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    bison \
    flex \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /libming

RUN LLVM_CONFIG=$(which llvm-config) && \
    AR=$(which llvm-ar) && \
    RANLIB=$(which llvm-ranlib) && \
    AS=$(which llvm-as) && \
    export CC=/aflgo/instrument/aflgo-clang && \
    export CXX=/aflgo/instrument/aflgo-clang++ && \
    export CFLAGS="-fcommon -targets=/inst-assist/BBtargets.txt -outdir=/inst-assist -flto -fuse-ld=gold -Wl,-plugin-opt=save-temps" && \
    export CXXFLAGS="-fcommon -targets=/inst-assist/BBtargets.txt -outdir=/inst-assist -flto -fuse-ld=gold -Wl,-plugin-opt=save-temps" && \
    export AR && \
    export AS && \
    export LLVM_CONFIG && \
    export RANLIB && \
    ./autogen.sh && \
    ./configure --disable-shared --disable-freetype && \
    make clean && \
    make -j "$(nproc)"

RUN /libming/util/swftophp /in/bumble-bee1.swf

RUN grep -v "^$" /inst-assist/BBnames.txt | rev | cut -d: -f2- | rev | sort | uniq > /inst-assist/BBnames2.txt && \
    mv /inst-assist/BBnames2.txt /inst-assist/BBnames.txt && \
    grep -Ev "^[^,]*$|^([^,]*,){2,}[^,]*$" /inst-assist/BBcalls.txt | sort | uniq > /inst-assist/BBcalls2.txt && \
    mv /inst-assist/BBcalls2.txt /inst-assist/BBcalls.txt

RUN /aflgo/distance/gen_distance_fast.py /libming/util /inst-assist swftophp

RUN export CC=/aflgo/instrument/aflgo-clang && \
    export CXX=/aflgo/instrument/aflgo-clang++ && \
    export CFLAGS="-fcommon -distance=/inst-assist/distance.cfg.txt -fsanitize=address -fno-omit-frame-pointer" && \
    export CXXFLAGS="-fcommon -distance=/inst-assist/distance.cfg.txt -fsanitize=address -fno-omit-frame-pointer" && \
    make clean && \
    ./configure --disable-shared --disable-freetype && \
    make -j "$(nproc)"

WORKDIR /

FROM builder as entrypoint-2016-9827

ENTRYPOINT ["/bin/entrypoint", "2016-9827"]
CMD ["45m", "1h", "10"]

FROM builder as entrypoint-2016-9829

ENTRYPOINT ["/bin/entrypoint", "2016-9829"]
CMD ["45m", "1h", "10"]
