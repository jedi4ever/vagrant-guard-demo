# Test Driven Infrastructure with Vagrant, Puppet and Guard
## Why
Lots has been written about [Vagrant](http://vagrantup.com). It simply is [a great tool](http://www.slideshare.net/jedi4ever/vagrant-devopsdays-mountain-view-2011): people use it as a sandbox environment to develop their Chef recipes or Puppet manifests in a safe environment.

The workflow usually looks like this:

- you create a vagrant vm
- share some puppet/chef files via a shared directory
- edit some files locally
- run a `vagrant provision` to see if this works
- and if you are happy with it, commit it to your favorite version control repository

Specifically for puppet, thanks to the great work by [Nikolay Sturm](http://twitter.com/nistude) and [Tim Sharpe](http://twitter.com/rodjek), we can now also complement this with tests written in [rspec-puppet](https://github.com/rodjek/rspec-puppet) and [cucumber-puppet](https://github.com/nistude/cucumber-puppet). You can find more info at [Puppet unit testing like a pro](http://www.jedi.be/blog/2011/12/05/puppet-unit-testing-like-a-pro/).

So we got code, and we got tests, what else are we missing? **Automation** of this process: it's funny if you think of it that we automate the hell out of server installations, but haven't automated the previous described process.

The need to run `vagrant provision` or `rake rspec` actually breaks my development flow: I have to leave my editor to run a shell command and then come back to it depending on the output.

Would it not be great if we could automate this whole cycle? And have it run tests and provision whenever files change?

## How
The first tool I came across is [autotest](https://github.com/autotest/autotest): it allows one to automatically re-execute tests depending on filesystem changes. Downside is that it could either run cucumber tests or rspec tests.

So enter [Guard](https://github.com/guard/guard); it describes itself as _a command line tool to easily handle events on file system modifications (FSEvent / Inotify / Polling support)_. Just what we wanted!

Installing Guard is pretty easy, you require the following gems in your Gemfile

    gem 'guard'
    gem 'rb-inotify', :require => false
    gem 'rb-fsevent', :require => false
    gem 'rb-fchange', :require => false
    gem 'growl', :require => false
    gem 'libnotify', :require => false

As you can tell by the names, it uses different strategies to detect changes in your directories. It uses growl (if correctly setup) on Mac OS X and libnotify on Linux to notify you if your tests pass or fail.
Once installed you get a command `guard`.

Guard uses a configuration file `Guardfile`, which can be created by `guard init`. In this file you define different guards based on different helpers: for example there is [guard-rspec](http://github.com/guard/guard-rspec), [guard-cucumber](http://github.com/guard/guard-cucumber) and [many more](http://github.com/guard). There is even a [guard-puppet](http://github.com/guard/guard-puppet)(which we will not use because it works only for local provisioning)

To install one of these helpers you just include it in your Gemfile. We are using only two here:

    gem 'guard-rspec'
    gem 'guard-cucumber'

Each of these helpers has a similar way of configuring themselves inside a Guardfile. A vanilla guard for a ruby gem with rspec testing would look like this:

    guard 'rspec' do
      watch(%r{^spec/.+_spec\.rb$})
      watch(%r{^lib/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }
      watch('spec/spec_helper.rb')  { "spec" }
    end

Whenever a file that matches a watch expression changes, it would run an rspec test. By default if no block is supplied, the file itself is run. You can alter the path in a block as in the example.

Once you have a `Guardfile` you simply run `guard` (or `bundle exec guard`) to have it watch changes. Simple hu?

## What
### Vagrant setup
Enter our sample puppet/vagrant project. You can find the full source at <http://github.com/jedi4ever/vagrant-guard-demo>
It's a typical vagrant project with the following tree structure:(only 3 levels shown)

    ├── Gemfile
    ├── Gemfile.lock
    ├── Guardfile
    ├── README.markdown
    ├── Vagrantfile
    ├── definitions # Veewee definitions
    │   └── lucid64
    │       ├── definition.rb
    │       ├── postinstall.sh
    │       └── preseed.cfg
    ├── iso # Veewee iso
    │   └── ubuntu-10.04.3-server-amd64.iso
    └── vendor
        └── ruby
            └── 1.8

### Puppet setup
The project follows Jordan Sissel's idea of [puppet nodeless configuration](http://www.semicomplete.com/blog/geekery/puppet-nodeless-configuration). To specify the classes to apply to a host, we use a fact called: `server_role`. We read this from a file `data/etc/server_tags` via [a custom fact](https://github.com/jedi4ever/vagrant-guard-demo/blob/master/puppet-repo/modules/truth/lib/facter/server_tags.rb) (inspired by  [self-classifying puppet node](http://nuknad.com/2011/02/11/self-classifying-puppet-nodes/)).

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

### Puppet - Vagrant setup

These are the settings we use in our Vagrant file to make puppet work:

    config.vm.share_folder "v-data", "/data", File.join(File.dirname(__FILE__), "data")
    # Enable provisioning with Puppet stand alone.  Puppet manifests
    # are contained in a directory path relative to this Vagrantfile.
    config.vm.provision :puppet, :options => "--verbose"  do |puppet|
      puppet.module_path = ["puppet-repo/modules"]
      puppet.manifests_path = "puppet-repo/manifests"
      puppet.manifest_file  = "site.pp"
    end

### Puppet tests setup
The cucumber-puppet tests will check if the catalog compiles for role `role::webserver`

    Feature: Catalog policy
      In order to ensure basic correctness
      I want all catalogs to obey my policy

      Scenario Outline: Generic policy for all server roles
        Given a node with role "<server_role>"
        When I compile its catalog
        Then compilation should succeed
        And all resource dependencies should resolve

        Examples:
          | server_role |
          | role::webserver |

The rspec-puppet tests will check if the package `http` gets installed

    require "#{File.join(File.dirname(__FILE__),'..','spec_helper')}"
    describe 'role::webserver', :type => :class do
      let(:facts) {{:server_tags => 'role:webserver=true',
          :operatingsystem => 'Ubuntu'}}
      it { should include_class('apache') }
      it { should contain_package('httpd').with_ensure('present') }
    end

### Guard setup
To make Guard work with a setup like our `puppet-repo` directory we need to change some things.
This has mostly to do with conventions used in development projects where Guard is normally used.

#### Fixing Guard-Cucumber to read from puppetrepo/features
The first problem is that the Guard-Cucumber gem standard reads it's features from `features` directory.
This is actually hardcoded in the gem. But nothing a little monkey patching can't solve:

    require 'guard/cucumber'

    # Inline extending the ::Guard::Cucumber
    # Because by default it only looks in the ['features'] directory
    # We have it in ['puppet-repo/features']
    module ::Guard
      class ExtendedCucumber < ::Guard::Cucumber
        def run_all
          passed = Runner.run(['puppet-repo/features'], options.merge(options[:run_all] || { }).merge(:message => 'Running all features'))

          if passed
            @failed_paths = []
          else
            @failed_paths = read_failed_features if @options[:keep_failed]
          end

          @last_failed = !passed

          throw :task_has_failed unless passed
        end
      end
    end

    # Monkey patching the Inspector class
    # By default it checks if it starts with /feature/
    # We tell it that whatever we pass is valid
    module ::Guard
      class Cucumber
        module Inspector
          class << self
            def cucumber_folder?(path)
              return true
            end
          end
        end
      end
    end

#### Orchestration of guard runs
The second problem was to have Guard only execute the Vagrant provision when **BOTH** the cucumber and rspec tests would be OK.
Inspired by [the comments](https://github.com/guard/guard/issues/189#issuecomment-3097145) of [Netzpirat](https://github.com/netzpirat), I got it working so that the block `vagrant provision` would only execute on both tests being complete.

    # This block simply calls vagrant provision via a shell
    # And shows the output
    def vagrant_provision
      IO.popen("vagrant provision") do |output|
        while line = output.gets do
          puts line
        end
      end
    end

    # So determine if all tests (both rspec and cucumber have been passed)
    # This is used to only invoke the vagrant_provision if all tests show green
    def all_tests_pass
      cucumber_guard = ::Guard.guards({ :name => 'extendedcucumber', :group => 'tests'}).first
      cucumber_passed = cucumber_guard.instance_variable_get("@failed_paths").empty?
      rspec_guard = ::Guard.guards({ :name => 'rspec', :group => 'tests'}).first
      rspec_passed = rspec_guard.instance_variable_get("@failed_paths").empty?
      return rspec_passed && cucumber_passed
    end

### Guard matchers
With all the correct guards and logic setup, it's time to specify the correct options to our Guards.

    group :tests do

      # Run rspec-puppet tests
      # --format documentation : for better output
      # :spec_paths to pass the correct path to look for features
      guard :rspec, :version => 2, :cli => "--color --format documentation", :spec_paths => ["puppet-repo"]  do
        # Match any .pp file (but be carefull not to include any dot-temporary files)
        watch(%r{^puppet-repo/.*/[^.]*\.pp$}) { "puppet-repo" }
        # Match any .rb file (but be carefull not to include any dot-temporary files)
        watch(%r{^puppet-repo/.*/[^.]*\.rb$}) { "puppet-repo" }
        # Match any _rspec.rb file (but be carefull not to include any dot-temporary files)
        watch(%r{^puppet-repo/.*/[^.]*_rspec.rb})
      end

      # Run cucumber puppet tests
      # This uses our extended cucumber guard, as by default it only looks in the features directory
      # --strict        : because otherwise cucumber would exit with 0 when there are pending steps
      # --format pretty : to get readable output, default is null output
      guard :extendedcucumber, :cli => "--require puppet-repo/features --strict --format pretty" do

        # Match any .pp file (but be carefull not to include any dot-temporary files)
        watch(%r{^puppet-repo/[^.]*\.pp$}) { "puppet-repo/features" }

        # Match any .rb file (but be carefull not to include any dot-temporary files)
        watch(%r{^puppet-repo/[^.]*\.rb$}) { "puppet-repo/features" }

        # Feature files are monitored as well
        watch(%r{^puppet-repo/features/[^.]*.feature})

        # This is only invoked on changes, not at initial startup
        callback(:start_end) do
          vagrant_provision if all_tests_pass
        end
        callback(:run_on_change_end) do
          vagrant_provision if all_tests_pass
        end
      end

    end

The full [Guardfile is on github](http://github.com/jedi4ever/vagrant-guard-demo/Guardfile)

### Run it
From within the top directory of the project type

`$ guard`

Now open a second terminal and change some of the files and watch the magic happen.

# Final remarks
The setup described is an idea I only recently started exploring. I'll probably enhance this in the future or may experience other problems.

For the demo project, I only call `vagrant provision`, but this can of course be extended easily. Some ideas:

1. Inspired by [Oliver Hookins - How we use Vagrant as a throwaway testing environment](http://paperairoplane.net/?p=240):
  - use [sahara](http://github.com/jedi4ever/sahara) to create a snapshot just before the provisioning
  - have it start from a clean machine when all tests pass
2. Turn this into a guard-vagrant gem, to monitor files and tests

