#!/usr/bin/env bash
set -eu
flatpak remote-add --if-not-exists \
flathub https://dl.flathub.org/repo/flathub.flatpakrepo
for app in \
org.fkoehler.KTailctl \
org.deskflow.deskflow \
org.gnome.DejaDup \
org.kde.haruna \
org.mozilla.Thunderbird \
org.mozilla.firefox;do
if flatpak info "$app" >/dev/null 2>&1;then
flatpak remove -y "$app"
fi
done
flatpak install -y --noninteractive flathub \
io.github.kolunmi.Bazaar \
io.github.flattool.Warehouse \
com.belmoussaoui.Authenticator \
org.libreoffice.LibreOffice \
com.nextcloud.desktopclient.nextcloud \
org.localsend.localsend_app \
app.comaps.comaps \
org.kde.elisa \
org.videolan.VLC
flatpak uninstall --unused -y||true
