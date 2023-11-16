FROM afl1007:latest

ARG CVE=2017-5969

ADD https://github.com/GNOME/libxml2/archive/refs/tags/v2.9.4.zip /

RUN unzip v2.9.4.zip && \
    mv /libxml2-2.9.4 /libxml2 && \
    rm v2.9.4.zip

RUN mkdir /inst-assist

COPY target/libxml2/$CVE /inst-assist/BBtargets.txt

RUN export CC=/aflgo/instrument/aflgo-clang && \
    export CXX=/aflgo/instrument/aflgo-clang++ && \
    export CFLAGS="-targets=/inst-assist/BBtargets.txt -outdir=/inst-assist -flto -fuse-ld=gold -Wl,-plugin-opt=save-temps" && \
    export CXXFLAGS="-targets=/inst-assist/BBtargets.txt -outdir=/inst-assist -flto -fuse-ld=gold -Wl,-plugin-opt=save-temps" && \
    export LLVM_CONFIG=/usr/bin/llvm-config-11 && \
    export AR=/usr/bin/llvm-ar-11 && \
    export RANLIB=/usr/bin/llvm-ranlib-11 && \
    export AS=/usr/bin/llvm-as-11 && \
    LDFLAGS="-lpthread" \
    cd /libxml2 && \
    ./autogen.sh && \
    ./configure --disable-shared --without-debug --without-ftp --without-http --without-legacy --without-modules --without-python && \
    make clean && \
    make xmllint

RUN /libxml2/xmllint --valid --recover /libxml2/test/dtd3

RUN cat /inst-assist/BBnames.txt | grep -v "^$"| rev | cut -d: -f2- | rev | sort | uniq > /inst-assist/BBnames2.txt && \
    mv /inst-assist/BBnames2.txt /inst-assist/BBnames.txt && \
    cat /inst-assist/BBcalls.txt | grep -Ev "^[^,]*$|^([^,]*,){2,}[^,]*$"| sort | uniq > /inst-assist/BBcalls2.txt && \
    mv /inst-assist/BBcalls2.txt /inst-assist/BBcalls.txt

RUN /aflgo/distance/gen_distance_fast.py /libxml2 /inst-assist xmllint

RUN export CC=/aflgo/instrument/aflgo-clang && \
    export CXX=/aflgo/instrument/aflgo-clang++ && \
    export CFLAGS="-distance=/inst-assist/distance.cfg.txt" && \
    export CXXFLAGS="-distance=/inst-assist/distance.cfg.txt" && \
    cd /libxml2 && \
    make clean && \
    ./configure --disable-shared --without-debug --without-ftp --without-http --without-legacy --without-modules --without-python && \
    make xmllint

CMD ["/libxml2/xmllint", "--valid --recover @@", "45m", "1h"]
