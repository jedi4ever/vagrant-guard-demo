require "#{File.join(File.dirname(__FILE__),'..','spec_helper')}"

describe 'role::webserver', :type => :class do
  let(:facts) {{:server_tags => 'role:webserver=true', :operatingsystem => 'Ubuntu'}}
  it { should include_class('apache') }
  it { should contain_package('httpd').with_ensure('present') }
end
