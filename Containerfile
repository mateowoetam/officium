# Use an ARG for the base image, provided by the CI/CD pipeline
ARG BASE_IMAGE

# -----------------------------------------------------------------------------
# Build context
# -----------------------------------------------------------------------------
FROM scratch AS ctx
COPY build_files/ /

# -----------------------------------------------------------------------------
# Base image (Kinoite-Main)
# -----------------------------------------------------------------------------
FROM ${BASE_IMAGE} AS final

ARG VARIANT
ARG IMAGE_NAME

LABEL \
    org.opencontainers.image.title="${IMAGE_NAME}" \
    org.opencontainers.image.description="Officium OS (${VARIANT})" \
    org.opencontainers.image.variant="${VARIANT}" \
    org.opencontainers.image.source="https://github.com/mateowoetam/officium" \
    org.opencontainers.image.licenses="AGPL-3.0 license"

# Prepare directories
RUN rm -rf /opt && mkdir -p /opt


# -----------------------------------------------------------------------------
# BUILD PHASE
# -----------------------------------------------------------------------------
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,target=/var/cache \
    --mount=type=cache,target=/var/cache/dnf \
    --mount=type=cache,target=/var/lib/dnf \
    --mount=type=cache,target=/var/log \
    --mount=type=tmpfs,target=/tmp \
    set -eux; \
    \
    # Run common scripts
    for script in rpms.sh flatpak.sh system-config.sh services.sh custom.sh; do \
        if [ -f "/ctx/$script" ]; then \
            install -m755 "/ctx/$script" "/tmp/$script"; \
            bash "/tmp/$script"; \
        fi; \
    done

# -----------------------------------------------------------------------------
# NVIDIA INSTALL (Conditional)
# -----------------------------------------------------------------------------
RUN set -eux; \
    if [ "$VARIANT" = "nvidia" ]; then \
        # 1. Install RPM Fusion Repositories (Step 1 of your guide)
        dnf5 -y install \
            https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
            https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm; \
        \
        # 2. Install Build Tools & Secure Boot Signing Tools (Step 2 of your guide)
        dnf5 -y install akmods kmodtool mokutil openssl gcc-c++ kernel-devel kernel-headers; \
        \
        # 3. Generate Secure Boot Key (Automated)
        # This replaces the manual 'kmodgenca' step.
        kmodgenca --force; \
        \
        # 4. Install the Drivers (Step 3 of your guide)
        dnf5 -y install akmod-nvidia xorg-x11-drv-nvidia-cuda; \
        \
        # 5. Force the build immediately
        # We manually find the kernel version to ensure we build for the image's kernel, not the runner's kernel.
        KERNEL_VERSION="$(find /usr/lib/modules -maxdepth 1 -type d ! -path /usr/lib/modules -exec basename '{}' ';' | head -n 1)"; \
        akmods --force --kernels "${KERNEL_VERSION}"; \
        \
        # 6. Apply Blacklist & Bootc Kargs (Crucial for bootc images)
        # This replaces manual 'grubby' commands with persistent configuration files.
        mkdir -p /usr/lib/modprobe.d /usr/lib/bootc/kargs.d; \
        \
        # Blacklist the open-source nouveau driver
        echo -e "blacklist nouveau\noptions nouveau modeset=0" > /usr/lib/modprobe.d/00-nouveau-blacklist.conf; \
        \
        # Force nvidia-modeset for better laptop/PRIME compatibility
        echo "options nvidia-drm modeset=1" > /usr/lib/modprobe.d/nvidia-modeset.conf; \
        \
        # Set persistent Bootc Kernel Arguments (replaces grubby --update-kernel)
        echo 'kargs = ["rd.driver.blacklist=nouveau", "modprobe.blacklist=nouveau", "nvidia-drm.modeset=1"]' > /usr/lib/bootc/kargs.d/00-nvidia.toml; \
        \
        dnf5 clean all; \
    fi
# -----------------------------------------------------------------------------
# System files
# -----------------------------------------------------------------------------
COPY system_files /

# Wallpaper
RUN set -eux; \
    mkdir -p /usr/share/backgrounds; \
    ln -sf /usr/share/wallpapers/Deseret/contents/images/4240x2832.jxl /usr/share/backgrounds/default.jxl; \
    ln -sf /usr/share/wallpapers/Deseret/contents/images/4240x2832.jxl /usr/share/backgrounds/default-dark.jxl

# Bootc validation
RUN bootc container lint
