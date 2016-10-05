# DOCKER-VERSION 1.2.0

# base
FROM    ubuntu:14.04
RUN     apt-get update
RUN     apt-get install -qy build-essential wget

# create user
RUN     adduser --disabled-password web

# ruby-install
#ADD     https://github.com/postmodern/ruby-install/archive/v0.6.0.tar.gz ruby-#install-0.6.0.tar.gz
RUN     wget https://github.com/postmodern/ruby-install/archive/v0.6.0.tar.gz -O ruby-install-0.6.0.tar.gz
RUN     tar -zxf ruby-install-0.6.0.tar.gz
RUN     cd ruby-install-0.6.0; make install

# ruby
RUN     ruby-install ruby 2.1.2 -- --disable-install-doc
RUN     chown -R web:web /opt/rubies/ruby-2.1.2

# become unprivileged
USER    web

# install bundler
ENV     PATH /opt/rubies/ruby-2.1.2/bin:$PATH
RUN     echo "gem: --no-document" >> /home/web/.gemrc
RUN     gem install bundler

# install as unprivileged user
USER    web
COPY    . pong_matcher_acceptance
RUN     cd pong_matcher_acceptance; bundle

ENTRYPOINT cd pong_matcher_acceptance; ruby pong_matcher_acceptance_test.rb
