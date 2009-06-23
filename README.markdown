SQS Accelerator
===============

http://github.com/pauldowman/sqs_accelerator

WARNING: this is totally experimental right now! It's just an idea I'm playing with and I'm trying to see if it works. (But please try it out and tell me what you think!)

This is a simple evented server (using [Event Machine](http://eventmachine.rubyforge.org)) that proxies requests to Amazon's Simple Queue Service. It's purpose is to queue messages very quickly, because otherwise SQS is too slow to use from within a web app (to be precise, the time to queue a message is too long).

It provides a simple RESTful interface for interacting with SQS that's also convenient to use from a browser.

One instance of the SQS Accelerator can send messages to any number of SQS queues, the queue name is given in the URL and the AWS credentials are given in HTTP headers (as HTTP Basic Authentication headers actually so it's convenient to use from a browser)


How it works
------------

The SQS Accelerator accepts messages from your web app and returns a response instantly without waiting for a response from SQS. Your web app then happily continues and returns it's response to the user. The SQS Accelerator finishes queueing the message to SQS in the background.

It runs as a daemon, if it's accepting queued messages from a web app one instance should be run on each app server. It listens on port 9292.


FAQ
------

Q: Won't lots of messages build up inside SQS Accelerator since it receives them faster than it sends them to SQS?

A. No, but you might run into . SQS has high latency, but it can accept a virtually unlimited number of incoming connections, so if you can hold a large number of open connections to it then your throughput can be very high. Because an evented client can hold a large number of open connections it can maintain a very high throughput.


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
* [em-http-request](http://github.com/igrigorik/em-http-request), Asynchronous HTTP Client.
* [RightAWS](http://rightscale.rubyforge.org/right_aws_gem_doc) (I stole a few lines of the SQS code).
* [Amazon SQS](http://aws.amazon.com/sqs/) for having a decent [Query API](http://docs.amazonwebservices.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/), even if it's not actually RESTful. :-)


Still to do
-----

* Find all the TODO comments in the code
* A command to start and stop the daemon, maybe a god config file
* Use SSL when connecting to SQS to protect message content (AWS credentials are never sent, they're just used to sign the message)
* Unit tests (I'm just trying to figure out if this idea even works first)
* Switch all actions to use evented HTTP client instead of EM.defer. Right now some actions are using EM.defer to use the RightAWS client in a thread. These actions will be less scalable. Sending messages, the most important action, _is_ using the evented client. This means making direct HTTP requests to the [SQS Query API]
* Fix bugs and make it nicer.
* Refactor all the SQS stuff out of the actions
* Some configuration options

