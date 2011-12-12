require 'guard/cucumber'


# This is an inline cucumber guard
# As the standard one does only look in features directory
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

module ::Guard
  class Cucumber
    module Inspector
      class << self
        def cucumber_folder?(path)
          puts path
          return true
        end
      end
    end
  end
end


def vagrant_provision
  IO.popen("vagrant provision") do |output|
    while line = output.gets do
      puts line
    end
  end
end
def all_tests_pass
  cucumber_guard = ::Guard.guards({ :name => 'extendedcucumber', :group => 'tests'}).first
  cucumber_passed = cucumber_guard.instance_variable_get("@failed_paths").empty?
  rspec_guard = ::Guard.guards({ :name => 'rspec', :group => 'tests'}).first
  rspec_passed = rspec_guard.instance_variable_get("@failed_paths").empty?
  return rspec_passed && cucumber_passed
end


group :tests do
  # Run rspec-puppet tests
  guard :rspec, :version => 2, :cli => "--color --format documentation", :spec_paths => ["puppet-repo"]  do
    watch(%r{^puppet-repo/.*/[^.]*\.pp$}) { "puppet-repo" }
    watch(%r{^puppet-repo/.*/[^.]*\.rb$}) { "puppet-repo" }
    watch(%r{^puppet-repo/.*/[^.]*_rspec.rb})
  end

  # Run cucumber puppet tests
  guard :extendedcucumber, :cli => "--require puppet-repo/features --strict --format pretty" do
    watch(%r{^puppet-repo/[^.]*\.pp$}) { "puppet-repo/features" }
    watch(%r{^puppet-repo/[^.]*\.rb$}) { "puppet-repo/features" }
    watch(%r{^puppet-repo/features/[^.]*.feature})

    callback(:run_on_change_end) do
      vagrant_provision if all_tests_pass
    end
  end

end
