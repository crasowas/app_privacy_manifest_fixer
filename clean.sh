#!/bin/bash

# Copyright (c) 2025, crasowas.
#
# Use of this source code is governed by a MIT-style license
# that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

set -e

target_paths=("Build")

echo "Cleaning..."

deleted_anything=false

for path in "${target_paths[@]}"; do
    if [ -e "$path" ]; then
        echo "Removing $path..."
        rm -rf "./$path"
        deleted_anything=true
    fi
done

if [ "$deleted_anything" == true ]; then
    echo "Cleanup completed."
else
    echo "Nothing to clean."
fi
