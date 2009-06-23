#!/usr/bin/env rackup -Ilib:../lib -s thin

require 'lib/sqs_accelerator'

run SqsAccelerator::Server.new
