#/bin/bash

set -ex

docker run -e "HOST=$HOST" camelpunch/pong-matcher-acceptance
