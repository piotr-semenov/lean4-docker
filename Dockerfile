FROM alpine:latest AS elan_builder
LABEL stage=intermediate

COPY ./elan.apkfile ./dockerfile-commons/reduce_alpine.sh /tmp/

SHELL ["/bin/ash", "-o", "pipefail", "-c"]
RUN apk update && \
    apk --no-cache add $(cat /tmp/elan.apkfile)

WORKDIR /workdir/
RUN \
    # Clone elan from HEAD.
    git clone --depth 1 https://github.com/leanprover/elan.git $(pwd) && \
    \
    # Build & install.
    cargo build --release && \
    cp /workdir/target/release/elan-init /usr/bin/elan && \
    \
    # Reduce to the minimal size distribution.
    sh /tmp/reduce_alpine.sh -v /target /usr/bin/elan && \
    \
    # Clean out.
    apk del $(sed -e "s/@.*$//" /tmp/elan.apkfile) && \
    rm -rf /tmp/*


FROM alpine:latest AS lean4_builder
LABEL stage=intermediate

COPY ./lean4.apkfile ./dockerfile-commons/reduce_alpine.sh /tmp/

RUN apk update && \
    apk --no-cache add $(cat /tmp/lean4.apkfile)

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
WORKDIR /workdir/
RUN \
    # Clone lean4 from HEAD.
    git clone --depth 1 https://github.com/leanprover/lean4 $(pwd) && \
    \
    # Build & install.
    export CC=/usr/bin/clang CXX=/usr/bin/clang++ && \
    ln -s /usr/bin/clang++ /usr/bin/c++ && \
    cmake --preset release && \
    make -C build/release -j$(nproc || sysctl -n hw.logicalcpu) && \
    \
    # Reduce to the minimal size distribution.
    cd ./build/release/stage1/ && \
    cp ./bin/* /usr/bin/ && \
    cp ./lib/lean/lib{Lake_,lean}shared.so /usr/lib/ && \
    sh /tmp/reduce_alpine.sh -v /target $(find ./bin -type f -exec echo /usr/\{\} \;) \
                                        /usr/lib/lib{Lake_,lean}shared.so && \
    \
    # Clean out.
    apk del $(sed -e "s/@.*$//" /tmp/lean4.apkfile) && \
    rm -rf /tmp/*


FROM scratch

ARG vcsref
LABEL \
    stage=production \
    org.label-schema.name="tiny-lean4-toolchain" \
    org.label-schema.description="Minified Lean4 toolchain distribution." \
    org.label-schema.url="https://hub.docker.com/r/semenovp/tiny-lean4-toolchain/" \
    org.label-schema.vcs-ref="$vcsref" \
    org.label-schema.vcs-url="https://github.com/piotr-semenov/lean4-docker.git" \
    maintainer="Piotr Semenov <piotr.k.semenov@gmail.com>"

COPY --from=elan_builder /target /
COPY --from=lean4_builder /target /

ENTRYPOINT ["lean"]
