#!/bin/bash
set -e
sudo podman build -t ghcr.io/lawik974/fedora-bootc-server:main . --cap-add=all --security-opt=label=type:container_runtime_t --device /dev/fuse

sudo podman run -it --rm --security-opt label=type:unconfined_t \
    --privileged \
    -v $(pwd):/output \
    -v /var/lib/containers/storage:/var/lib/containers/storage \
    quay.io/centos-bootc/bootc-image-builder:latest \
        --output "/output" \
        --type qcow2 \
        --rootfs xfs \
        "ghcr.io/lawik974/fedora-bootc-server:main"
