require 'byebug'
require_relative 'nests'

class Command
  def initialize(logger)
    @logger = logger
  end
end

class HatchCommand < Command
  def initialize(logger)
    super
    @nest = DigitalOceanNest.new
  end

  def run
    @logger.info 'Start nesting'
    host = @nest.get_or_create_host
    ip_address = host.networks.v4[0].ip_address
    puts ip_address
  end
end

class ListZerglingsCommand < Command
  def initialize(logger, db)
    super(logger)
    @db = db
  end

  def run
    @db.all_docs do |doc|
      puts doc
    end
  end
end
