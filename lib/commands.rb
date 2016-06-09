require 'net/ssh'
require_relative 'nests'

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

    time_delay = 10

    i = 0
    while i < @total_zerglings do
      host = @nest.get_or_create_host
      puts "Viper host ip address: #{host.ip_address}"

      puts "Current time delay: #{time_delay} secs"
      begin
        host.run_image('kevinjqiu/viper', ["-e COUCH=#{ENV['COUCH']}"])
        i += 1
        @logger.info "Hatched #{i}/#{@total_zerglings}"
        time_delay = [time_delay / 2, 10].max
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
