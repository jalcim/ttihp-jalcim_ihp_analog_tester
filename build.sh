#!/usr/bin/env bash
set -euo pipefail

IP_DIR="ip/adder_4b"
MACRO_RUN_DIR="librelane/runs"

echo "=== Etape 1 : PnR hard macro adder_4b ==="
librelane librelane/config.yaml

# Trouver le dernier run
LAST_RUN=$(ls -td "$MACRO_RUN_DIR"/RUN_* | head -1)
echo "Run macro : $LAST_RUN"

# Copier les artefacts dans ip/
mkdir -p "$IP_DIR"
cp "$LAST_RUN/final/gds/adder_4b.gds" "$IP_DIR/"
cp "$LAST_RUN/final/lef/adder_4b.lef" "$IP_DIR/"
for lib in "$LAST_RUN"/final/lib/*/adder_4b__*.lib; do
    cp "$lib" "$IP_DIR/"
done

echo "=== Artefacts macro copies dans $IP_DIR ==="
ls -lh "$IP_DIR"

echo "=== Etape 2 : PnR top-level TT ==="
librelane librelane/config_top.yaml

echo "=== Build termine ==="
