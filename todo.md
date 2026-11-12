# todo

## 已完成

### 2026-11-12 审核报告批次6（audit-batch6-6repos-2026-11-11）scriptlet 节修复

审核结论：P0 0 条；P1 4 条，全部落在两个 shell 脚本的错误处理/权限面。本次全部修复并配回归测试。

| ID | 原问题 | 修复 | 证据 | 回归测试 |
| --- | --- | --- | --- | --- |
| P1-1 | `linux/fix-wps-missing-font.sh:12-14` wget 失败仍继续、`[ -f ]` 对 0 字节/残包通过、无 `set -e` → 可能误报 `fix success` | 加 `set -e`；`wget` 退出码判定；下载后 `tar -tf` 校验包完整性，失败即 `exit 1`；补 `command -v wget` 前置检查；临时文件 `mktemp` + `trap cleanup EXIT` | `linux/fix-wps-missing-font.sh:7,13,18,29,35` | `tests/run.sh` P1-1（2 例：wget 失败 / 包损坏，均断言非 0 退出、无 success、无残留） |
| P1-2 | 同文件 `:21` `chmod 644 ${FontHome}/*` 只改顶层，子目录文件漏改、目录被 644 化不可进入 | 改 `find -type f -exec chmod 644 {} +` + `find -type d -exec chmod 755 {} +` | `linux/fix-wps-missing-font.sh:43-44` | `tests/run.sh` P1-2（嵌套子目录：文件 644、目录 755） |
| P1-3 | 同文件 `:25` `mkfontdir`/`fc-cache` 未加 sudo，非 root 写不动 `/usr/share/fonts`，缓存实际未重建但仍打印 success | 三命令统一 `sudo`，并逐个独立执行 | `linux/fix-wps-missing-font.sh:48-50` | `tests/run.sh` P1-3（sudo 日志断言 mkfontscale/mkfontdir/fc-cache 三者均经 sudo） |
| P1-4 | `linux/mount_other_linux_as_chroot.sh:1-2` 无设备/挂载点前置检查、无 `set -e`、无卸载路径 → 可能 chroot 进错误根并留脏挂载 | 加 `set -e`；`-b` 校验 root/boot 设备；`mountpoint -q` 拒绝已占用挂载点；`mkdir -p /boot`；新增 `unmount` 子命令按 逆序 dev/proc/sys/boot/root 卸载（经 sudo，非 root 无法卸载 root 挂载）；设备与挂载点支持 `ROOT_DEV`/`BOOT_DEV`/`MOUNTPOINT` 覆盖 | `linux/mount_other_linux_as_chroot.sh:19-44,52-68` | `tests/run.sh` P1-4（3 例：缺设备中止且零 mount / 挂载点被占用中止 / unmount 全量清理且不挂载） |

- 测试：`sh tests/run.sh` → 7 passed, 0 failed。
- 静态检查：`shellcheck -S error` 两脚本 clean；`sh -n` 通过。
- 真机验证：`fix-wps` 对真实 Release 资产 `v0.0.1/wps-fonts.tar.xz` 端到端跑通（rc=0，字体 644 落盘，fc-cache succeeded）；`mount` 脚本对 `/dev/loop0` 挂载失败正确中止（rc=32，无挂载残留、未 chroot）；对真实 bind mount 的占用检测与 `unmount` 清理均实测生效（卸载后 0 残留）。
- 未修（审核列为 P2，本次不动）：变量未加引号类历史写法已随重写收敛；下载无校验和（依赖 GitHub Release 完整性）；`dev.ps1`/`fix_win_time.bat` 的 P2 项。
- 提交：`28cf204`（代码+测试+README 一份 commit；随后 `docs: fix commit sha in todo ledger` 仅修正本行 sha）。

## 待办

- 无。
