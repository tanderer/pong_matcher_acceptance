#/bin/bash

set -ex

docker pull docker.gocd.cf-app.com:5000/pong-matcher-acceptance || true
docker build $DOCKER_BUILD_OPTS -t docker.gocd.cf-app.com:5000/pong-matcher-acceptance .
docker push docker.gocd.cf-app.com:5000/pong-matcher-acceptance
docker run -e "HOST=$HOST" docker.gocd.cf-app.com:5000/pong-matcher-acceptance
