## Install necessary gems
    $ gem install bundler
#create Gemfile
    $ bundle install --path vendor
    $ bundle exec cucumber-nagios
    $ alias guard='bundle exec guard'
    $ alias vagrant='bundle exec vagrant'
    $ alias puppet='bundle exec puppet'

## Create a basebox with veewee
    $ vagrant basebox templates
    $ vagrant basebox define 'lucid64' 'ubuntu-10.04.3-server-amd64'
    $ vagrant basebox build 'lucid64'
    $ vagrant basebox valudate 'lucid64'
    $ vagrant basebox export 'lucid64'
## Adding the basebox to vagrant
    $ vagrant box add 'lucid64' 'lucid64.box'
    $ vagrant init lucid64
## Bring up the vm
    $ vagrant up
    $ vagrant ssh groupadd puppet
    $ vagrant sandbox on
## Activating puppet
    $ mkdir puppet-repo
    $ mkdir puppet-repo/{modules,manifests}
    $ > puppet-repo/manifests/site.pp
- adapt the Vagrantfile

config.vm.share_folder "v-data", "/data", File.join(File.dirname(__FILE__),"data")

config.vm.provision :puppet do |puppet|
      puppet.module_path = ["puppet-repo/modules"]
      puppet.manifests_path = "puppet-repo/manifests"
      puppet.manifest_file  = "site.pp"
end

- $ vagrant reload to read the shares
- use the enforcer mechanism for roles
- run it inside the vm
- write rspec-puppet, rspec-

    $ bundle exec guard init
