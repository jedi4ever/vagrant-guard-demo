require "cucumber/rake/task"

task :default => ["validate"]

# Usage rake validate
# - single vm: rake validate
# - multi vm: rake validate vm=logger
Cucumber::Rake::Task.new(:validate) do |task|
    # VM needs to be running already
    vm_name=ENV['vm'] || ""
    ssh_name=ENV['vm'] || "default"
    ENV['SYSTEM_CONNECT']="vagrant ssh #{vm_name}"
    ENV['SYSTEM_EXECUTE']="vagrant ssh_config #{vm_name}| ssh -q -F /dev/stdin #{ssh_name}"
    task.cucumber_opts = ["-s","features" ]
end
