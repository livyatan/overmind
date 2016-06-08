require 'rubygems'
require 'commander'
require 'couchrest'
require 'logger'
require 'byebug'
require 'droplet_kit'
require 'retriable'

class Nest
  def initialize
  end
end

class Command
  def initialize(logger)
    @logger = logger
  end
end

class HatchCommand < Command
  def run
    @logger.info 'Start nesting'
    client = DropletKit::Client.new(access_token: ENV['DIGITAL_OCEAN_ACCESS_TOKEN'])
    my_ssh_keys = client.ssh_keys.all.collect {|key| key.fingerprint}
    droplet = DropletKit::Droplet.new(name: 'viper', region: 'nyc2', image: 'coreos-stable', size: '512mb', ssh_keys: my_ssh_keys)
    created = client.droplets.create(droplet)

    puts 'Waiting for the droplet to become active'
    droplet = nil
    Retriable.retriable on: RuntimeError, tries: 100, base_interval: 3 do
      print '.'
      droplet = client.droplets.find(id: created.id)
      raise RuntimeError.new("Droplet status #{droplet.status} is not active") unless droplet.status == 'active'
    end
    byebug
    client.droplets.delete(id: created.id)
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

class Overmind
  include Commander::Methods

  def initialize(db)
    @db = db
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO
  end

  def run
    program :name, 'Overmind'
    program :version, '1.0.0'
    program :description, 'Command and Control Centre'

    command :hatch do |c|
      c.syntax = 'overmind hatch'
      c.action do |args, options|
        HatchCommand.new(@logger).run()
      end
    end

    command :zerglings do |c|
      c.syntax = 'overmind zerglings'
      c.action do |args, options|
        ListZerglingsCommand.new(@logger, @db).run()
      end
    end

    run!
  end
end

db = CouchRest.new(ENV['COUCH']).database!('zergling')
Overmind.new(db).run if $0 == __FILE__
