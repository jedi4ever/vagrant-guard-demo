class truth::enforcer {

  group { "puppet":
    ensure => "present",
  }

  if has_role("webserver") {
    include role::webserver
    Group["puppet"] -> Class["role::webserver"] 
    notice("I am a webserver")
  }
}
