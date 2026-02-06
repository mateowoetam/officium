#!/usr/bin/env bash
set -euxo pipefail
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
flatpak --system install -y --noninteractive flathub \
io.github.kolunmi.Bazaar \
io.github.flattool.Warehouse \
com.belmoussaoui.Authenticator \
org.libreoffice.LibreOffice \
com.nextcloud.desktopclient.nextcloud \
org.localsend.localsend_app \
org.kde.elisa \
org.videolan.VLC||true
flatpak --system uninstall --unused -y||true
