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
if ! dnf5 upgrade --refresh -y;then
log_error "Failed to upgrade existing packages."
exit 1
fi
if ! dnf5 -y install --refresh $DNF_OPTS --best --allowerasing akmod-nvidia xorg-x11-drv-nouveau;then
log_error "Failed to install NVIDIA and Nouveau drivers."
exit 1
fi
if ! echo "blacklist nvidia" >/etc/modprobe.d/blacklist-nvidia.conf;then
log_error "Failed to create blacklist for NVIDIA."
exit 1
fi
if ! dracut --force;then
log_error "Failed to create initramfs."
exit 1
fi
if ! akmods --force --kernels "$(rpm -q kernel-core --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n')";then
log_error "Failed to compile kernel modules."
exit 1
fi
dnf5 remove -y rpmfusion-free-release rpmfusion-nonfree-release||true
dnf5 clean all||true
fi
