#!/usr/bin/env python3
import fcntl
import json
import os
import re
import subprocess
import sys
import termios

from snack import ButtonChoiceWindow, EntryWindow, ListboxChoiceWindow, SnackScreen

VT_OPENQRY = 0x5600
VT_ACTIVATE = 0x5606
VT_WAITACTIVE = 0x5607
__version__ = "{{ VERSION }}"

MIN_DISK_GB = 10
MIN_DISK_BYTES = MIN_DISK_GB * 1024**3

HOSTNAME_RE = re.compile(
    r"^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)(\.([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?))*$"
)


def setup_tty(target_tty_n=6):
    # Find first free VT
    tty0 = os.open("/dev/tty0", os.O_RDWR)

    fcntl.ioctl(tty0, VT_ACTIVATE, target_tty_n)
    fcntl.ioctl(tty0, VT_WAITACTIVE, target_tty_n)
    os.close(tty0)

    target_tty = f"/dev/tty{target_tty_n}"

    # Fork so the child can become a new session leader and claim the tty
    pid = os.fork()
    if pid > 0:
        _, status = os.waitpid(pid, 0)
        sys.exit(os.waitstatus_to_exitcode(status))

    # Child: create new session, then claim the free tty as controlling terminal
    os.setsid()
    fd = os.open(target_tty, os.O_RDWR)
    fcntl.ioctl(fd, termios.TIOCSCTTY, 1)
    os.dup2(fd, 0)
    os.dup2(fd, 1)
    os.dup2(fd, 2)
    if fd > 2:
        os.close(fd)


def write_error(message):
    print(f"Error: {message}")
    with open("/tmp/ks-pre-error.txt", "w", encoding="utf-8") as error_file:
        error_file.write(f"{message}\n")


def get_installer_disk():
    """Return the disk name hosting the installer media (example 'sda'), or None."""

    def _disk_for_device(dev):
        """Given a device path or name, return the parent disk name."""
        if not dev:
            return None
        dev = dev.strip().strip("\n")
        if dev.startswith("/dev/"):
            dev = dev[len("/dev/") :]
        try:
            pkname = subprocess.run(
                ["lsblk", "-no", "PKNAME", f"/dev/{dev}"],
                check=True,
                capture_output=True,
                text=True,
            ).stdout
            lines = [l.strip() for l in pkname.splitlines() if l.strip()]
            pkname = lines[0] if lines else ""
            return pkname if pkname else dev
        except Exception:
            return dev

    for mountpoint in ("/run/install/repo", "/run/install/source"):
        try:
            result = subprocess.run(
                ["findmnt", "-n", "-o", "SOURCE", mountpoint],
                check=True,
                capture_output=True,
                text=True,
            )
            source = result.stdout.strip().strip("\n")
            if (
                source
                and not source.startswith("tmpfs")
                and not source.startswith("overlay")
            ):
                disk = _disk_for_device(source)
                if disk:
                    return disk
        except Exception:
            pass

    return None


def get_disks():
    installer_disk = get_installer_disk()

    result = subprocess.run(
        ["lsblk", "-J", "-dn", "-o", "NAME,SIZE,MODEL,TYPE,FSTYPE"],
        check=True,
        capture_output=True,
        text=True,
    )
    blockdevices = json.loads(result.stdout).get("blockdevices", [])

    with open("/tmp/installer-disk-detection.txt", "w", encoding="utf-8") as f:
        f.write(f"installer_disk={installer_disk!r}\n")

    return [
        disk
        for disk in blockdevices
        if (
            disk.get("type") == "disk"
            and disk.get("fstype") not in ["swap"]
            and disk.get("name", "").strip() != installer_disk
        )
    ]


def select_language(screen):
    items = [("English", "en_US.UTF-8"), ("French", "fr_FR.UTF-8")]
    button, selected_language = ListboxChoiceWindow(
        screen,
        "Language selection",
        "Select language:",
        items,
        buttons=["OK", "Cancel"],
        height=min(max(len(items), 1), 12),
        scroll=1,
    )
    if button == "cancel":
        write_error("Language selection cancelled.")
        return None
    subprocess.run(["localectl", "set-locale", selected_language], check=True)
    subprocess.run(
        ["loadkeys", selected_language.split(".")[0].split("_")[1].lower()], check=True
    )
    return selected_language


def parse_size_bytes(size_str):
    """Convert lsblk human-readable size string (e.g. '8G', '500M') to bytes."""
    if not size_str:
        return 0
    units = {"B": 1, "K": 1024, "M": 1024**2, "G": 1024**3, "T": 1024**4}
    size_str = size_str.strip().upper()
    for suffix, multiplier in units.items():
        if size_str.endswith(suffix):
            try:
                return float(size_str[:-1]) * multiplier
            except ValueError:
                return 0
    try:
        return float(size_str)
    except ValueError:
        return 0


