######################
# Stage Builder
######################
# Begin with a standard bootc base image that serves as a "builder" for our custom image.
FROM quay.io/fedora/fedora-bootc:43 as builder
RUN /usr/libexec/bootc-base-imagectl build-rootfs --manifest=minimal /target-rootfs
# Create a new, empty image from scratch.


###############
# Stage intermediate 1
###############
FROM alpine:3.20 AS busybox-build

RUN apk add --no-cache busybox-static


#####################
# Stage Intermediate 2
#####################
FROM scratch as final

# Copy the root file system built in the previous step into this image.
COPY --from=builder /target-rootfs/ /
# Install a static busybox binary on top of UBI minimal.
COPY --from=busybox-build /bin/busybox.static /usr/bin/busybox
RUN chmod 0755 /usr/bin/busybox && \
        /usr/bin/busybox --install -s /usr/bin
# Apply customizations to the image.
COPY --chmod=755 ./setup.sh /tmp/setup.sh
RUN /tmp/setup.sh && rm /tmp/setup.sh

#################
# Stage Final
#################
FROM scratch
# Copy the customized root file system built in the previous step into this image.
COPY --from=final --exclude=/var --exclude=/run --exclude=/tmp / /

# Define required labels for this bootc image to be recognized as such.
LABEL containers.bootc 1
LABEL ostree.bootable 1
# Optional labels that only apply when running this image as a container. These keep the default entry point running under systemd.
STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]
# Run the bootc linter to avoid encountering certain bugs and maintain content quality. Place this command last in your Containerfile.
RUN bootc container lint
