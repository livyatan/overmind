require 'droplet_kit'

class Nest
  def initialize
  end
end

class DigitalOceanNest < Nest
  def initialize
    @client = DropletKit::Client.new(access_token: ENV['DIGITAL_OCEAN_ACCESS_TOKEN'])
  end

  def get_or_create_host
    viper_host = @client.droplets.all.find_all { |d| d.name == 'viper' }.first
    if viper_host == nil
      viper_host = create_host
    end
    viper_host
  end

  private
  def create_host
    my_ssh_keys = @client.ssh_keys.all.collect {|key| key.fingerprint}
    droplet = DropletKit::Droplet.new(name: 'viper', region: 'nyc2', image: 'coreos-stable', size: '512mb', ssh_keys: my_ssh_keys)
    created = @client.droplets.create(droplet)

    puts 'Waiting for the droplet to become active'
    droplet = nil
    Retriable.retriable on: RuntimeError, tries: 100, base_interval: 3 do
      print '.'
      droplet = @client.droplets.find(id: created.id)
      raise RuntimeError.new("Droplet status #{droplet.status} is not active") unless droplet.status == 'active'
    end
  end

  def destroy_host(host)
    @client.droplets.delete(id: host.id)
  end
end
