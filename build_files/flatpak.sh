#!/usr/bin/env bash
set -euxo pipefail
export FLATPAK_DISABLE_SANDBOX=1
mkdir -p /root/.cache/dconf
flatpak --system remote-add --if-not-exists \
flathub https://dl.flathub.org/repo/flathub.flatpakrepo||true
for app in \
org.fkoehler.KTailctl \
org.deskflow.deskflow \
org.gnome.DejaDup \
org.kde.haruna \
org.mozilla.Thunderbird \
org.mozilla.firefox;do
flatpak --system uninstall -y "$app"||true
done
mkdir -p /etc/flatpak/preinstall.d
cp -r /ctx/custom/flatpaks/*.preinstall /etc/flatpak/preinstall.d/
flatpak --system uninstall --unused -y||true
