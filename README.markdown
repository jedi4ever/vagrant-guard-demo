# Test Driven Infrastructure with Vagrant, Puppet and Guard
## Why
[Vagrant](http://vagrantup.com) is a great tool : people use it as a sandbox environment to develop their Chef recipes or Puppet manifests in a safe environment.

The workflow usually looks like this:

- create a vagrant vm
- share some puppet/chef files via a shared directory
- edit some files locally
- run a `vagrant provision` to see if this works
- if we are happy with it, commit it to the version control repository

Specifically for puppet, thanks to the great work by [Nicolas Sturm](http://twitter.com/nistude) and [Tim Sharpe](http://twitter.com/rodjek), we can now also complement this with tests written in [rspec-puppet](https://github.com/rodjek/rspec-puppet) and [cucumber-puppet](https://github.com/nistude/cucumber-puppet). You can find more info at [Puppet unit testing like a pro](http://www.jedi.be/blog/2011/12/05/puppet-unit-testing-like-a-pro/).

So we got code, and we got tests, what else are we missing? Automation of this process: it's funny if you think of it that we automate the hell out of server installations, but haven't automated the previous described process.

The need to run `vagrant provision` or `rake rspec` actually breaks my development flow: I have to leave my editor to run a shell command and then come back to it depending on the output.

Wouldn't it be great if we could automate this whole cycle? And have it run tests and provision whenever files change?

## How
The first tool I came across is [autotest](https://github.com/autotest/autotest) : it allows one to automatically re-execute tests depending on filesystem changes. Downside was that it could either run cucumber tests or rspec tests.

Enter [Guard](https://github.com/guard/guard); it describes itself as _a command line tool to easily handle events on file system modifications (FSEvent / Inotify / Polling support)_ . Just what we wanted.

Installing Guard is pretty easy, you require the following gems in your Gemfile

    gem 'guard'
    gem 'rb-inotify', :require => false
    gem 'rb-fsevent', :require => false
    gem 'rb-fchange', :require => false
    gem 'growl'

Once installed you get a command `guard`

Guard uses a configurationfile `Guardfile`, which can be created by `guard init`. In this file you define different guards based on different helpers: for example there is [guard-rspec](http://github.com/guard/guard-rspec), [guard-cucumber](http://github.com/guard/guard-cucumber) and [many more](http://github.com/guard). There is even a [guard-puppet](http://github.com/guard/guard-puppet).

To install one of these helpers you just include it in your Gemfile. We are using only two here:

    gem 'guard-rspec'
    gem 'guard-cucumber'

Each of these helpers have a similar way of configuring themselves inside a Guardfile. A vanilla guard for a ruby gem with rspec testing would like this:

    guard 'rspec' do
      watch(%r{^spec/.+_spec\.rb$})
      watch(%r{^lib/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }
      watch('spec/spec_helper.rb')  { "spec" }
      end
    end

Whenever a file that matches a watch expression changes, it would run an rspec test. By default if no block is supplied, the file itself is run. You can alter the path in a block as in the example.

Once you have `Guardfile` you simply run `guard` (or `bundle exec guard`) to have it watch changes. Simple hu?

## What
Enter our sample puppet/vagrant project. You can find the full source at <http://github.com/jedi4ever/vagrant-guard-demo>

It's a typical vagrant project with the following tree structure:(only 3 levels shown)

    ├── Gemfile
    ├── Gemfile.lock
    ├── Guardfile
    ├── README.markdown
    ├── Vagrantfile
    ├── definitions
    │   └── lucid64
    │       ├── definition.rb
    │       ├── postinstall.sh
    │       └── preseed.cfg
    ├── iso
    │   └── ubuntu-10.04.3-server-amd64.iso
    └── vendor
        └── ruby
            └── 1.8

The project follows Jordan Sissel's idea of [puppet nodeless configuration](http://www.semicomplete.com/blog/geekery/puppet-nodeless-configuration). To specify the classes to apply to a host, we use a fact called: `server_role`. We read this from a file `data/etc/server_tags` via [a custom fact](https://github.com/jedi4ever/vagrant-guard-demo/blob/master/puppet-repo/modules/truth/lib/facter/server_tags.rb) . (inspired by  [self-classifying puppet node](http://nuknad.com/2011/02/11/self-classifying-puppet-nodes/))

This allows us to only require one file, `site.pp`. And we don't have to fiddle with our hostname to get the correct role. Also if we want to test multiple roles on this one test machine, just add another role to the `data/etc/server_tags` file.

    ├── data
    │   └── etc
    │       └── server_tags

    $ cat data/etc/server_tags
    role:webserver=true

The puppet modules and manifests can be found in `puppet-repo`. It has class `role::webserver` which includes class `apache`.

    puppet-repo
    ├── features # This is where the cucucumber-puppet catalog policy feature lives
    │   ├── catalog_policy.feature
    │   ├── steps
    │   │   ├── catalog_policy.rb
    │   └── support
    │       ├── hooks.rb
    │       └── world.rb
    ├── manifests 
    │   └── site.pp #No nodes required
    └── modules
        ├── apache
        |    <module content>
        ├── role
        │   ├── manifests
        │   │   └── webserver.pp # Corresponds with the role specified
        │   └── rspec
        │       ├── classes
        │       └── spec_helper.rb
        └── truth # Logic of puppet nodeless configuration
            ├── lib
            │   ├── facter
            │   └── puppet
            └── manifests
                └── enforcer.pp

- The cucumber-puppet tests will check if the catalog compiles for role `role::webserver` 

    Feature: Catalog policy
      In order to ensure basic correctness
      I want all catalogs to obey my policy

      Scenario Outline: Generic policy for all server roles
        Given a node with role "<server_role>"
        When I compile its catalog
        Then compilation should succeed

        Examples:
          | server_role |
          | role::webserver |

- The rspec-puppet tests will check if the package `http` get installed

    require "#{File.join(File.dirname(__FILE__),'..','spec_helper')}"

    describe 'role::webserver', :type => :class do
      let(:facts) {{:server_tags => 'role:webserver=true',
          :operatingsystem => 'Ubuntu'}}
      it { should include_class('apache') }
      it { should contain_package('httpd').with_ensure('present') }
    end

So how do we make this work with guard?

1. the guard-cucumber assumes to have it's features in `$PROJECT/features`
2. if we add both guard-rspec and guard-cucumber we need to check if both tests before running `vagrant provision`

