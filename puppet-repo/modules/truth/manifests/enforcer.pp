class truth::enforcer {
  if has_role("webserver") {
    include role::webserver
    notice("I am a webserver")
  }
}
