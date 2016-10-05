#/bin/bash

set -ex

#docker pull docker.gocd.cf-app.com:5000/pong-matcher-acceptance || true
docker build $DOCKER_BUILD_OPTS -t pong-matcher-acceptance .
#docker push docker.gocd.cf-app.com:5000/pong-matcher-acceptance
docker run --name "acceptance" --rm -e "HOST=$HOST" pong-matcher-acceptance
