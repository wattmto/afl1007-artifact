FROM afl1007:latest

RUN python3 -m pip install networkx \
    pydot \
    pydotplus

RUN git clone https://gitlab.gnome.org/GNOME/libxml2 && \
    cd /libxml2 && \
    git checkout ef709ce2

RUN mkdir /inst-assist

RUN wget -O /inst-assist/showlinenum.awk https://raw.githubusercontent.com/jay/showlinenum/develop/showlinenum.awk && \
    chmod +x /inst-assist/showlinenum.awk

RUN cd /libxml2 && \
    git diff -U0 HEAD^ HEAD > /inst-assist/commit.diff && \
    cat /inst-assist/commit.diff | \
        /inst-assist/showlinenum.awk show_header=0 path=1 | \
        grep -e "\.[ch]:[0-9]*:+" -e "\.cpp:[0-9]*:+" -e "\.cc:[0-9]*:+" | \
        cut -d+ -f1 | rev | cut -c2- | rev > /inst-assist/BBtargets.txt

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
    ./configure --disable-shared && \
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
    ./configure --disable-shared && \
    make xmllint

CMD ["/libxml2/xmllint", "--valid --recover @@", "45m", "1h"]
