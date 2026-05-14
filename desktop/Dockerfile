####################
# Stage Builder
####################
FROM ghcr.io/lawik974/fedora-bootc-base:main as builder

LABEL maintainer="Loïc Dubard"
LABEL org.opencontainers.image.authors="Loïc Dubard"
LABEL org.opencontainers.image.title="Fedora Bootc Desktop"
LABEL org.opencontainers.image.description="A Fedora-based desktop image built with bootc, featuring GNOME and a selection of pre-installed applications, designed for users seeking a ready-to-use desktop environment in a containerized format."
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.source="https://github.com/lawik974/fedora-bootc"

RUN mkdir -p /etc/skel/.config/terminator
COPY ./terminator.config /etc/skel/.config/terminator/config
COPY ./wallpaper.jpg /usr/share/backgrounds/wallpaper.jpg
COPY ./fedora.png /usr/share/icons/fedora.png
# Apply customizations to the image.
COPY --chmod=755 ./setup.sh /tmp/setup.sh
RUN /tmp/setup.sh

# Run the bootc linter to avoid encountering certain bugs and maintain content quality. Place this command last in your Containerfile.
RUN bootc container lint
