require 'thread'
require 'timeout'
require 'rethinkdb'

include RethinkDB::Shortcuts

class MultiThink::Connection

  DEFAULTS = {
    retries: 10,
    retry_interval: 1,
    conn_timeout: 1
  }

  def initialize(options = {})
    options = DEFAULTS.merge(options)
    @servers = options.fetch(:servers)
    @retries = options.fetch(:retries)
    @retry_interval = options.fetch(:retry_interval)
    @conn_timeout = options.fetch(:conn_timeout)
    connect
  end

  def connect
    @tried = 0
    while @tried < @retries do
      @servers.each do |server|
        begin
          #TODO(jpg) make timeout configurable
          Timeout::timeout(@conn_timeout) do
            @conn = r.connect(server)
          end
          return true
        rescue
          sleep @retry_interval
        end
        @tried += 1
      end
    end
    # If we got here we couldn't get a connection. :(
    raise "Error: Reached maximum retries (#{@retries})"
  end

  def run(query, *args)
    begin
      query.run(@conn, *args)
    rescue StandardError => e
      if is_connection_error(e)
        retry if reconnect
      end
    end
  end

  def is_connection_error(e)
    case e
    when Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::EPIPE,
      Errno::ECONNRESET, Errno::ETIMEDOUT, IOError
      true
    when RethinkDB::RqlRuntimeError
      e.message =~ /cannot perform (read|write): No master available/ ||
      e.message =~ /Error: Connection Closed/
    else
      false
    end
  end

  def reconnect
    begin
      # try fast path first
      @conn.reconnect
    rescue
      # if that fails then try get a new connection
      connect
    end
  end

end
