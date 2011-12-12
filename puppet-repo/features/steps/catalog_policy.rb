Given /^a node with role "([^\"]*)"$/ do |role|
  # server roles map to higher level puppet classes
  # (in manifests/templates.pp)
  @klass = role
end

Then /^puppet should ensure all packages are up\-to\-date$/ do
  packages.each do |package|
    package.should be_latest
  end
end
