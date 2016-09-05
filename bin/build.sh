#!/bin/bash

set -euo pipefail

# Install dependencies
carton install --deployment

# Syntax check
for SCRIPT in bin/*.pl ; do
  carton exec perl -c $SCRIPT
done

# Perform unittests (yeah right)
# TODO

rm -rf local/cache

mkdir build/artifact
chmod -R ugo=rwX build/

tar vzcf build/artifact/artifact.tar.gz \
  cpanfile* \
  bin/*.pl \
  local/
