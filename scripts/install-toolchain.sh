#!/bin/bash
# Roblox/Luau toolchain for Linux x86_64, pinned versions, into /usr/local/bin.
set -euo pipefail
G=https://github.com
T=$(mktemp -d)
get() {
  [ -x "/usr/local/bin/$1" ] && return 0
  curl -fsSL --retry 3 -o "$T/$1.zip" "$2"
  unzip -qo "$T/$1.zip" -d "$T/$1"
  install -m 0755 "$(find "$T/$1" -type f -name "$1" | head -1)" "/usr/local/bin/$1"
}
get rojo     $G/rojo-rbx/rojo/releases/download/v7.6.1/rojo-7.6.1-linux-x86_64.zip
get wally    $G/UpliftGames/wally/releases/download/v0.3.2/wally-v0.3.2-linux.zip
get stylua   $G/JohnnyMorganz/StyLua/releases/download/v2.0.0/stylua-linux-x86_64.zip
get selene   $G/Kampfkarren/selene/releases/download/0.27.0/selene-0.27.0-linux.zip
get lune     $G/lune-org/lune/releases/download/v0.11.1/lune-0.11.1-linux-x86_64.zip
get luau-lsp $G/JohnnyMorganz/luau-lsp/releases/download/1.70.1/luau-lsp-linux-x86_64.zip
rm -rf "$T"
