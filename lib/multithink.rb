require 'multithink/version'
require 'multithink/timed_stack'

class MultiThink
  DEFAULTS = {size: 5, timeout: 5, servers: [{host: '127.0.0.1', port: 28015}]}

  def initialize(options = {})
    options = DEFAULTS.merge(options)

    @size = options.fetch(:size)
    @timeout = options.fetch(:timeout)
    @servers = options.fetch(:servers)

    @available = TimedStack.new(@size, @servers)
    @key = :"current-#{@available.object_id}"
  end

  def with(options = {})
    conn = checkout(options)
    begin
      yield conn
    ensure
      checkin
    end
  end

  def checkout(options = {})
    stack = ::Thread.current[@key] ||= []

    if stack.empty?
      timeout = options[:timeout] || @timeout
      conn = @available.pop(timeout)
    else
      conn = stack.last
    end

    stack.push conn
    conn
  end

  def checkin
    stack = ::Thread.current[@key]
    conn = stack.pop
    if stack.empty?
      @available << conn
    end
    nil
  end

  def shutdown
    @available.shutdown
  end

end
