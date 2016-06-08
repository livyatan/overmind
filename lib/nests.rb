require 'droplet_kit'
require_relative 'hosts'

class Nest
end

class DigitalOceanNest < Nest
  def initialize
    @client = DropletKit::Client.new(access_token: ENV['DIGITAL_OCEAN_ACCESS_TOKEN'])

    my_ssh_keys = @client.ssh_keys.all.collect {|key| key.fingerprint}
    @default_droplet_params = {
      name:     'viper',
      region:   'nyc2',
      image:    'coreos-stable',
      size:     '512mb',
      ssh_keys: my_ssh_keys,
    }
  end

  def get_or_create_host
    viper_droplet = @client.droplets.all.find_all { |d| d.name == 'viper' }.first
    if viper_droplet == nil
      viper_droplet = create_host
    end
    DigitalOceanHost.new viper_droplet
  end

  private
  def create_host
    droplet = DropletKit::Droplet.new @default_droplet_params
    created = @client.droplets.create(droplet)

    puts 'Waiting for the droplet to become active'
    droplet = nil
    Retriable.retriable on: RuntimeError, tries: 100, base_interval: 3 do
      print '.'
      droplet = @client.droplets.find(id: created.id)
      raise RuntimeError.new("Droplet status #{droplet.status} is not active") unless droplet.status == 'active'
    end
    droplet
  end

  def destroy_host(host)
    @client.droplets.delete(id: host.id)
  end
end
