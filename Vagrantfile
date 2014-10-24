# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

ruby_version = ENV['PANOTPES_RUBY'] || 'jruby-1.7.16'
bundle_command = ruby_version.match(/jruby/) ? 'jbundle' : 'bundle'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu-14.04-docker"
  config.vm.box_url = "https://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64-vagrant-disk1.box"
  config.vm.network :forwarded_port, guest: 3000, host: 3000

  config.vm.provider "virtualbox" do |vb|
    vb.customize ["modifyvm", :id, "--memory", "2048"]
  end

  config.vm.synced_folder "./", "/home/vagrant/panoptes/"

  config.vm.provision "shell", inline: "mkdir -p /opt/postgresql"
  config.vm.provision "shell", inline: "docker stop $(docker ps -aq) || true; docker rm $(docker ps -aq) || true; rm /home/vagrant/panoptes/tmp/pids/server.pid || true"
  config.vm.provision "shell", inline: "echo #{ ruby_version } > /home/vagrant/.ruby-version" 

  config.vm.provision "docker",
    version: '1.0.1',
    images: [ 'zooniverse/postgresql',
              'zooniverse/zookeeper',
              'zooniverse/cellect',
              'zooniverse/ruby',
              'zooniverse/kafka',
              'redis' ]

  config.vm.provision "docker" do |d|
    d.run 'postgres', image: 'zooniverse/postgresql',
      args: '-e DB="panoptes_development" -e PG_USER="panoptes" -e PASS="panoptes" -v /opt/postgresql:/data'
    d.run 'zookeeper', image: 'zooniverse/zookeeper',
      cmd: '-c localhost:2888:3888 -i 1'
    d.run 'cellect', image: 'zooniverse/cellect',
      args: '--link postgres:pg --link zookeeper:zk'
    d.run 'redis', image: 'redis',
      cmd: 'redis-server --appendonly yes'
    d.run 'kafka', image: 'zooniverse/kafka',
      args: '--link zookeeper:zookeeper',
      cmd: '-H kafka -p 9092 -z zookeeper:2181 -i 1'
    d.run 'panoptes', image: "zooniverse/ruby:#{ ruby_version }",
      args: '--link zookeeper:zookeeper --link postgres:postgres --link kafka:kafka --link redis:redis -v /home/vagrant/panoptes/:/rails_app/ -e "RAILS_ENV=development" -p 3000:80',
      cmd: "bash -c \"#{ bundle_command } /rails_app/start.sh\""
    d.run 'panoptes-sidekiq', image: "zooniverse/ruby:#{ ruby_version}",
      args: '--link zookeeper:zookeeper --link postgres:postgres --link kafka:kafka --link redis:redis -v /home/vagrant/panoptes/:/rails_app/ -e "RAILS_ENV=development"',
      cmd: "bash -c \"#{ bundle_command } install && bundle exec sidekiq\""
  end
end
