require "right_aws"

# This class will be removed. It's just for the operations that haven't been 
# switched to use the evented http client yet.

class SqsAccelerator::SqsProxy

  def initialize(aws_access_key_id, aws_secret_access_key, options = {})
    options = {:multi_thread => true}.merge(options)
    @logger = options[:logger]
    @sqs = RightAws::SqsGen2.new(aws_access_key_id, aws_secret_access_key, options)
  end
  
  def create_queue(queue_name, visibility_timeout)
    RightAws::SqsGen2::Queue.create(@sqs, queue_name, true, visibility_timeout)
  end
  
  def get_queue_info(queue_name)
    # TODO do something smart if the queue doesn't exist
    queue = @sqs.queue(queue_name, false)
    queue_info = {
      :num_messages => queue.size,
      :visibility_timeout => queue.visibility
    }
    return queue_info
  end
end