# scriptlet

零散运维脚本合集。

- [English](/)
- [README.md](https://github.com/cuihairu/scriptlet/blob/main/README.md) — 同一内容，英文
- [README.zh.md](https://github.com/cuihairu/scriptlet/blob/main/README.zh.md) — 同一内容，中文

## 脚本索引

| 脚本 | 用途 | 用法 |
| --- | --- | --- |
| `linux/fix-wps-missing-font.sh` | 修复 WPS Office 缺字体：从本仓 Release（`v0.0.1` 资产 `wps-fonts.tar.xz`）下载字体包，解压到 `/usr/share/fonts/wps-office`（文件 644、目录 755），并重建字体缓存（`mkfontscale`/`mkfontdir`/`fc-cache -fv`）；下载失败或包损坏即中止，不误报成功。下载 URL 与安装目录可用 `DOWNLOAD_URL` / `FONT_HOME` 环境变量覆盖 | `sh fix-wps-missing-font.sh`（需 `wget` + `sudo`） |
| `linux/mount_other_linux_as_chroot.sh` | 把已装的 Linux 系统挂载并 chroot 进去（`/dev/bcache0` 为根、`/dev/sda1` 为 `/boot`，绑定 `dev`/`proc`/`sys`）。设备与挂载点取自 `ROOT_DEV` / `BOOT_DEV` / `MOUNTPOINT` 环境变量（默认 `/dev/bcache0`、`/dev/sda1`、`/mnt`）；挂载前校验设备存在且挂载点空闲，退出 chroot 后用 `sh mount_other_linux_as_chroot.sh unmount` 卸载 | `sudo sh mount_other_linux_as_chroot.sh`；`sudo sh mount_other_linux_as_chroot.sh unmount` |
| `hackintosh/fix_win_time.bat` | 修 Windows/macOS 双系统时间差：写注册表 `RealTimeIsUniversal=1`，让 Windows 按 UTC 读硬件时钟（管理员 cmd 运行） | 管理员权限运行 `fix_win_time.bat` |

## 回归测试

Shell 脚本的回归测试在 `tests/run.sh`，运行 `sh tests/run.sh`。

## docker

docker 一键安装脚本

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh --mirror=Aliyun
```

## Homebrew

一键安装脚本

```bash
/bin/zsh -c "$(curl -fsSL https://gitee.com/cunkai/HomebrewCN/raw/master/Homebrew.sh)"
```
