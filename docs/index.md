# scriptlet

A collection of miscellaneous ops scripts.

- [简体中文](/zh/)
- [README.md](https://github.com/cuihairu/scriptlet/blob/main/README.md) — same content, English
- [README.zh.md](https://github.com/cuihairu/scriptlet/blob/main/README.zh.md) — same content, Chinese

## Script index

| Script | Purpose | Usage |
| --- | --- | --- |
| `linux/fix-wps-missing-font.sh` | Fix missing WPS Office fonts: download the font package from this repo's Release (`v0.0.1` asset `wps-fonts.tar.xz`), extract it to `/usr/share/fonts/wps-office` (files 644, directories 755), and rebuild the font cache (`mkfontscale`/`mkfontdir`/`fc-cache -fv`); aborts on download failure or a broken package instead of reporting success. The download URL and install directory can be overridden via the `DOWNLOAD_URL` / `FONT_HOME` environment variables | `sh fix-wps-missing-font.sh` (requires `wget` + `sudo`) |
| `linux/mount_other_linux_as_chroot.sh` | Mount an installed Linux system and chroot into it (`/dev/bcache0` as root, `/dev/sda1` as `/boot`, bind-mounting `dev`/`proc`/`sys`). Device names and the mountpoint are taken from the `ROOT_DEV` / `BOOT_DEV` / `MOUNTPOINT` environment variables (defaults `/dev/bcache0`, `/dev/sda1`, `/mnt`); before mounting it verifies the devices exist and the mountpoint is free, and after leaving the chroot run `sh mount_other_linux_as_chroot.sh unmount` to unmount | `sudo sh mount_other_linux_as_chroot.sh`; `sudo sh mount_other_linux_as_chroot.sh unmount` |
| `hackintosh/fix_win_time.bat` | Fix the Windows/macOS dual-boot clock drift: writes the registry value `RealTimeIsUniversal=1` so Windows reads the hardware clock as UTC (run from an admin cmd) | Run `fix_win_time.bat` with administrator rights |

## Tests

Regression tests for the shell scripts live in `tests/run.sh`; run them with `sh tests/run.sh`.

## docker

One-shot Docker install script:

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh --mirror=Aliyun
```

## Homebrew

One-shot install script:

```bash
/bin/zsh -c "$(curl -fsSL https://gitee.com/cunkai/HomebrewCN/raw/master/Homebrew.sh)"
```
