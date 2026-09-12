#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"

echo "Running cyan build..."
cyan build

echo "Runnning luarocks make..."
luarocks make

echo "Running amalg.lua..."
cd build
amalg.lua -a -o ../tested_core.lua -s tested.lua \
tested.assert_table \
tested.libs.ansicolors \
tested.libs.inspect \
tested.libs.shared \
tested.libs.tadd \
tested.results.plain \
tested.results.tap \
tested.results.terminal

cat ../scripts/header.lua ../tested_core.lua > ../tested_core.tmp.lua
mv ../tested_core.tmp.lua ../tested_core.lua

echo "Done!"