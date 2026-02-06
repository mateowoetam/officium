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
        # 1. Install build tools AND SELinux policy support first
        dnf5 -y install \
            gcc-c++ \
            kernel-devel \
            kernel-headers \
            selinux-policy-targeted \
            selinux-policy-devel; \
        \
        # 2. Allow containers to manage cgroups (required for some toolkit versions)
        # We use || true because this can fail in some build environments but shouldn't stop the build
        setsebool -P container_manage_cgroup on || true; \
        \
        # 3. Enable the Terra NVIDIA release repo
        dnf5 -y install --enablerepo=terra terra-release-nvidia; \
        \
        # 4. Install drivers and tools
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
        # 5. Cleanup
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
