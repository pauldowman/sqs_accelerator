SQS Accelerator
===============

[http://github.com/pauldowman/sqs_accelerator](http://github.com/pauldowman/sqs_accelerator)

WARNING: this is totally experimental right now! It's just an idea I'm playing with and I'm trying to see if it works. (But please try it out and tell me what you think!)

This is a simple evented server (using [Event Machine](http://eventmachine.rubyforge.org)) that proxies requests to Amazon's [Simple Queue Service](http://aws.amazon.com/sqs/) hosted queue. It's purpose is to queue messages very quickly, because otherwise SQS is too slow to use from within a web app (to be precise, the time it takes to queue a message is often too long).

It provides a simple RESTful interface for interacting with SQS that's also convenient to use from a browser.

One instance of the SQS Accelerator can send messages to any number of SQS queues, the queue name is given in the URL and the AWS credentials are given in HTTP headers (as HTTP Basic Authentication headers actually so it's convenient to use from a browser)


How it works
------------

The SQS Accelerator accepts messages from your web app and returns a response instantly without waiting for a response from SQS. Your web app then happily continues and returns it's response to the user. The SQS Accelerator finishes queueing the message to SQS in the background.

It runs as a daemon, if it's accepting queued messages from a web app one instance should be run on each app server. It listens on port 9292.


FAQ
------

Q: Won't lots of messages build up inside SQS Accelerator since it receives them faster than it sends them to SQS?

_A: No, but you might get errors if you hit the maximum number of open connections (not sure what this limit is yet, but it should be very high with EventMachine). SQS has high latency, but it can accept a virtually unlimited number of incoming connections, so if you can hold a large number of open connections to it then your throughput can be very high. Because an evented client can hold a large number of open connections it can maintain a very high throughput._

Q: Isn't this like queueing messages locally before queueing them in SQS?

_A: No, it's more like a proxy than a queue, the messages don't build up inside SQS Accelerator, they are all being sent to SQS concurrently._ 

Q: Why not just use a local queue?

_A: You could do that instead of using SQS. But SQS is simple and scalable, and it's also simple and scalable to run an instance of SQS Accelerator on each app server._

Q: Are you sure about all this?

_A: Not yet, it's just a theory so far, my next priority is to benchmark this and make sure it really works as it should in theory._


Usage instructions
------------------

* Install this gem
* Run sqs_accelerator.ru
* Hit [http://localhost:9292/](http://localhost:9292/) in a browser
* TODO improve this


Thanks to the following great projects
--------------------------------------

* [Event Machine](http://eventmachine.rubyforge.org), the thing that makes this even possible.
* [async_sinatra](http://github.com/raggi/async_sinatra), allows writing evented HTTP servers using the nice Sinatra framework/DSL.
* [em-http-request](http://github.com/igrigorik/em-http-request), an asynchronous HTTP Client.
* [RightAWS](http://rightscale.rubyforge.org/right_aws_gem_doc) (I stole a few lines of the SQS code).
* [Amazon SQS](http://aws.amazon.com/sqs/) for having a decent [Query API](http://docs.amazonwebservices.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/), even if it's not actually RESTful. :-)


Still to do
-----

* Find all the TODO comments in the code
* Benchmarking
* A command to start and stop the daemon, maybe a [god](http://god.rubyforge.org/) config file
* Use SSL when connecting to SQS to protect message content (AWS credentials are never sent, they're just used to sign the message)
* Unit tests (I'm just trying to figure out if this idea even works first)
* Create a Ruby client library
* Switch all actions to use evented HTTP client instead of EM.defer. Right now some actions are using EM.defer to use the RightAWS client in a thread. These actions will be less scalable. Sending messages, the most important action, _is_ using the evented client. This means making direct HTTP requests to the [SQS Query API]
* Fix bugs and make it nicer.
* Refactor all the SQS stuff out of the actions
* Some configuration options

