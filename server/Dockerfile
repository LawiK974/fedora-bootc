FROM ghcr.io/lawik974/fedora-bootc-base:main as builder

LABEL maintainer="Loïc Dubard"
LABEL org.opencontainers.image.authors="Loïc Dubard"
LABEL org.opencontainers.image.title="Fedora Bootc server"
LABEL org.opencontainers.image.description="A Fedora-based server image built with bootc, featuring GNOME and a selection of pre-installed applications, designed for users seeking a ready-to-use server environment in a containerized format."
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.source="https://github.com/lawik974/fedora-bootc"

COPY ./k3s.service /etc/systemd/system/k3s.service
COPY ./k3s.service.env /etc/systemd/system/k3s.service.env
COPY ./k3s-manifests /var/lib/rancher/k3s/manifests
# Apply customizations to the image.
COPY --chmod=755 ./setup.sh /tmp/setup.sh
RUN /tmp/setup.sh && rm /tmp/setup.sh


# Run the bootc linter to avoid encountering certain bugs and maintain content quality. Place this command last in your Containerfile.
RUN bootc container lint
