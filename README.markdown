# Test Driven Infrastructure with Vagrant, Puppet, Cucumber-Puppet, Rspec-Puppet and Guard
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

Compared to TDD cycle, the need to run `vagrant provision` or `rake rspec` actually breaks my development flow: I have to leave my editor to run a shell command and then come back to it depending on the output.

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

Guard uses a configurationfile `Guardfile`, which can be created by `guard init`

## What

