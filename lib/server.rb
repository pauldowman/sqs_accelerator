require "em-http"
require "sqs_helper"
require "sqs_proxy"
require "xml"

class SqsAccelerator::Server < Sinatra::Base  
  register Sinatra::Async
  
  configure do 
    # TODO fix logging.
    LOGGER = Logger.new(STDOUT)
    LOGGER.level = Logger::DEBUG
    use Rack::CommonLogger, LOGGER
  end
  
  # use http basic auth to get aws_access_key_id and aws_secret_access_key
  helpers do
    include SqsAccelerator::SqsHelper

    def deny
      response['WWW-Authenticate'] = %(Basic realm="SQS Accelerator - use SQS credentials")
      response.status = 401 # "Unauthorized": http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html
      body "Please provide the SQS access key id and secret access key as the userid and password.\n"
    end

    def authorized?
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? && @auth.basic? && @auth.credentials
      # We don't care what the credentials are, we'll just pass them on to SQS
    end
    
    def aws_access_key_id
      @auth.credentials[0]
    end
    
    def aws_secret_access_key
      @auth.credentials[1]
    end
    
    def logger
      LOGGER
    end
  end
  
  aget '/' do
    body haml :home
  end
  
  aget '/queues' do
    deny and return unless authorized?
    
    request_hash = generate_request_hash('ListQueues')
    http = EventMachine::HttpRequest.new("http://queue.amazonaws.com/").get :query => request_hash, :timeout => 120
    
    http.callback {
      queue_urls = []
      doc = parse_response(http.response)
      doc.find('//sqs:QueueUrl').each do |u|
        queue_urls << u.content.strip
      end
      
      body haml :all_queues, :locals => { :queue_urls => queue_urls }
    }
    
    http.errback {
      # TODO a decent log message and error page here
      logger.debug "fail"
      body "fail"
    }
    
  end
  
  # Create a queue
  apost '/queues' do
    deny and return unless authorized?

    queue_name = params[:queue_name]
    visibility_timeout = params[:visibility_timeout]
    
    # TODO switch to using evented client
    operation = proc do
      sqs = SqsAccelerator::SqsProxy.new(aws_access_key_id, aws_secret_access_key, :logger => logger)
      sqs.create_queue(queue_name, visibility_timeout)
      redirect "/queues/#{queue_name}"
    end
    EM.defer(operation)    
  end
  
  # Get info on a queue. Doesn't create the queue if it doesn't exist
  aget '/queues/:queue_name' do
    deny and return unless authorized?
  
    queue_name = params[:queue_name]
  
    # TODO switch to using evented client
    operation = proc do          
      sqs = SqsAccelerator::SqsProxy.new(aws_access_key_id, aws_secret_access_key, :logger => logger)
      queue_info = sqs.get_queue_info(queue_name)
      body haml :queue_info, :locals => { :queue_name => queue_name, :queue_info => queue_info }
    end
    EM.defer(operation)
  end
  
  # Send a new message on a queue. Returns immediately and sends message asynchronously
  apost '/queues/:queue_name' do
    deny and return unless authorized?

    queue_name = params[:queue_name]
    message_body = params[:message_body]
    
    logger.info "Received message for queue #{queue_name}"
    logger.debug "message_body: #{message_body}"
    
    # TODO check that chars are allowed by SQS: #x9 | #xA | #xD | [#x20 to #xD7FF] | [#xE000 to #xFFFD] | [#x10000 to #x10FFFF]
    # TODO deal with unicode, where chars != bytes
    if message_body.size > SqsAccelerator::SqsHelper::MAX_MESSAGE_SIZE
      logger.error "Message is too large, rejecting."
      response.status = 413 # "Request Entity Too Large": http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html
      body "Message must be less than SqsAccelerator::SqsHelper::MAX_MESSAGE_SIZE bytes"
      return
    end
    
    # Messaage seems to be OK, return a response immediately then send message to SQS
    body "Message will be queued, check log for errors.\n"
    
    request_hash = generate_request_hash("SendMessage", :message => message_body)
    # build the body string ourselves for now until Ilya's gem gets updated because of the content-length bug
    request_body = request_hash.to_a.collect{|key,val| CGI.escape(key.to_s) + "=" + CGI.escape(val.to_s) }.join("&")
    http = EventMachine::HttpRequest.new("http://queue.amazonaws.com/#{queue_name}").post({:body => request_body, :head => {"Content-Type" => "application/x-www-form-urlencoded"}})
    
    http.callback {
      doc = parse_response(http.response)
      id_el = doc.find_first('//sqs:MessageId')
      md5_el = doc.find_first('//sqs:MD5OfMessageBody')
      if id_el && md5_el
        message_id = id_el.content.strip
        checksum = md5_el.content.strip
        # TODO check md5
        # TODO a decent log message here
        logger.info "Queued message, SQS message id is: #{message_id}"
      else
        logger.error "SQS returned an error response"
        # TODO parse the response and print something useful
        # TODO retry a few times with exponentially increasing delay
      end
    }
    
    http.errback {
      # TODO a decent log message here
      logger.error "fail"
      # TODO dump the message to a temp file and write a utility to re-send dumped messages
    }
    
  end
end
