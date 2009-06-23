#!/usr/bin/env rackup -Ilib:../lib -s thin

require 'lib/server'

run SqsAccelerator::Server.new
