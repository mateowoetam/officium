# Use an ARG for the base image, provided by the CI/CD pipeline
ARG BASE_IMAGE
# Build context
FROM scratch AS ctx
COPY build_files/ /

# -----------------------------------------------------------------------------
# Base image (Kinoite-Main or Kinoite-Nvidia)
# -----------------------------------------------------------------------------
FROM ${BASE_IMAGE} AS final

# Re-declare ARGs to use them inside this stage
ARG VARIANT
ARG IMAGE_NAME

LABEL \
    org.opencontainers.image.title="${IMAGE_NAME}" \
    org.opencontainers.image.description="Officium OS (${VARIANT})" \
    org.opencontainers.image.variant="${VARIANT}" \
    org.opencontainers.image.source="https://github.com/mateowoetam/officium" \
    org.opencontainers.image.licenses="Apache-2.0"

# Clean up opt and prepare directories
RUN rm -rf /opt && mkdir -p /opt

# BUILD PHASE
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,target=/var/cache \
    --mount=type=cache,target=/var/cache/dnf \
    --mount=type=cache,target=/var/lib/dnf \
    --mount=type=cache,target=/var/log \
    --mount=type=tmpfs,target=/tmp \
    set -eux; \
    \
    # Run common build scripts
    for script in rpms.sh flatpak.sh system-config.sh services.sh custom.sh; do \
        if [ -f "/ctx/$script" ]; then \
            install -m755 "/ctx/$script" "/tmp/$script"; \
            bash "/tmp/$script"; \
        fi; \
    done; \
    \
    # NVIDIA variant stage
    if [ "$VARIANT" = "nvidia" ]; then \
        dnf5 config-manager unsetopt skip_if_unavailable; \
        dnf5 -y remove \
            nvidia-gpu-firmware \
            rocm-hip \
            rocm-opencl \
            rocm-clinfo \
            rocm-smi; \
        \
        dnf5 -y copr enable ublue-os/staging; \
        dnf5 -y install \
            egl-wayland.x86_64 \
            egl-wayland.i686; \
        \
        install -m755 "/ctx/nvidia.sh" "/tmp/nvidia.sh"; \
        bash "/tmp/nvidia.sh"; \
    fi


COPY system_files /

# Set Deseret as default wallpaper
RUN set -eux; \
    mkdir -p /usr/share/backgrounds; \
    ln -sf /usr/share/wallpapers/Deseret/contents/images/4240x2832.jxl /usr/share/backgrounds/default.jxl; \
    ln -sf /usr/share/wallpapers/Deseret/contents/images/4240x2832.jxl /usr/share/backgrounds/default-dark.jxl


# Final health check for bootc compatibility
RUN bootc container lint
