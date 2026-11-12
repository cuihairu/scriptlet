#!/bin/sh
# Regression tests for the P1 fixes in scriptlet shell scripts.
# Each test reproduces one reported bug; no sudo or real block devices needed
# (sudo/mount/umount/chroot/wget/mkfontscale are stubbed in a temp PATH).
#
# Usage: sh tests/run.sh

set -u

SCRIPTLET_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

pass=0
fail=0

# ---------------------------------------------------------------------------
# Stub environment builders
# ---------------------------------------------------------------------------

# fake_wps_env <ok|fail|corrupt> [sudo_logger]
# Prints the stub bin dir. Stubs: sudo (optionally logging), wget, and the
# three font-cache commands (so the script never needs root or real tools).
fake_wps_env() {
	local wgetmode="$1"
	local bindir="${TMP}/bin-$wgetmode"
	mkdir -p "${bindir}"

	if [ "${2:-}" = "sudo_logger" ]; then
		printf '%s\n' '#!/bin/sh' \
			"echo \"sudo: \$*\" >> \"${TMP}/sudo.log\"" \
			'exec "$@"' > "${bindir}/sudo"
	else
		printf '%s\n' '#!/bin/sh' 'exec "$@"' > "${bindir}/sudo"
	fi

	case "${wgetmode}" in
	ok)
		printf '%s\n' '#!/bin/sh' \
			'dest=""' \
			'while [ $# -gt 0 ]; do if [ "$1" = "-O" ]; then dest="$2"; shift 2; else shift; fi; done' \
			"cp \"${TMP}/fonts.tar.xz\" \"\$dest\"" > "${bindir}/wget"
		;;
	corrupt)
		printf '%s\n' '#!/bin/sh' \
			'dest=""' \
			'while [ $# -gt 0 ]; do if [ "$1" = "-O" ]; then dest="$2"; shift 2; else shift; fi; done' \
			'printf "not a tar archive" > "$dest"' > "${bindir}/wget"
		;;
	*)
		printf '%s\n' '#!/bin/sh' 'echo "wget: network error" >&2' 'exit 1' > "${bindir}/wget"
		;;
	esac

	# Font cache tools: log + succeed.
	for tool in mkfontscale mkfontdir fc-cache; do
		printf '%s\n' '#!/bin/sh' \
			"echo \"${tool} \$*\" >> \"${TMP}/cache.log\"" \
			'exit 0' > "${bindir}/${tool}"
	done

	# chown needs root in the real script; stub it out.
	printf '%s\n' '#!/bin/sh' 'exit 0' > "${bindir}/chown"

	chmod +x "${bindir}"/*
	echo "${bindir}"
}

# fake_mount_env <mountpoint_exit>
# Prints the stub bin dir for the chroot script. mount/umount/chroot log to
# mount.log; mountpoint exits with the given code.
fake_mount_env() {
	local mp_exit="${1:-1}"
	local bindir="${TMP}/mbind-${mp_exit}"
	mkdir -p "${bindir}"
	printf '%s\n' '#!/bin/sh' 'exec "$@"' > "${bindir}/sudo"
	printf '%s\n' '#!/bin/sh' "echo \"mount: \$*\" >> \"${TMP}/mount.log\"" 'exit 0' > "${bindir}/mount"
	printf '%s\n' '#!/bin/sh' "echo \"umount: \$*\" >> \"${TMP}/mount.log\"" 'exit 0' > "${bindir}/umount"
	printf '%s\n' '#!/bin/sh' "echo \"chroot: \$*\" >> \"${TMP}/mount.log\"" 'exit 0' > "${bindir}/chroot"
	printf '%s\n' '#!/bin/sh' "exit ${mp_exit}" > "${bindir}/mountpoint"
	chmod +x "${bindir}"/*
	echo "${bindir}"
}

make_font_tar() {
	rm -rf "${TMP}/pkg"
	# Mirror the real release layout: a single top-level dir that
	# `--strip-components 1` removes.
	mkdir -p "${TMP}/pkg/wps-fonts"
	if [ "$1" = "nested" ]; then
		mkdir -p "${TMP}/pkg/wps-fonts/subdir"
		printf 'fontdata' > "${TMP}/pkg/wps-fonts/subdir/deep.ttf"
	else
		printf 'fontdata' > "${TMP}/pkg/wps-fonts/somefont.ttf"
	fi
	tar -C "${TMP}/pkg" -cJf "${TMP}/fonts.tar.xz" wps-fonts
}

# run_wps <bindir> <fonthome> ; prints combined output, returns script rc
run_wps() {
	local bin="$1" fonthome="$2"
	PATH="${bin}:${PATH}" \
		TMPDIR="${TMP}" \
		FONT_HOME="${fonthome}" \
		DOWNLOAD_URL="http://example.invalid/wps-fonts.tar.xz" \
		sh "${SCRIPTLET_DIR}/linux/fix-wps-missing-font.sh" 2>&1
}

# ---------------------------------------------------------------------------
# P1-1: download failure / corrupted archive must abort, never print success
# ---------------------------------------------------------------------------
test_wget_failure_aborts() {
	make_font_tar flat
	local bin; bin=$(fake_wps_env fail)
	local fonthome="${TMP}/fh-fail"; mkdir -p "${fonthome}"
	local out rc
	out=$(run_wps "${bin}" "${fonthome}"); rc=$?
	[ "${rc}" -ne 0 ] || { echo "FAIL: wget failure should exit non-zero"; return 1; }
	case "${out}" in *"fix success"*) echo "FAIL: printed fix success after wget failure"; return 1;; esac
	if ls "${TMP}"/wps-fonts.tar.xz* >/dev/null 2>&1; then
		echo "FAIL: temp tarball leaked"; return 1
	fi
	echo "PASS: wget failure aborts, no success message, temp file removed"
}

test_corrupt_download_aborts() {
	make_font_tar flat
	local bin; bin=$(fake_wps_env corrupt)
	local fonthome="${TMP}/fh-corrupt"; mkdir -p "${fonthome}"
	local out rc
	out=$(run_wps "${bin}" "${fonthome}"); rc=$?
	[ "${rc}" -ne 0 ] || { echo "FAIL: corrupt archive should exit non-zero"; return 1; }
	case "${out}" in
		*"fix success"*) echo "FAIL: printed fix success for corrupt archive"; return 1;;
	esac
	case "${out}" in
		*corrupt*) : ;;
		*) echo "FAIL: no corruption diagnostic; output was: ${out}"; return 1;;
	esac
	echo "PASS: corrupt archive aborts with diagnostic, no success message"
}

# ---------------------------------------------------------------------------
# P1-2: chmod must cover subdirectory files and keep dirs 755
# ---------------------------------------------------------------------------
test_subdir_permissions() {
	make_font_tar nested
	local bin; bin=$(fake_wps_env ok)
	local fonthome="${TMP}/fh-perm"; mkdir -p "${fonthome}"
	run_wps "${bin}" "${fonthome}" >/dev/null 2>&1 || { echo "FAIL: install failed"; return 1; }
	[ -f "${fonthome}/subdir/deep.ttf" ] || { echo "FAIL: nested file not installed"; return 1; }
	local fmode dmode
	fmode=$(stat -c %a "${fonthome}/subdir/deep.ttf")
	dmode=$(stat -c %a "${fonthome}/subdir")
	[ "${fmode}" = "644" ] || { echo "FAIL: nested file mode ${fmode}, want 644"; return 1; }
	[ "${dmode}" = "755" ] || { echo "FAIL: subdir mode ${dmode}, want 755"; return 1; }
	echo "PASS: nested font file 644, subdirectory 755"
}

# ---------------------------------------------------------------------------
# P1-3: mkfontscale / mkfontdir / fc-cache must all run under sudo
# ---------------------------------------------------------------------------
test_cache_cmds_under_sudo() {
	make_font_tar flat
	local bin; bin=$(fake_wps_env ok sudo_logger)
	local fonthome="${TMP}/fh-sudo"; mkdir -p "${fonthome}"
	: > "${TMP}/sudo.log"
	run_wps "${bin}" "${fonthome}" >/dev/null 2>&1 || { echo "FAIL: install failed"; return 1; }
	local log; log=$(cat "${TMP}/sudo.log")
	for cmd in mkfontscale mkfontdir fc-cache; do
		case "${log}" in
			*"sudo: ${cmd}"*) : ;;
			*) echo "FAIL: ${cmd} not run under sudo; sudo log: ${log}"; return 1;;
		esac
	done
	echo "PASS: mkfontscale, mkfontdir, fc-cache all run under sudo"
}

# ---------------------------------------------------------------------------
# P1-4: mount script preflight checks and unmount path
# ---------------------------------------------------------------------------
test_missing_root_device_aborts() {
	local bin; bin=$(fake_mount_env 1)
	local mp="${TMP}/mp-missing"; mkdir -p "${mp}"
	: > "${TMP}/mount.log"
	local out rc
	out=$(ROOT_DEV="/dev/no-such-root" BOOT_DEV="/dev/no-such-boot" MOUNTPOINT="${mp}" \
		PATH="${bin}:${PATH}" sh "${SCRIPTLET_DIR}/linux/mount_other_linux_as_chroot.sh" 2>&1); rc=$?
	[ "${rc}" -ne 0 ] || { echo "FAIL: missing root device should exit non-zero"; return 1; }
	[ -s "${TMP}/mount.log" ] && { echo "FAIL: mounted despite missing device: $(cat "${TMP}/mount.log")"; return 1; }
	case "${out}" in
		*"does not exist"*) : ;;
		*) echo "FAIL: no 'does not exist' diagnostic; output: ${out}"; return 1;;
	esac
	echo "PASS: missing root device aborts before any mount attempt"
}

test_busy_mountpoint_aborts() {
	local bin; bin=$(fake_mount_env 0)   # mountpoint -q says "is a mountpoint"
	local mp="${TMP}/mp-busy"; mkdir -p "${mp}"
	: > "${TMP}/mount.log"
	local out rc
	out=$(ROOT_DEV="/dev/loop0" BOOT_DEV="/dev/loop1" MOUNTPOINT="${mp}" \
		PATH="${bin}:${PATH}" sh "${SCRIPTLET_DIR}/linux/mount_other_linux_as_chroot.sh" 2>&1); rc=$?
	[ "${rc}" -ne 0 ] || { echo "FAIL: busy mountpoint should exit non-zero"; return 1; }
	grep -q '^mount: ' "${TMP}/mount.log" && { echo "FAIL: mounted onto a busy mountpoint"; return 1; }
	case "${out}" in
		*"already a mountpoint"*) : ;;
		*) echo "FAIL: no busy-mountpoint diagnostic; output: ${out}"; return 1;;
	esac
	echo "PASS: busy mountpoint aborts instead of mounting over it"
}

test_unmount_cleans_up() {
	local bin; bin=$(fake_mount_env 1)
	local mp="${TMP}/mp-unmount"; mkdir -p "${mp}"
	: > "${TMP}/mount.log"
	MOUNTPOINT="${mp}" PATH="${bin}:${PATH}" sh "${SCRIPTLET_DIR}/linux/mount_other_linux_as_chroot.sh" unmount \
		>/dev/null 2>&1 || { echo "FAIL: unmount mode exited non-zero"; return 1; }
	local log; log=$(cat "${TMP}/mount.log")
	for target in "${mp}/dev" "${mp}/proc" "${mp}/sys" "${mp}/boot" "${mp}"; do
		grep -q "^umount: ${target}$" "${TMP}/mount.log" ||
			{ echo "FAIL: ${target} not unmounted; log: ${log}"; return 1; }
	done
	grep -q '^mount: ' "${TMP}/mount.log" && { echo "FAIL: unmount mode also mounted something"; return 1; }
	echo "PASS: unmount mode unmounts dev/proc/sys/boot/root and mounts nothing"
}

# ---------------------------------------------------------------------------
# run
# ---------------------------------------------------------------------------
run() {
	local name="$1"; shift
	if "$@"; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "  ^ ${name}"; fi
}

run "P1-1 wget failure aborts"        test_wget_failure_aborts
run "P1-1 corrupt download aborts"    test_corrupt_download_aborts
run "P1-2 nested file permissions"    test_subdir_permissions
run "P1-3 cache commands under sudo"  test_cache_cmds_under_sudo
run "P1-4 missing root device abort"  test_missing_root_device_aborts
run "P1-4 busy mountpoint abort"      test_busy_mountpoint_aborts
run "P1-4 unmount cleanup"            test_unmount_cleans_up

echo
echo "results: ${pass} passed, ${fail} failed"
[ "${fail}" -eq 0 ]
