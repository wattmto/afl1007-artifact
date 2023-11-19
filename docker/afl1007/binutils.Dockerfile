ARG TAG=main
ARG CVE=2017-8392

FROM alpine:3 AS input-downloader

ADD https://github.com/JonathanSalwan/binary-samples/archive/refs/heads/master.zip /

RUN unzip master.zip

FROM ghcr.io/wattmto/afl1007-artifact/afl1007:${TAG} AS preinst-builder

ARG CVE

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ADD http://ftp.gnu.org/gnu/binutils/binutils-2.28.tar.gz /

RUN tar xf binutils-2.28.tar.gz && \
    mv /binutils-2.28 /binutils && \
    rm binutils-2.28.tar.gz

RUN mkdir /in /inst-assist

COPY target/binutils/$CVE /inst-assist/BBtargets.txt

COPY --from=input-downloader /master/elf-FreeBSD-x86_64-echo \
    /master/elf-Haiku-GCC2-ls \
    /master/elf-Haiku-GCC7-WebPositive \
    /master/elf-Linux-lib-x64.so \
    /master/elf-Linux-lib-x86.so \
    /master/elf-Linux-x64-bash \
    /master/elf-Linux-x86-bash \
    /master/elf-NetBSD-x86_64-echo \
    /master/elf-OpenBSD-x86_64-sh \
    /master/elf-solaris-x86-ls \
    /master/pe-Windows-x64-cmd \
    /master/pe-Windows-x86-cmd \
    /master/pe-cygwin-ls.exe \
    /master/pe-mingw32-strip.exe \
    /in/

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
    ./configure --disable-shared --disable-gdb --disable-libdecnumber --disable-readline --disable-sim --disable-ld && \
    make clean && \
    make -j "$(nproc)"

FROM preinst-builder as 2017-8392-preinst-runner

RUN /binutils/objdump -SD /in/elf-Linux-x64-bas

FROM ${CVE}-preinst-runner as builder

RUN grep -v "^$" /inst-assist/BBnames.txt | rev | cut -d: -f2- | rev | sort | uniq > /inst-assist/BBnames2.txt && \
    mv /inst-assist/BBnames2.txt /inst-assist/BBnames.txt && \
    grep -Ev "^[^,]*$|^([^,]*,){2,}[^,]*$" /inst-assist/BBcalls.txt | sort | uniq > /inst-assist/BBcalls2.txt && \
    mv /inst-assist/BBcalls2.txt /inst-assist/BBcalls.txt

RUN /aflgo/distance/gen_distance_fast.py /libxml2 /inst-assist xmllint

RUN export CC=/aflgo/instrument/aflgo-clang && \
    export CXX=/aflgo/instrument/aflgo-clang++ && \
    export CFLAGS="-distance=/inst-assist/distance.cfg.txt" && \
    export CXXFLAGS="-distance=/inst-assist/distance.cfg.txt" && \
    make clean && \
    ./configure --disable-shared --without-debug --without-ftp --without-http --without-legacy --without-modules --without-python && \
    make -j "$(nproc)" xmllint

WORKDIR /

FROM builder as entrypoint-2017-5969

ENTRYPOINT ["/bin/entrypoint", "/libxml2/xmllint", "--recover @@"]
CMD ["45m", "1h"]

FROM builder as entrypoint-2017-9047

ENTRYPOINT ["/bin/entrypoint", "/libxml2/xmllint", "--valid @@"]
CMD ["45m", "1h"]

FROM builder as entrypoint-2017-9048

ENTRYPOINT ["/bin/entrypoint", "/libxml2/xmllint", "--valid @@"]
CMD ["45m", "1h"]

# hadolint ignore=DL3006
FROM entrypoint-${CVE}
