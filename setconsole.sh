#!/usr/bin/env bash

#shellcheck disable=SC2024

sudo cat <<EOF > /etc/vconsole.conf
KEYMAP=us
FONT=ter-v16b
EOF