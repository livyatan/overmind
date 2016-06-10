require 'net/ssh'
require_relative 'nests'

MinTimeDelay = 10

class Command
  def initialize(logger)
    @logger = logger
  end
end

class HatchCommand < Command
  def initialize(logger, total_zerglings)
    super(logger)
    @total_zerglings = total_zerglings
    @nest = DigitalOceanNest.new
  end

  def run
    @logger.info 'Start nesting'

    time_delay = MinTimeDelay

    i = 0
    while i < @total_zerglings do
      host = @nest.get_or_create_host
      puts "Viper host ip address: #{host.ip_address}"

      puts "Current time delay: #{time_delay} secs"
      begin
        host.run_image('kevinjqiu/viper', ["-e COUCH=#{ENV['COUCH']}"])
        i += 1
        @logger.info "Hatched #{i}/#{@total_zerglings}"
        time_delay = [time_delay / 2, MinTimeDelay].max
      rescue
        @logger.warn "Runtime error encountered. Time to relocate to another host"
        time_delay *= 2
      ensure
        if i < @total_zerglings
          @logger.info "Cooling down for #{time_delay} seconds"
          sleep time_delay
        end
      end
    end
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

class VoteCommand < Command
  def initialize(logger, db, action, permalink)
    super(logger)
    @db = db
    @action = action
    @permalink = permalink
    @nest = DigitalOceanNest.new
  end

  def run
    host = @nest.get_or_create_host
    zerglings = @db.all_docs
    if @action == :up
      direction = "up"
    else
      direction = "down"
    end
    zerglings['rows'].each do |z|
      host.run_image('kevinjqiu/zergling', ["-e COUCH=#{ENV['COUCH']}"],
                     "python zergling.py #{direction} -u #{z['id']} -t #{@permalink}")
    end
  end
end
