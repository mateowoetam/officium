#!/usr/bin/env bash
set -euxo pipefail
log_error(){
echo "ERROR: $1" >&2
}
if [ "$VARIANT" = "nvidia" ];then
FEDORA_VERSION="$(rpm -E %fedora)"
DNF_OPTS="--setopt=tsflags=nodocs --setopt=install_weak_deps=False"
rpm -qa|grep -qi nvidia&&dnf5 remove -y '*nvidia*'||true
if ! dnf5 -y install --refresh $DNF_OPTS --allowerasing \
"https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$FEDORA_VERSION.noarch.rpm" \
"https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$FEDORA_VERSION.noarch.rpm";then
log_error "Failed to install RPM Fusion repositories."
exit 1
fi
dnf5 -y install $DNF_OPTS kernel-devel gcc akmods
if ! dnf5 -y install --refresh $DNF_OPTS --best --allowerasing akmod-nvidia;then
log_error "Failed to install NVIDIA drivers."
exit 1
fi
if ! echo "blacklist nouveau" >/etc/modprobe.d/blacklist-nouveau.conf;then
log_error "Failed to create blacklist for Nouveau."
exit 1
fi
KERNEL_VERSION=$(rpm -q kernel-devel --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n'|head -n 1)
if ! akmods --force --kernels "$KERNEL_VERSION";then
log_error "Failed to compile kernel modules. Check /var/cache/akmods/ for logs."
exit 1
fi
dracut --force
dnf5 remove -y rpmfusion-free-release rpmfusion-nonfree-release||true
dnf5 clean all||true
fi
