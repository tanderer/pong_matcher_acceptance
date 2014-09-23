#/bin/bash

set -ex

docker build -t andrewbruce/pongrubyacceptance .
docker run -e "HOST=$HOST" andrewbruce/pongrubyacceptance
