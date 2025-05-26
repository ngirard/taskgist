#!/usr/bin/env bash

set -e

PREFIX="/usr"
PROJNAME="taskgist"

# Eget
#   Easily install prebuilt binaries from GitHub
#   https://github.com/zyedidia/eget
curl https://zyedidia.github.io/eget.sh | sh && { f=eget; sudo install $f "${PREFIX}/bin" && rm $f; }

# Just
#   Just a command runner
#   https://github.com/casey/just
#   Config: no
sudo eget -a x86_64 -a musl casey/just --to="${PREFIX}/bin"

(just sync && just baml-generate || exit 1)
