ARG VERSION=main

FROM ghcr.io/lawik974/fedora-bootc-base:main as builder

LABEL maintainer="Loïc Dubard"
LABEL org.opencontainers.image.authors="Loïc Dubard"
LABEL org.opencontainers.image.title="Fedora Bootc Installer"
LABEL org.opencontainers.image.description="A Fedora-based Installer image built with bootc."
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.source="https://github.com/lawik974/fedora-bootc"

ARG VERSION

COPY --chmod=755 ./custom_part.py /usr/bin/custom_part.py
RUN sed -i "s/{{ VERSION }}/$VERSION/" /usr/bin/custom_part.py
COPY --chmod=755 ./setup.sh /tmp/setup.sh
RUN /tmp/setup.sh

# For Fedora 43 or rawhide this workaround gets EFI files in the right
# place:
RUN mkdir -p /boot/efi && cp -ra /usr/lib/efi/*/*/EFI/ /boot/efi

# lorax wants to create a symlink in /mnt which points to /var/mnt
# on bootc but /var/mnt does not exist on some images.
#
# If https://gitlab.com/fedora/bootc/base-images/-/merge_requests/294
# gets merged this will be no longer needed
RUN mkdir /var/mnt

RUN bootc container lint
