require 'rubygems'
require 'commander'
require 'couchrest'
require 'logger'
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
      c.option '-n INTEGER', Integer, 'Number of zerglings to hatch'
      c.action do |args, options|
        n = options.n || 1
        HatchCommand.new(@logger, n).run()
      end
    end

    command :zerglings do |c|
      c.syntax = 'overmind zerglings'
      c.action do |args, options|
        ListZerglingsCommand.new(@logger, @db).run()
      end
    end

    command :vote do |c|
      c.syntax = 'overmind vote'
      c.option '--up', 'Upvote'
      c.option '--down', 'Downvote'
      c.option '--thing STRING', String, 'Thing to up/down vote'
      c.action do |args, options|
        permalink = options.thing
        action = if options.up
                   :up
                 else
                   :down
                 end
        VoteCommand.new(@logger, @db, action, permalink).run()
      end
    end

    run!
  end
end

db = CouchRest.new(ENV['COUCH']).database!('zergling')
Overmind.new(db).run if $0 == __FILE__
