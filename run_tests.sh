#/bin/bash

set -ex

docker run -e "HOST=$HOST" docker.gocd.cf-app.com:5000/pong-matcher-acceptance
