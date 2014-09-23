#/bin/bash

set -ex

chruby 2.1.2
bundle
ruby pong_matcher_acceptance_test.rb
