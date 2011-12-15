When /^I execute `([^`]*)` on a running system$/ do |cmd|
  @execute_command=ENV['SYSTEM_EXECUTE']
  @connect_failed=false
  unless @execute_command.nil?
    steps %Q{ When I run `#{@execute_command} "#{cmd}"` }
  else
    @execute_failed=true
    raise "No SYSTEM_EXECUTE environment variable specified"
  end
end

When /^I connect to a running system interactively$/ do
  @connect_command=ENV['SYSTEM_CONNECT']
  @connect_failed=false
  unless @connect_command.nil?
    steps %Q{
        When I run `#{@connect_command}` interactively
    }
  else
    @connect_failed=true
    raise "No SYSTEM_COMMAND environment variable specified"
  end
end

When /^I disconnect$/ do
  steps %Q{ When I type "exit $?" }
end
