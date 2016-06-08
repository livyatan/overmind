require 'rubygems'
require 'commander'
require 'couchrest'
require 'logger'
require 'byebug'
require 'retriable'
require_relative 'lib/commands'

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
