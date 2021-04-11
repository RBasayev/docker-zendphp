#!/bin/bash

cd "$(dirname "$0")"

rm -f kombined.yaml

# This is to "skip" non-existing files
shopt -s nullglob

# First PVCs, then ConfigMaps, then Services and then Deployments
for def in pvc cfg svc dpl; do
    glb=$def.*.yml
    for f in $glb; do
        echo "   Adding File $f"
        [ -f kombined.yaml ] && echo "---" >> kombined.yaml
        echo "# $f :" >> kombined.yaml
        cat $f >> kombined.yaml
        echo >> kombined.yaml
        echo >> kombined.yaml
    done
done