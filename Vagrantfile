$script = <<SCRIPT
  echo "Provisioning dev machine"
  sudo apt-get update
  sudo apt-get upgrade -y
  sudo apt-get install -y docker-compose
  # If logging in, switch to the mounted directory instead of /home/vagrant
  echo "cd /vagrant" >> /home/vagrant/.profile
SCRIPT


Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-17.10"
  config.ssh.forward_agent = true
  config.ssh.insert_key = true
  config.vm.provider :virtualbox do |vb|
    # The following setting reduces boot time for the ubuntu/vagrant box
    # See: https://bugs.launchpad.net/cloud-images/+bug/1627844
    vb.customize ["modifyvm", :id, "--uartmode1", "disconnected"]
    # https://www.vagrantup.com/docs/virtualbox/configuration.html
    vb.linked_clone = true if Gem::Version.new(Vagrant::VERSION) >= Gem::Version.new('1.8.0')
  end

  config.vm.network "forwarded_port", guest: 389, host: 2389, host_ip: "127.0.0.1", id: "ldap"

  config.vm.provision "shell", inline: $script

end

