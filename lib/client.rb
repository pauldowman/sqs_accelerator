require "net/http"

require "#{File.dirname(__FILE__)}/sqs_accelerator"

class SqsAccelerator::Client
  def initialize(aws_access_key_id, aws_secret_access_key)
    @aws_access_key_id, @aws_secret_access_key = aws_access_key_id, aws_secret_access_key
  end
  
  def create_queue(queue_name, visibility_timeout = nil)
    form_data = {'queue_name' => queue_name}
    form_data['visibility_timeout'] = visibility_timeout if visibility_timeout
    post_request("http://localhost:9292/queues", form_data)
  end
  
  def send_message(queue_name, message_body)
    post_request("http://localhost:9292/queues/#{queue_name}", 'message_body' => message_body)
  end
  
  protected
  
  def post_request(url, form_data)
    url = URI.parse(url)
    req = Net::HTTP::Post.new(url.path)
    req.basic_auth @aws_access_key_id, @aws_secret_access_key
    req.set_form_data(form_data, ';')
    response = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
    unless response.is_a? Net::HTTPSuccess
      raise SqsAccelerator::HttpError.new("#{response.code} #{response.message}")
    end
    return response
  end
end

class SqsAccelerator::HttpError < Exception
end
