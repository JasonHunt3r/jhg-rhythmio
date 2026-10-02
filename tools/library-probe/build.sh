#!/bin/sh
# Builds build/library-probe from probe.swift plus RhythmIOCore's sources.
set -e
cd "$(dirname "$0")/../.."
mkdir -p build
swiftc -O -parse-as-library -module-name RhythmIOCore tools/library-probe/probe.swift \
  Sources/RhythmIOCore/*.swift -lsqlite3 -o build/library-probe
echo "built build/library-probe"
