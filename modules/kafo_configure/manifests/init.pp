# This class is called from the kafo configure script
# and expects a yaml file to exist at either:
#   optional $answers class parameter
#   $modulepath/config/answers.yaml
#   /etc/kafo-configure/answers.yaml
#
class kafo_configure(
  Boolean $add_progress = false,
  Hash[String, String] $module_requirements = {},
) {
  $puppet_version = SemVer($facts['puppetversion'])

  $module_requirements.each |$module, $requirement| {
    unless $puppet_version =~ SemVerRange($requirement) {
      fail("kafo_configure::puppet_version_failure: Puppet ${facts['puppetversion']} does not meet requirements for ${module} (${requirement})")
    }
  }

  if $puppet_version =~ SemVerRange('< 6.0') and $add_progress {
    add_progress()
  }

  hiera_include('classes')
}
