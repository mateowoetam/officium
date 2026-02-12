#!/usr/bin/env bash
sed -i 's/^NAME=.*/NAME="Fedora (Officium)"/' /etc/os-release
sed -i 's/^PRETTY_NAME=.*/PRETTY_NAME="Fedora (Officium))"/' /etc/os-release
