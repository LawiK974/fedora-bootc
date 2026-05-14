# BUILD


```sh
sudo podman build -t localhost/fedora-bootc:43-custom . --cap-add=all --security-opt=label=type:container_runtime_t --device /dev/fuse \
&& sudo podman run -it --rm --security-opt label=type:unconfined_t \
    --privileged \
    -v $(pwd):/output \
    -v /var/lib/containers/storage:/var/lib/containers/storage \
    quay.io/centos-bootc/bootc-image-builder:latest \
        --verbose \
        --log-level debug \
        --progress verbose \
        --output "/output" \
        --type qcow2 \
        --rootfs ext4 \
        "localhost/fedora-bootc:43-custom"
```

# DEPLOY

```sh
sudo virt-install \
    --name fedora-bootc \
    --cpu host \
    --vcpus 4 \
    --memory 4096 \
    --import --disk ./qcow2/disk.qcow2,format=qcow2 \
    --os-variant fedora-eln
```
