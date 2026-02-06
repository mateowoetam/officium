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
        # 1. Install build tools, Kernel headers, and SELinux support
        dnf5 -y install \
            gcc-c++ \
            kernel-devel \
            kernel-headers \
            selinux-policy-targeted \
            selinux-policy-devel \
            akmods; \
        \
        # 2. Enable Terra NVIDIA repo
        dnf5 -y install --enablerepo=terra terra-release-nvidia; \
        \
        # 3. Install drivers and toolkit
        dnf5 -y install \
            --enablerepo=terra-nvidia \
            --enablerepo=terra \
            akmod-nvidia \
            nvidia-driver \
            nvidia-driver-cuda \
            libnvidia-fbc \
            libva-nvidia-driver \
            nvidia-modprobe \
            nvidia-persistenced \
            nvidia-settings \
            nvidia-container-toolkit; \
        \
        # 4. TRIGGER KERNEL MODULE BUILD (Crucial part from nvidia-post.sh)
        # Find the specific kernel version installed in the image
        KERNEL_VERSION="$(find "/usr/lib/modules" -maxdepth 1 -type d ! -path "/usr/lib/modules" -exec basename '{}' ';' | sort | tail -n 1)"; \
        mkdir -p /var/tmp /var/log/akmods /run/akmods; \
        chmod 1777 /var/tmp; \
        # Force akmods to build the nvidia .ko files right now
        akmods --force --kernels "${KERNEL_VERSION}" --kmod "nvidia"; \
        \
        # 5. CONFIGURE BOOT AND DRIVERS (Blacklisting Nouveau)
        mkdir -p /usr/lib/modprobe.d /usr/lib/bootc/kargs.d; \
        echo "blacklist nouveau\nblacklist nova-core\noptions nouveau modeset=0" > /usr/lib/modprobe.d/00-nouveau-blacklist.conf; \
        \
        # Add bootc kernel arguments for the driver
        echo 'kargs = ["rd.driver.blacklist=nouveau", "modprobe.blacklist=nouveau", "nvidia-drm.modeset=1"]' > /usr/lib/bootc/kargs.d/00-nvidia.toml; \
        \
        # 6. CDI Generation Service (for containers)
        printf "[Unit]\nDescription=nvidia container toolkit CDI auto-generation\nAfter=local-fs.target\n\n[Service]\nType=oneshot\nExecStart=/usr/bin/nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml\n\n[Install]\nWantedBy=multi-user.target\n" > /usr/lib/systemd/system/nvctk-cdi.service; \
        systemctl enable nvctk-cdi.service; \
        \
        # 7. Cleanup
        dnf5 config-manager setopt terra-nvidia.enabled=0; \
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