def select_disk(screen, disks):
    items = []
    for disk in disks:
        model = (disk.get("model") or "Unknown model").strip()
        label = f"{disk['name']} ({disk.get('size', 'Unknown size')}, {model}, {disk.get('fstype', 'Unknown fstype')})"
        items.append((label, disk["name"]))

    while True:
        button, selected_disk = ListboxChoiceWindow(
            screen,
            "Disk selection",
            (
                f"WARNING: the selected disk will be completely formatted!\n\n"
                f"Minimum required: {MIN_DISK_GB} GB\n\n"
                "Select target disk:"
            ),
            items,
            buttons=["OK", "Cancel"],
            height=min(max(len(items), 1), 12),
            scroll=1,
        )
        if button == "cancel":
            write_error("Disk selection cancelled.")
            return None

        disk_info = next((d for d in disks if d["name"] == selected_disk), {})
        disk_bytes = parse_size_bytes(disk_info.get("size", "") if disk_info else "")
        if disk_bytes < MIN_DISK_BYTES:
            action = ButtonChoiceWindow(
                screen,
                "Insufficient disk size",
                (
                    f"Disk '{selected_disk}' is too small "
                    f"({disk_info.get('size', 'unknown')}).\n\n"
                    f"At least {MIN_DISK_GB} GB is required."
                ),
                buttons=["Reconfigure", "Cancel"],
            )
            if action == "cancel":
                write_error("Disk selection cancelled: disk too small.")
                return None
            continue

        return selected_disk


def prompt_hostname(screen):
    while True:
        button, values = EntryWindow(
            screen,
            "Hostname",
            "Define hostname:",
            [("Hostname", "")],
            buttons=["OK", "Cancel"],
        )
        if button == "cancel":
            write_error("Hostname entry cancelled.")
            return None

        hostname = values[0].strip()
        if HOSTNAME_RE.match(hostname):
            return hostname


def write_partitioning(hostname, install_disk, lang):
    with open("/tmp/partitioning.ks", "w", encoding="utf-8") as kickstart_file:
        kickstart_file.write(
            f"""network --no-activate --hostname={hostname}
lang {lang}
keyboard {lang[:2]}
ignoredisk --only-use={install_disk}
clearpart --all --initlabel --drives={install_disk} --disklabel=gpt
zerombr
part biosboot  --fstype=biosboot --size=1 --ondisk={install_disk} --label=biosboot
part /boot --fstype=ext4 --size=1000 --ondisk={install_disk} --label=boot
part /boot/efi --fstype=efi --size=500 --ondisk={install_disk} --label=efi
part pv.01 --fstype=lvmpv --ondisk={install_disk} --size=10000 --grow --label=pv.01
volgroup {install_disk}_system pv.01
logvol / --vgname={install_disk}_system --fstype=xfs --size=10000 --name=root
# logvol /var/etc --vgname={install_disk}_system --fstype=xfs --size=500 --fsoption="x-initrd.mount,nosuid,nodev,noexec" --name=etc
# logvol /var/log --vgname={install_disk}_system --fstype=xfs --size=1000 --fsoption="nosuid,nodev,noexec" --name=log
logvol /var --vgname={install_disk}_system --fstype=xfs --size=1000 --grow --fsoption="x-initrd.mount,nosuid,nodev,noexec" --name=var
"""
        )


def get_bootc_version():
    try:
        with open("/run/install/repo/osbuild-base.ks", "r", encoding="utf-8") as f:
            for line in f:
                if line.startswith("bootc switch"):
                    return line.split(" ")[-1].strip()
    except Exception as e:
        write_error(str(e))
    return "None"


setup_tty()

disks = get_disks()
if not disks:
    write_error("No install disk found.")
    sys.exit(1)

screen = SnackScreen()
screen.drawRootText(
    1,
    0,
    "Installer version: ghcr.io/lawik974/fedora-bootc-installer:" + __version__,
)
screen.drawRootText(1, 1, "Image to install: " + get_bootc_version())

screen.refresh()
try:
    while True:
        install_disk = select_disk(screen, disks)
        if install_disk is None:
            sys.exit(1)

        lang = select_language(screen)
        if lang is None:
            sys.exit(1)

        hostname = prompt_hostname(screen)
        if hostname is None:
            sys.exit(1)

        choice = ButtonChoiceWindow(
            screen,
            "Confirmation",
            (
                "Confirm installation settings:\n\n"
                f"Target disk: {install_disk}\n"
                f"Language: {lang}\n"
                f"Hostname: {hostname}"
            ),
            buttons=["Accept", "Reconfigure", "Exit"],
        )
        if choice == "accept":
            write_partitioning(hostname, install_disk, lang)
            break
        if choice == "exit":
            write_error("Installation configuration cancelled.")
            sys.exit(1)
finally:
    screen.finish()
    # try:
    #     tty0 = os.open("/dev/tty0", os.O_RDWR)
    #     fcntl.ioctl(tty0, VT_ACTIVATE, 1)
    #     fcntl.ioctl(tty0, VT_WAITACTIVE, 1)
    #     os.close(tty0)
    # except OSError:
    #     pass
