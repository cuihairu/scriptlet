#!/bin/sh
# Fix missing fonts for WPS Office.
# Downloads the font tarball from this repo's GitHub Release and installs
# it into /usr/share/fonts/wps-office, then rebuilds the font cache.
# Usage: sh fix-wps-missing-font.sh   (requires wget + sudo)

set -e

Ver=v0.0.1
DownloadUrl="${DOWNLOAD_URL:-https://github.com/cuihairu/scriptlet/releases/download/${Ver}/wps-fonts.tar.xz}"
# Overridable for testing; defaults are the real paths.
FontHome="${FONT_HOME:-/usr/share/fonts/wps-office}"
TempFile=$(mktemp "${TMPDIR:-/tmp}/wps-fonts.tar.xz.XXXXXX")

cleanup() {
	rm -f "${TempFile}"
}
trap cleanup EXIT

if ! command -v wget >/dev/null 2>&1; then
	echo "wget not found, please install it first" >&2
	exit 1
fi

if [ ! -d "${FontHome}" ]; then
	sudo mkdir -p "${FontHome}"
fi

if ! wget -O "${TempFile}" "${DownloadUrl}"; then
	echo "download fail" >&2
	exit 1
fi

# A truncated or empty download must abort instead of failing later in tar.
if ! tar -tf "${TempFile}" >/dev/null 2>&1; then
	echo "downloaded file is corrupted (not a valid tar archive)" >&2
	exit 1
fi

sudo tar -xvf "${TempFile}" -C "${FontHome}" --strip-components 1
sudo chown root:root -R "${FontHome}"
# 644 for regular files, 755 for directories (incl. subdirectories).
sudo find "${FontHome}" -type f -exec chmod 644 {} +
sudo find "${FontHome}" -type d -exec chmod 755 {} +

# Rebuild font cache. All three steps need root to write under /usr/share/fonts.
cd "${FontHome}"
sudo mkfontscale
sudo mkfontdir
sudo fc-cache -fv
echo "fix success"
