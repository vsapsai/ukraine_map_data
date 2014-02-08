Vagrant.configure("2") do |config|
  config.vm.box = 'precise64'
  config.vm.box_url = 'http://files.vagrantup.com/precise64.box'

  config.vm.network :forwarded_port, guest: 1111, host: 1111
  
  config.vm.provider :virtualbox do |v|
    # This setting gives the VM 1024MB of MEMORIES instead of the default 384.
    v.customize ["modifyvm", :id, "--memory", 1024]
  end

  config.vm.provision :shell do |shell|
    shell.path = "vagrant.sh"
  end
end
