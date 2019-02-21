define kafo_configure::puppet_version_semver($requirement) {
  unless SemVer($facts['puppetversion']) =~ SemVerRange($requirement) {
    fail("kafo_configure::puppet_version_failure: Puppet ${facts['puppetversion']} does not meet requirements for ${title} (${requirement})")
  }
}
