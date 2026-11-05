# scriptlet

零散运维脚本合集。

## 脚本索引

| 脚本 | 用途 | 用法 |
| --- | --- | --- |
| `linux/fix-wps-missing-font.sh` | 修复 WPS Office 缺字体：从本仓 Release（`v0.0.1` 资产 `wps-fonts.tar.xz`）下载字体包，解压到 `/usr/share/fonts/wps-office`（644 权限），并重建字体缓存（`mkfontscale`/`mkfontdir`/`fc-cache -fv`） | `sh fix-wps-missing-font.sh`（需 `wget` + `sudo`） |
| `linux/mount_other_linux_as_chroot.sh` | 把已装的 Linux 系统挂载并 chroot 进去（`/dev/bcache0` 为根、`/dev/sda1` 为 `/boot`，绑定 `dev`/`proc`/`sys`）——设备名按需手改 | `sudo sh mount_other_linux_as_chroot.sh`（逐行执行亦可） |
| `hackintosh/fix_win_time.bat` | 修 Windows/macOS 双系统时间差：写注册表 `RealTimeIsUniversal=1`，让 Windows 按 UTC 读硬件时钟（管理员 cmd 运行） | 管理员权限运行 `fix_win_time.bat` |

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
