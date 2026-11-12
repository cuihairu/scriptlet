#!/bin/sh
# Mount an installed Linux system and chroot into it.
#
# Mounts <ROOT_DEV> (default /dev/bcache0) as the root, <BOOT_DEV>
# (default /dev/sda1) as /boot, binds /dev /proc /sys, then chroots.
# Runs each mount with preflight checks so a bad device or a busy mount
# aborts instead of chrooting into the wrong root.
#
# Device names are the parts you usually need to change — edit ROOT_DEV
# and BOOT_DEV below to match your machine.
#
# Usage:
#   sudo sh mount_other_linux_as_chroot.sh            # mount + chroot
#   sudo sh mount_other_linux_as_chroot.sh unmount    # unmount everything
#
# Requires: sudo, mount, umount, chroot (util-linux)

set -e

ROOT_DEV="${ROOT_DEV:-/dev/bcache0}"
BOOT_DEV="${BOOT_DEV:-/dev/sda1}"
MOUNTPOINT="${MOUNTPOINT:-/mnt}"

fail() {
	echo "mount_other_linux_as_chroot: $*" >&2
	exit 1
}

# Unmount in reverse order and try to remove the mountpoint.
# sudo is required: the mounts were created via sudo, and a non-root user
# cannot unmount them.
unmount_all() {
	echo "Unmounting..."
	sudo umount "${MOUNTPOINT}/dev" 2>/dev/null || true
	sudo umount "${MOUNTPOINT}/proc" 2>/dev/null || true
	sudo umount "${MOUNTPOINT}/sys" 2>/dev/null || true
	sudo umount "${MOUNTPOINT}/boot" 2>/dev/null || true
	sudo umount "${MOUNTPOINT}" 2>/dev/null || true
	echo "Done. ${MOUNTPOINT} should be free."
}

if [ "$1" = "unmount" ]; then
	unmount_all
	exit 0
fi

[ -b "${ROOT_DEV}" ] || fail "root device ${ROOT_DEV} does not exist"
[ -b "${BOOT_DEV}" ] || fail "boot device ${BOOT_DEV} does not exist"

# A busy mountpoint means something is already mounted there; abort so we
# never chroot into the wrong tree.
if mountpoint -q "${MOUNTPOINT}"; then
	fail "${MOUNTPOINT} is already a mountpoint (is something already mounted there?)"
fi

[ -d "${MOUNTPOINT}" ] || sudo mkdir -p "${MOUNTPOINT}"

sudo mount "${ROOT_DEV}" "${MOUNTPOINT}"
sudo mkdir -p "${MOUNTPOINT}/boot"
sudo mount "${BOOT_DEV}" "${MOUNTPOINT}/boot"
sudo mount --bind /dev "${MOUNTPOINT}/dev"
sudo mount --bind /proc "${MOUNTPOINT}/proc"
sudo mount --bind /sys "${MOUNTPOINT}/sys"

echo "Chrooting into ${MOUNTPOINT} (exit chroot, then run:"
echo "  sudo sh $0 unmount   to clean up mounts)"
sudo chroot "${MOUNTPOINT}"
