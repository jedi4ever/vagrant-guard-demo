require 'aruba/cucumber'
require 'shellwords'

# Uncomment this if you want to see the command as it really executed in the shell
# Aruba.configure do |config|
#   config.before_cmd do |cmd|
#     puts "--->#{cmd}"
#   end
# end

# Here we monkey patch Aruba to work with pipe commands
module Aruba
  class Process
    include Shellwords

    def initialize(cmd, exit_timeout, io_wait)
      @exit_timeout = exit_timeout
      @io_wait = io_wait

      @out = Tempfile.new("aruba-out")
      @err = Tempfile.new("aruba-err")
      #cmd2 = Shellwords.escape(cmd)
      #puts cmd2
      @process = ChildProcess.build(cmd)
      @process.io.stdout = @out
      @process.io.stderr = @err
      @process.duplex = true
    end
  end
end

