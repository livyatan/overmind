require 'byebug'
require 'net/ssh'
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

    keys = ['/home/kevin/.ssh/id_rsa_coreos']
    Net::SSH.start(ip_address, 'core', :keys => keys) do |ssh|
      puts ssh.exec! "docker run -e COUCH=#{ENV['COUCH']} kevinjqiu/viper"
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
