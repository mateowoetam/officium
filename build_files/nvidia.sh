#!/usr/bin/env bash
set -euo pipefail
FRELEASE="$(rpm -E %fedora)"
dnf5 install -y \
"https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$FRELEASE.noarch.rpm" \
"https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$FRELEASE.noarch.rpm"
curl -fsSL https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo \
-o /etc/yum.repos.d/nvidia-container-toolkit.repo
dnf5 -y makecache
NVIDIA_PACKAGES=(
akmod-nvidia
xorg-x11-drv-nvidia
xorg-x11-drv-nvidia-cuda
xorg-x11-drv-nvidia-libs
xorg-x11-drv-nvidia-libs.i686
nvidia-modprobe
nvidia-persistenced
libva-nvidia-driver
nvidia-container-toolkit)
MESA_MULTILIB=(
mesa-dri-drivers.i686
mesa-libGL.i686
mesa-libEGL.i686
mesa-vulkan-drivers.i686)
dnf5 install -y "${NVIDIA_PACKAGES[@]}"
dnf5 install -y "${MESA_MULTILIB[@]}"
mkdir -p /usr/lib/dracut.conf.d
cat >/usr/lib/dracut.conf.d/10-nvidia.conf <<'EOF'
add_drivers+=" nvidia nvidia_modeset nvidia_uvm nvidia_drm "
EOF
mkdir -p /usr/lib/modprobe.d
cat >/usr/lib/modprobe.d/officium-nvidia.conf <<'EOF'
blacklist nouveau
options nouveau modeset=0
EOF
systemctl enable nvidia-persistenced.service||true
systemctl enable nvidia-container-toolkit.service||true
if [[ -f /usr/share/selinux/packages/nvidia-container.pp ]];then
semodule --install /usr/share/selinux/packages/nvidia-container.pp||true
fi
rm -f /etc/yum.repos.d/rpmfusion-*.repo
rm -f /etc/yum.repos.d/nvidia-container-toolkit.repo
