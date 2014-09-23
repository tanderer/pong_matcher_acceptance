#/bin/bash

set -ex

docker build -t andrewbruce/pongrubyacceptance .
docker run andrewbruce/pongrubyacceptance
