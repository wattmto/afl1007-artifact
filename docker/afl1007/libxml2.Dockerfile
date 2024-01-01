ARG TAG=main
ARG CVE=2017-5969
ARG PREFIX
ARG SAN
FROM ${PREFIX}afl1007-artifact/afl1007:${TAG} AS distance-builder

ARG CVE

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ADD https://download.gnome.org/sources/libxml2/2.9/libxml2-2.9.4.tar.xz /

RUN tar -xf libxml2-2.9.4.tar.xz && \
    mv /libxml2-2.9.4 /libxml2 && \
    rm libxml2-2.9.4.tar.xz

RUN mkdir /inst-assist

COPY target/libxml2/$CVE /inst-assist/BBtargets.txt

WORKDIR /libxml2

RUN LLVM_CONFIG=$(which llvm-config) && \
    AR=$(which llvm-ar) && \
    RANLIB=$(which llvm-ranlib) && \
    AS=$(which llvm-as) && \
    export CC=/aflgo/instrument/aflgo-clang && \
    export CXX=/aflgo/instrument/aflgo-clang++ && \
    export CFLAGS="-targets=/inst-assist/BBtargets.txt -outdir=/inst-assist -flto -fuse-ld=gold -Wl,-plugin-opt=save-temps" && \
    export CXXFLAGS="-targets=/inst-assist/BBtargets.txt -outdir=/inst-assist -flto -fuse-ld=gold -Wl,-plugin-opt=save-temps" && \
    export AR && \
    export AS && \
    export LLVM_CONFIG && \
    export RANLIB && \
    LDFLAGS="-lpthread" \
    ./autogen.sh && \
    ./configure --disable-shared --without-debug --without-ftp --without-http --without-legacy --without-modules --without-python && \
    make clean && \
    make -j "$(nproc)" xmllint

RUN /libxml2/xmllint --valid --recover /libxml2/test/dtd3

RUN grep -v "^$" /inst-assist/BBnames.txt | rev | cut -d: -f2- | rev | sort | uniq > /inst-assist/BBnames2.txt && \
    mv /inst-assist/BBnames2.txt /inst-assist/BBnames.txt && \
    grep -Ev "^[^,]*$|^([^,]*,){2,}[^,]*$" /inst-assist/BBcalls.txt | sort | uniq > /inst-assist/BBcalls2.txt && \
    mv /inst-assist/BBcalls2.txt /inst-assist/BBcalls.txt

RUN /aflgo/distance/gen_distance_fast.py /libxml2 /inst-assist xmllint

FROM distance-builder as builder

WORKDIR /libxml2

RUN export CC=/aflgo/instrument/aflgo-clang && \
    export CXX=/aflgo/instrument/aflgo-clang++ && \
    export CFLAGS="-distance=/inst-assist/distance.cfg.txt -fsanitize=address -fno-omit-frame-pointer" && \
    export CXXFLAGS="-distance=/inst-assist/distance.cfg.txt -fsanitize=address -fno-omit-frame-pointer" && \
    make clean && \
    ./configure --disable-shared --without-debug --without-ftp --without-http --without-legacy --without-modules --without-python && \
    make -j "$(nproc)" xmllint

FROM distance-builder as builder-nosan

WORKDIR /libxml2

RUN export CC=/aflgo/instrument/aflgo-clang && \
    export CXX=/aflgo/instrument/aflgo-clang++ && \
    export CFLAGS="-distance=/inst-assist/distance.cfg.txt" && \
    export CXXFLAGS="-distance=/inst-assist/distance.cfg.txt" && \
    make clean && \
    ./configure --disable-shared --without-debug --without-ftp --without-http --without-legacy --without-modules --without-python && \
    make -j "$(nproc)" xmllint

FROM builder${SAN} as builder

WORKDIR /

FROM builder as entrypoint-2017-5969

ENTRYPOINT ["/bin/entrypoint", "2017-5969"]
CMD ["45m", "1h", "10"]

FROM builder as entrypoint-2017-9047

ENTRYPOINT ["/bin/entrypoint", "2017-9047"]
CMD ["45m", "1h", "10"]

FROM builder as entrypoint-2017-9048

ENTRYPOINT ["/bin/entrypoint", "2017-9048"]
CMD ["45m", "1h", "10"]

# hadolint ignore=DL3006
FROM entrypoint-${CVE}
