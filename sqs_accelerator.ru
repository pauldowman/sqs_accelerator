#!/usr/bin/env rackup -Ilib:../lib -s thin

require "#{File.dirname(__FILE__)}/lib/server"

run SqsAccelerator::Server.new
