require 'thread'
require 'timeout'
require 'rethinkdb'

include RethinkDB::Shortcuts

class MultiThink::Connection

  def initialize(servers)
    @servers = servers
    connect
  end

  def connect
    # TODO try all servers until we get a connection
    options = @servers.first
    @conn = r.connect(options)
  end

  def run(query)
    # TODO handle connection failure
    query.run(@conn)
  end

end
