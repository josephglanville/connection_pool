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
    @tried = 0
    while @tried < @retries do
      @servers.each do |server|
        begin
          @conn = r.connect(server)
          return true
        rescue
          sleep 1
        end
        @tried += 1
      end
    end
    # If we got here we couldn't get a connection. :(
    raise RuntimeError "Error: Reached maximum retries (#{@retries})"
  end

  def run(query, *args)
    begin
      query.run(@conn, *args)
    rescue RuntimeError => e
      if reconnect
        retry
      end
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
