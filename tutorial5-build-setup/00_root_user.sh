#!/bin/bash
# Clean-distro bootstrap (as root): a normal user with sudo, as a fresh Ubuntu-on-WSL first launch creates.
set -euo pipefail
adduser --quiet --gecos "" --disabled-password tester
usermod -aG adm,cdrom,sudo,dip,plugdev tester
printf 'tester ALL=(ALL) NOPASSWD:ALL\n' >/etc/sudoers.d/90-tester
chmod 0440 /etc/sudoers.d/90-tester
printf '\n[user]\ndefault=tester\n' >>/etc/wsl.conf
. /etc/os-release
echo "$PRETTY_NAME | kernel $(uname -r) | cpus $(nproc) | $(grep MemTotal /proc/meminfo) | $(grep SwapTotal /proc/meminfo)"
for tool in gcc g++ cc cmake ninja pkg-config; do
  command -v "$tool" >/dev/null && echo "present: $tool" || echo "absent:  $tool"
done
dpkg -l | grep -cE '^ii' | sed 's/^/installed packages: /'
