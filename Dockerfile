# DOCKER-VERSION 1.2.0

FROM    camelpunch/pong-matcher-base:ruby

# install as unprivileged user
USER    web
COPY    . pong_matcher_acceptance
RUN     cd pong_matcher_acceptance; bundle

ENTRYPOINT cd pong_matcher_acceptance; ruby pong_matcher_acceptance_test.rb
