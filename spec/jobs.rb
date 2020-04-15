class NoThresholdWork
  include Hutch::Consumer
  include Hutch::Enqueue
  
  consume 'nothreshold'
  
  def process(message)
    puts "NoThresholdWork: #{Time.now.to_f} message: #{message.body}"
  end
end

class LoadWork
  include Hutch::Consumer
  include Hutch::Enqueue
  
  consume 'load'
  threshold rate: 3, interval: 1
  
  def process(message)
    puts "LoadWork: #{Time.now.to_f} message: #{message.body}"
  end
end

class LoadWork2
  include Hutch::Consumer
  include Hutch::Enqueue
  
  consume 'load2'
  threshold -> { { context: 'get_report', rate: 2, interval: 2 } }
  
  def process(message)
    puts "LoadWork2: #{Time.now.to_f} message: #{message.body}"
  end
end
