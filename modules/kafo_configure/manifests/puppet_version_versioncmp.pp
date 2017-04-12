define kafo_configure::puppet_version_versioncmp($minimum = undef, $maximum = undef) {
  if $minimum and versioncmp($minimum, $::puppetversion) > 0 {
    fail("kafo_configure::puppet_version_failure: Puppet ${puppetversion} does not meet minimum requirement for ${title} (version $minimum)")
  }

  if $maximum and versioncmp($maximum, $::puppetversion) < 0 {
    fail("kafo_configure::puppet_version_failure: Puppet ${puppetversion} does not meet maximum requirement for ${title} (version $maximum)")
  }
}
