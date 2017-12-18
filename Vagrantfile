require 'fileutils'
VAGRANTFILE_API_VERSION = "2"
Vagrant.require_version ">= 2.0.0"

# set defaults
$boxes = []
$os = "centos/7"
$ip_prefix = '10.0.0'
$disable_folder_sync = true
$proxies = {
  "http" => nil,
  "https" => nil,
  "no_proxy" => nil
}
$provisioning = {
  "playbook"      => nil,
  "remote_user"   => nil,
  "become"        => nil,
  "become_method" => nil,
  "become_user"   => nil
}

# read and load the config file
CONFIG = File.join(File.dirname(__FILE__), "Vagrantfile-config.rb")
if File.exist?(CONFIG)
    require CONFIG
end

#unless Vagrant.has_plugin?('vagrant-proxyconf')
#  puts 'vagrant-proxyconf plugin not found, installing...'
#  `vagrant plugin install vagrant-proxyconf`
#  abort 'vagrant-proxyconf plugin installed, but you need to rerun the vagrant command'
#end

# validate existance of master server
def parse_boxes(boxes)
  masters = []
  workers = []
  balancers = []
  boxes.each do |box|
    abort 'Must specify name for box' if box['name'].nil?
    case box['role']
      when "master"
        masters.push(box)
      when "worker"
        workers.push(box)
      when "balancer"
        balancers.push(box)
    end
  end
  abort 'At least one master must be specified in the $boxes config' if masters.empty?
  return masters + workers + balancers
end

# loop boxes to get ip address of the first server box found
def get_server_ip(boxes, hostname='')
  default_server_ip = nil
  boxes.each_with_index do |box, i|
    if not box['role'].nil? and box['role'] == 'server'
      ip = box['ip'] ? box['ip'] : "#{$ip_prefix}.#{i+1}#{i+1}"
      default_server_ip = ip if default_server_ip.nil?
      if hostname == "#{box['name']}-%02d" % i
        return ip
      end
    end
  end
  return default_server_ip
end

# sort boxes
$sorted_boxes = parse_boxes $boxes

# determine server ip
$default_server_ip = get_server_ip $sorted_boxes

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # global config
  config.ssh.insert_key = false

  # plugin conflict
  if Vagrant.has_plugin?("vagrant-vbguest") then
    config.vbguest.auto_update = false
  end

  # On VirtualBox, we don't have guest additions or a functional vboxsf in CoreOS, so tell Vagrant that so it can be smarter.
  config.vm.provider :virtualbox do |vb|
    #vb.check_guest_additions = false
    #vb.functional_vboxsf     = false
    vb.gui = false
  end

  config.vm.box = $os
  #config.vm.guest = :centos

  if $disable_folder_sync
    config.vm.synced_folder '.', '/vagrant', disabled: true
  else
    config.vm.synced_folder '.', '/vagrant', disabled: false
  end

  # Set correct proxies if defined, defaults to none
  if Vagrant.has_plugin?("vagrant-proxyconf")

    unless $proxies['http'].nil?
      config.proxy.http = $proxies['http']
    end
    unless $proxies['https'].nil?
      config.proxy.https = $proxies['https']
    end
    unless $proxies['ftp'].nil?
      config.proxy.ftp = $proxies['ftp']
    end
    unless $proxies['no_proxy'].nil?
      config.proxy.no_proxy = $proxies['no_proxy']

      # Determine box ips for private networking
      $sorted_boxes.each_with_index do |box, box_index|
        count = box['count'] || 1

        # loop instances of agents
        (0..count).each do |i|
          ip = box['ip'] ? box['ip'] : "#{$ip_prefix}.#{box_index+1}#{i}"
          config.proxy.no_proxy = config.proxy.no_proxy + "," + ip
        end
      end
    end
  end

  $sorted_boxes.each_with_index do |box, box_index|
    count = box['count'] || 1

    # loop instances
    #(1..count).each do |i|
    for i in 1..count

      # configure network
      hostname = "#{box['name']}-%02d" % i
      puts hostname.inspect
      config.vm.define hostname do |node|
        node.vm.hostname = hostname
        ip = box['ip'] ? box['ip'] : "#{$ip_prefix}.#{box_index+1}#{i}"
        node.vm.network 'private_network', ip: ip

        # provision commons
        config.vm.provision "ansible" do |ansible|
  #        ansible.verbose = "v"
          ansible.compatibility_mode = "2.0"
  #        if !$provisioning['become'].nil?
            ansible.become = $provisioning['become']
  #        else
  #          ansible.become = true
  #        end
          ansible.become_user = $provisioning['become_user'] if !$provisioning['become_user'].nil?
          ansible.extra_vars = $provisioning['extra_vars'] if !$provisioning['extra_vars'].nil?
  #
  #        case box['role']
  #        when "master"
  #          unless $provisioning['playbook-master'].nil?
              ansible.playbook = $provisioning['playbook-master']
  #          end
  #        when "worker"
  #          unless $provisioning['playbook-worker'].nil?
  #            ansible.playbook = $provisioning['playbook-worker']
  #          end
  #        when "balancer"
  #          unless $provisioning['playbook-balancer'].nil?
  #            ansible.playbook = $provisioning['playbook-balancer']
  #          end
  #        end
        end
        # configure hardware
        unless box['memory'].nil?
          node.vm.provider 'virtualbox' do |vb|
            vb.memory = box['memory']
            vb.linked_clone = true
            vb.cpus = box['cpu'] ? box['cpu'] : 2
            vb.customize ["modifyvm", :id, "--vram", "2"]
            vb.customize ["modifyvm", :id, "--cpuhotplug", "on"]
            vb.customize ["modifyvm", :id, "--ioapic", "on"]
            vb.customize ["modifyvm", :id, "--hwvirtex", "on"]
            vb.customize ["modifyvm", :id, "--boot1", "disk"]
            vb.customize ["modifyvm", :id, "--boot2", "none"]
            vb.customize ["modifyvm", :id, "--boot3", "none"]
            vb.customize ["modifyvm", :id, "--boot4", "none"]
            vb.customize ["storageattach", :id, "--storagectl", "IDE", '--port', '0', '--device', '0', '--nonrotational', 'on']
          end
        end
      end

    end
  end
end

