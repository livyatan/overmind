require 'net/ssh'

class Host
  def run(image)
    raise NotImplementedError
  end
end

class DigitalOceanHost < Host
  def initialize(droplet)
    @droplet = droplet
    @keys = [ENV['DIGITAL_OCEAN_KEY_FILE']]
  end

  def ip_address
    @droplet.networks.v4[0].ip_address
  end

  def run_image(image_name, params=[])
    command = "docker pull #{image_name} && docker run #{params.join(' ')} #{image_name}"
    puts "About to run command: #{command} on host: #{ip_address}"
    Net::SSH.start(ip_address, 'core', :keys => @keys) do |ssh|
      output = ssh.exec! command
      lines = output.split.collect { |line| line.start_with? "****" }
      puts lines
      if lines.include? "****ZERGLING HATCHED****"
        true
      else
        raise RuntimeError.new(lines)
      end
    end
  end
end
