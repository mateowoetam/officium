#!/usr/bin/env bash
set -euxo pipefail
export FLATPAK_DISABLE_SANDBOX=1
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
flatpak install -y --noninteractive flathub \
io.github.kolunmi.Bazaar \
com.ranfdev.DistroShelf \
io.github.flattool.Warehouse \
com.github.tchx84.Flatseal \
com.belmoussaoui.Authenticator \
org.libreoffice.LibreOffice \
com.nextcloud.desktopclient.nextcloud \
org.localsend.localsend_app \
org.kde.elisa \
org.videolan.VLC
mkdir -p /etc/flatpak/preinstall.d
if compgen -G "/ctx/custom/flatpaks/*.preinstall" >/dev/null;then
cp /ctx/custom/flatpaks/*.preinstall /etc/flatpak/preinstall.d/
fi
flatpak --system uninstall --unused -y||true
