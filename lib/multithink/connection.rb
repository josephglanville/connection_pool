require 'thread'
require 'timeout'
require 'rethinkdb'

include RethinkDB::Shortcuts

class MultiThink::Connection

  DEFAULTS = {retries: 10}

  def initialize(servers, options = {})
    @servers = servers
    options = DEFAULTS.merge(options)
    @retries = options.fetch(:retries)
    connect
  end

  def connect
    # TODO try all servers until we get a connection
    options = @servers.first
    begin
      @conn = r.connect(options)
    rescue
      @tried ||= 0
      sleep 1
      retry if (@tried += 1) < @retries
    end
  end

  def run(query)
    # TODO handle connection failure
    begin
      query.run(@conn)
    rescue RuntimeError => e
      reconnect
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
