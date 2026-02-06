#!/usr/bin/env bash
set -euo pipefail
echo "[INFO] Installing NVIDIA stack for immutable bootc image..."
FRELEASE="$(rpm -E %fedora)"
echo "[INFO] Adding RPM Fusion repositories..."
dnf5 install -y \
"https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$FRELEASE.noarch.rpm" \
"https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$FRELEASE.noarch.rpm"
echo "[INFO] Adding NVIDIA container toolkit repository..."
curl -fsSL https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo \
-o /etc/yum.repos.d/nvidia-container-toolkit.repo
echo "[INFO] Refreshing metadata..."
dnf5 -y makecache
echo "[INFO] Installing NVIDIA driver packages..."
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
echo "[INFO] Configuring dracut NVIDIA module loading..."
mkdir -p /usr/lib/dracut.conf.d
cat >/usr/lib/dracut.conf.d/10-nvidia.conf <<'EOF'
add_drivers+=" nvidia nvidia_modeset nvidia_uvm nvidia_drm "
EOF
echo "[INFO] Blacklisting nouveau..."
mkdir -p /usr/lib/modprobe.d
cat >/usr/lib/modprobe.d/officium-nvidia.conf <<'EOF'
blacklist nouveau
options nouveau modeset=0
EOF
echo "[INFO] Enabling NVIDIA services..."
systemctl enable nvidia-persistenced.service||true
systemctl enable nvidia-container-toolkit.service||true
if [[ -f /usr/share/selinux/packages/nvidia-container.pp ]];then
echo "[INFO] Installing NVIDIA SELinux module..."
semodule --install /usr/share/selinux/packages/nvidia-container.pp||true
fi
echo "[INFO] Removing temporary repositories..."
rm -f /etc/yum.repos.d/rpmfusion-*.repo
rm -f /etc/yum.repos.d/nvidia-container-toolkit.repo
echo "[INFO] Cleaning package metadata..."
dnf5 clean all
rm -rf /var/cache/dnf /var/cache/yum /var/tmp/*
echo "[INFO] NVIDIA stack installation complete."
