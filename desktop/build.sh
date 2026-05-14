#!/bin/bash
set -e
sudo podman build -t localhost/fedora-bootc-gnome:43-custom . --cap-add=all --security-opt=label=type:container_runtime_t --device /dev/fuse

# sudo podman run -it --rm --security-opt label=type:unconfined_t \
#     --privileged \
#     -v $(pwd):/output \
#     -v $(pwd)/installer-config.toml:/config.toml \
#     -v /var/lib/containers/storage:/var/lib/containers/storage \
#     quay.io/centos-bootc/bootc-image-builder:latest \
#         --output "/output" \
#         --type qcow2 \
#         --rootfs xfs \
#         --config /config.toml \
#         "localhost/fedora-bootc-gnome:43-custom"

sudo podman run -it --rm --security-opt label=type:unconfined_t \
    --privileged \
    -v $(pwd):/output \
    -v $(pwd)/installer-config.toml:/config.toml \
    -v /var/lib/containers/storage:/var/lib/containers/storage \
    quay.io/centos-bootc/bootc-image-builder:latest \
        --output "/output" \
        --type bootc-installer \
        --rootfs xfs \
        --config /config.toml \
        --installer-payload-ref "localhost/fedora-bootc-gnome:43-custom" \
        "ghcr.io/lawik974/fedora-bootc-installer:main"
