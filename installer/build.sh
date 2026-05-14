#!/bin/bash
set -e
sudo podman build -t ghcr.io/lawik974/fedora-bootc-installer:main . --cap-add=all --security-opt=label=type:container_runtime_t --device /dev/fuse
