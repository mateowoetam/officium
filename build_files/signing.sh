#!/usr/bin/env bash
set -euo pipefail
CONTAINER_DIR="/usr/etc/containers"
ETC_CONTAINER_DIR="/etc/containers"
SIGNING_DIR="/ctx/modules/signing"
COSIGN_KEY="/ctx/cosign.pub"
IMAGE_REGISTRY="${IMAGE_REGISTRY:?IMAGE_REGISTRY not set}"
IMAGE_NAME="${IMAGE_NAME:?IMAGE_NAME not set}"
IMAGE_REGISTRY_TITLE="$(echo "$IMAGE_REGISTRY"|cut -d'/' -f2-)"
echo "==> Configuring container signing"
echo "==> Image: $IMAGE_NAME"
echo "==> Registry: $IMAGE_REGISTRY"
mkdir -p \
"$CONTAINER_DIR/registries.d" \
"$ETC_CONTAINER_DIR/registries.d" \
/usr/etc/pki/containers \
/etc/pki/containers
install -m644 "$SIGNING_DIR/policy.json" \
"$CONTAINER_DIR/policy.json"
install -m644 "$SIGNING_DIR/policy.json" \
"$ETC_CONTAINER_DIR/policy.json"
jq \
--arg image_registry "$IMAGE_REGISTRY" \
--arg image_registry_title "$IMAGE_REGISTRY_TITLE" \
'.transports.docker |=
   { $image_registry: [
     {
       "type": "sigstoreSigned",
       "keyPaths": [
         ("/usr/etc/pki/containers/" + $image_registry_title + ".pub")
       ],
       "signedIdentity": { "type": "matchRepository" }
     }
   ] } + .' \
"$CONTAINER_DIR/policy.json" >/tmp/policy.json
install -m644 /tmp/policy.json "$CONTAINER_DIR/policy.json"
install -m644 /tmp/policy.json "$ETC_CONTAINER_DIR/policy.json"
rm -f /tmp/policy.json
sed \
"s|ghcr.io/IMAGENAME|$IMAGE_REGISTRY|g" \
"$SIGNING_DIR/registry-config.yml" > \
/tmp/registry.yaml
install -m644 /tmp/registry.yaml \
"$CONTAINER_DIR/registries.d/$IMAGE_REGISTRY_TITLE.yaml"
install -m644 /tmp/registry.yaml \
"$ETC_CONTAINER_DIR/registries.d/$IMAGE_REGISTRY_TITLE.yaml"
rm -f /tmp/registry.yaml
install -m644 "$COSIGN_KEY" \
"/usr/etc/pki/containers/$IMAGE_REGISTRY_TITLE.pub"
