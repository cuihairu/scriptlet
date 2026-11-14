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

## Codex 深审发现（2026-11-13，luna profile 近5 commit 审核，待修）

- [Major] 中途挂载失败没有回滚 | 位置 linux/mount_other_linux_as_chroot.sh:58 | 问题：连续执行 `sudo mount ...`，仅依赖 `set -e`，没有失败清理。桩验证根挂载成功、boot 挂载失败后返回 32，未调用任何 umount；失败发生在清理提示之前。属于 P1-4“留脏挂载”问题的残留 | 影响：根或部分系统目录保持挂载，后续重试被占用检查拒绝 | 修复方向：记录本次成功的挂载，在异常退出时逆序回滚，保留原始错误码；覆盖各阶段失败。
- [Major] 占用检测测试依赖真实块设备 | 位置 tests/run.sh:203 | 问题：硬编码 `ROOT_DEV="/dev/loop0" BOOT_DEV="/dev/loop1"`，但仅替换外部命令，没有替换脚本中的 `-b` 检查。本环境两个设备均不存在；实跑相同入口后直接报 `root device ... does not exist`，未进入 mountpoint 分支，与“no ... real block devices needed”矛盾 | 影响：普通容器中该测试失败，目标分支无法验证 | 修复方向：提供可注入的设备检查方式，让测试无需真实块设备，并断言确实到达占用检测。
- [Major] 卸载失败仍返回成功 | 位置 linux/mount_other_linux_as_chroot.sh:34 | 问题：`sudo umount ... 2>/dev/null || true` 对五个目标全部吞错，随后打印 `Done` 并 `exit 0`。实跑桩验证：全部卸载返回 32，脚本仍返回 0；`28cf204` 新增的卸载路径重新引入“假成功”。现有测试将 umount 固定为成功，只验证调用日志 | 影响：设备忙、权限不足等情况下，调用方误认为挂载已清理 | 修复方向：继续尝试所有卸载，但汇总失败、保留诊断并返回非零；增加卸载失败用例。
- [Major] 合法空包仍可被报告为字体修复成功 | 位置 linux/fix-wps-missing-font.sh:35 | 问题：`tar -tf` 只检查归档可读性；解压后没有确认安装了字体便打印 `fix success`。实跑合法空 tar 的列举及向标准输出解包均返回 0、内容为空；扁平包中的字体也会被 `--strip-components 1` 跳过。现有测试仅使用预期目录结构和明显损坏的数据 | 影响：下载了结构错误但合法的归档时，字体未安装仍可能报告成功 | 修复方向：检查归档布局及预期字体成员，安装后核验对应文件；增加空包和扁平布局用例。
- [Major] 挂载点检查异常被当作空闲 | 位置 linux/mount_other_linux_as_chroot.sh:52 | 问题：`if mountpoint -q ...; then ... fi` 将所有非零结果视为可继续，`set -e` 不会中止这个条件命令。桩验证检查返回 127 后，脚本仍执行全部 mount 和 chroot；依赖列表也未列出 mountpoint | 影响：检查工具缺失或检查失败时绕过安全前置条件 | 修复方向：明确检查依赖，区分“不是挂载点”和执行错误；增加异常退出码测试。
- [Minor] PowerShell 脚本保留失败后继续执行的同型问题 | 位置 dev.ps1:6 | 问题：连续执行 `scoop bucket add`、`scoop update`、`scoop install`，未检查各步结果；唯一的 `if (!$?)` 只处理开头一次 scoop 调用。该文件由审核范围内的 `984966a` 新增 | 影响：bucket、更新或安装失败后继续执行，无法可靠汇总缺失的软件 | 修复方向：检查每次 Scoop 调用的结果，明确失败即停或汇总失败，并返回非零状态；本项为静态确认，环境没有 pwsh。
- [Minor] 完成台账夸大测试覆盖 | 位置 todo.md:11 | 问题：`28cf204` 写入“2 例……均断言……无残留”，实际只有 `tests/run.sh:120` 的下载失败用例检查残留，损坏包用例没有；`:7` 的“全部修复”也未体现上述挂载残留问题。`9c5c09f` 将提交号修正为 `28cf204` 与 Git 一致，但没有纠正这些覆盖声明 | 影响：维护者会高估完成度；`:18` 的历史真机结果缺少仓内原始日志，本次无法独立复核 | 修复方向：补齐缺失断言，按实际覆盖修订完成状态，并将历史验证声明与可复核证据区分。
- [Minor] 权限测试没有证明权限修正生效 | 位置 tests/run.sh:89 | 问题：测试使用 `mkdir -p` 和 `printf > 文件` 创建夹具；常见 umask 022 下，它们已经是目录 755、文件 644。因此即使删除生产代码的两条 chmod，权限断言仍可通过 | 影响：测试无法防止权限修复被删除的回归 | 修复方向：打包前显式设置不符合目标的文件、目录权限，再验证安装后的修正结果。