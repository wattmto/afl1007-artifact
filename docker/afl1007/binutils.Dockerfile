ARG TAG=main
ARG CVE=2017-8392
ARG PREFIX

FROM alpine:3 AS input-downloader

ADD https://github.com/JonathanSalwan/binary-samples/archive/refs/heads/master.zip /

RUN unzip master.zip

FROM alpine:3 AS binutils-2-28-downloader

ADD http://ftp.gnu.org/gnu/binutils/binutils-2.28.tar.gz /

RUN tar xf binutils-2.28.tar.gz && \
    mv /binutils-2.28 /binutils && \
    rm binutils-2.28.tar.gz

FROM binutils-2-28-downloader AS downloader-2017-8392

FROM binutils-2-28-downloader AS downloader-2017-8396

FROM binutils-2-28-downloader AS downloader-2017-8397

FROM binutils-2-28-downloader AS downloader-2017-8398

FROM downloader-${CVE} AS downloader

FROM ${PREFIX}afl1007-artifact/afl1007:${TAG} AS preinst-builder

ARG CVE

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY --from=downloader /binutils /binutils

RUN mkdir /inst-assist

COPY target/binutils/$CVE /inst-assist/BBtargets.txt

COPY --from=input-downloader /binary-samples-master/elf-FreeBSD-x86_64-echo \
    /binary-samples-master/elf-Haiku-GCC2-ls \
    /binary-samples-master/elf-Haiku-GCC7-WebPositive \
    /binary-samples-master/elf-Linux-lib-x64.so \
    /binary-samples-master/elf-Linux-lib-x86.so \
    /binary-samples-master/elf-Linux-x64-bash \
    /binary-samples-master/elf-Linux-x86-bash \
    /binary-samples-master/elf-NetBSD-x86_64-echo \
    /binary-samples-master/elf-OpenBSD-x86_64-sh \
    /binary-samples-master/elf-solaris-x86-ls \
    /binary-samples-master/pe-Windows-x64-cmd \
    /binary-samples-master/pe-Windows-x86-cmd \
    /binary-samples-master/pe-cygwin-ls.exe \
    /binary-samples-master/pe-mingw32-strip.exe \
    /in/

WORKDIR /binutils

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
    make -j "$(nproc)"

FROM preinst-builder AS objdump-preinst-runner

RUN /binutils/binutils/objdump -SD /in/elf-Linux-x64-bash

RUN grep -v "^$" /inst-assist/BBnames.txt | rev | cut -d: -f2- | rev | sort | uniq > /inst-assist/BBnames2.txt && \
    mv /inst-assist/BBnames2.txt /inst-assist/BBnames.txt && \
    grep -Ev "^[^,]*$|^([^,]*,){2,}[^,]*$" /inst-assist/BBcalls.txt | sort | uniq > /inst-assist/BBcalls2.txt && \
    mv /inst-assist/BBcalls2.txt /inst-assist/BBcalls.txt

RUN /aflgo/distance/gen_distance_fast.py /binutils/binutils /inst-assist objdump

FROM objdump-preinst-runner AS preinst-runner-2017-8392

FROM objdump-preinst-runner AS preinst-runner-2017-8396

FROM objdump-preinst-runner AS preinst-runner-2017-8397

FROM objdump-preinst-runner AS preinst-runner-2017-8398

FROM preinst-runner-${CVE} AS builder

RUN export CC=/aflgo/instrument/aflgo-clang && \
    export CXX=/aflgo/instrument/aflgo-clang++ && \
    export CFLAGS="-distance=/inst-assist/distance.cfg.txt -DFORTIFY_SOURCE=2 -fstack-protector-all -fsanitize=undefined,address -fno-omit-frame-pointer -g -Wno-error" && \
    export CXXFLAGS="-distance=/inst-assist/distance.cfg.txt -DFORTIFY_SOURCE=2 -fstack-protector-all -fsanitize=undefined,address -fno-omit-frame-pointer -g -Wno-error" && \
    make distclean && \
    ./configure --disable-shared --disable-gdb --disable-libdecnumber --disable-readline --disable-sim --disable-ld && \
    # ignore LeakSanitizer error
    make -j "$(nproc)" || true && \
    make -j "$(nproc)"

WORKDIR /

FROM builder AS entrypoint-2017-8392

ENTRYPOINT ["/bin/entrypoint", "/binutils/binutils/objdump", "-SD @@"]
CMD ["45m", "1h", "1000"]

FROM builder AS entrypoint-2017-8396

ENTRYPOINT ["/bin/entrypoint", "/binutils/binutils/objdump", "-W @@"]
CMD ["45m", "1h", "1000"]

FROM builder AS entrypoint-2017-8397

ENTRYPOINT ["/bin/entrypoint", "/binutils/binutils/objdump", "-W @@"]
CMD ["45m", "1h", "1000"]

FROM builder AS entrypoint-2017-8398

ENTRYPOINT ["/bin/entrypoint", "/binutils/binutils/objdump", "-W @@"]
CMD ["45m", "1h", "1000"]

# hadolint ignore=DL3006
FROM entrypoint-${CVE}
