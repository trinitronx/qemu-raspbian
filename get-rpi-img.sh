#!/bin/bash

set -o errexit
set -o nounset

wget "$IMG_URL"
echo "Uncompressing image..." >&2
unxz "${IMG_URL##*/}"
