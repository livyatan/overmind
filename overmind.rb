require 'rubygems'
require 'commander'
require 'couchrest'

class Overmind
  include Commander::Methods

  def initialize(db)
    @db = db
  end

  def run
    program :name, 'Overmind'
    program :version, '1.0.0'
    program :description, 'Command and Control Centre'

    command :hatch do |c|
      c.syntax = 'overmind hatch'
      c.action do |args, options|
        hatch
      end
    end

    command :zerglings do |c|
      c.syntax = 'overmind zerglings'
      c.action do |args, options|
        list_zerglings
      end
    end

    run!
  end

  private
  def hatch
    puts 'foo'
  end

  def list_zerglings
    @db.all_docs do |doc|
      puts doc
    end
  end
end

db = CouchRest.new(ENV['COUCH']).database!('zergling')
Overmind.new(db).run if $0 == __FILE__
