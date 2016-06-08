require 'byebug'
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

    i = 0
    while i < @total_zerglings do
      host = @nest.get_or_create_host
      puts "Viper host ip address: #{host.ip_address}"

      begin
        host.run_image('kevinjqiu/viper', ["-e COUCH=#{ENV['COUCH']}"])
        i += 1
        @logger.info "Hatched #{i}/#{@total_zerglings}"
      rescue
        @logger.warn "Runtime error encountered. Time to relocate to another host"
        @nest.destroy_host host
      ensure
        if i < @total_zerglings
          sec = 30
          @logger.info "Cooling down for #{sec} seconds"
          sleep sec
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
