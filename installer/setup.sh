#!/bin/bash
set -xeuo pipefail

dnf install --setopt=install_weak_deps=False --nodocs -y \
    python3-newt \
    anaconda \
    anaconda-install-env-deps \
    anaconda-dracut \
    squashfs-tools \
    net-tools \
    nfs-utils \
    grub2-efi-x64-cdboot \
    dracut-config-generic \
    dracut-network \
    python3-mako \
    biosdevname \
    prefixdevname \
    lorax-templates-*

dnf reinstall -y shim-x64

# Remove leftover build artifacts from installing packages in the final built image.
dnf clean all
rm /var/{log,cache,lib}/* -rf
rm -rf /run/* /tmp/* /var/tmp/* || true
