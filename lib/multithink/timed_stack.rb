require 'thread'
require 'timeout'
require_relative 'connection'

class MultiThink::PoolShuttingDownError < RuntimeError; end

class MultiThink::TimedStack

  def initialize(size = 0, options)
    @size = size
    @options = options
    @que = []
    @checked_out = []
    @mutex = Mutex.new
    @resource = ConditionVariable.new
    @shutdown_block = nil
  end

  def push(obj)
    @mutex.synchronize do
      if @shutdown_block
        @shutdown_block.call(obj)
      else
        @que.push obj
        @checked_out.delete obj
      end

      @resource.broadcast
    end
  end
  alias_method :<<, :push

  def available?
    @que.count + @checked_out.count < @size
  end

  def pop(timeout=0.5)
    deadline = Time.now + timeout
    @mutex.synchronize do
      loop do
        raise PoolShuttingDownError if @shutdown_block
        return @que.pop unless @que.empty?
        if available?
          new_conn = MultiThink::Connection.new(@options)
          @checked_out << new_conn
          return new_conn
        end
        to_wait = deadline - Time.now
        raise Timeout::Error, "Waited #{timeout} sec" if to_wait <= 0
        @resource.wait(@mutex, to_wait)
      end
    end
  end

  def shutdown(&block)
    raise ArgumentError, "shutdown must receive a block" unless block_given?

    @mutex.synchronize do
      @shutdown_block = block
      @resource.broadcast

      @que.size.times do
        conn = @que.pop
        block.call(conn)
      end
    end
  end

  def empty?
    @que.empty?
  end

  def length
    @que.length
  end
end
