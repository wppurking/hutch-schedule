class NoThresholdWork
  include Hutch::Consumer
  include Hutch::Enqueue
  
  consume 'nothreshold'
  
  def process(message)
    puts "NoThresholdWork: #{Time.now.to_f} message: #{message.body}"
  end
end

class NoArgsWork
  include Hutch::Consumer
  include Hutch::Enqueue
  
  consume 'noargs'
  
  def process
    puts "NoArgsWork: #{Time.now.to_f}"
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
  threshold ->(msg) { CONTEXTS[msg[:b]] }
  
  CONTEXTS = [
    # { context: 'get_report0', rate: 1, interval: 1 },
    # { context: 'get_report1', rate: 1, interval: 1 },
    # { context: 'get_report2', rate: 1, interval: 1 },
    # { context: 'get_report3', rate: 1, interval: 1 },
    # { context: 'get_report4', rate: 1, interval: 1 },
    # { context: 'get_report5', rate: 1, interval: 1 },
    # { context: 'get_report6', rate: 5, interval: 1 },
    # { context: 'get_report7', rate: 10, interval: 1 },
    { context: 'get_report8', rate: 10, interval: 1 },
    { context: 'get_report9', rate: 1, interval: 30 }
  ]
  
  def process(message)
    puts "#{Thread.current.name} - LoadWork2: #{Time.now.to_f} message: #{message.body}"
  end
end
