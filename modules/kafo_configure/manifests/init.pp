# This class is called from the kafo configure script
# and expects a yaml file to exist at either:
#   optional $answers class parameter
#   $modulepath/config/answers.yaml
#   /etc/kafo-configure/answers.yaml
#
# @param add_progress
#   Whether to add a progress bar. Only works on Puppet < 6.
class kafo_configure(
  Boolean $add_progress = $::kafo_add_progress,
) {
  if $add_progress and SemVer($facts['puppetversion']) =~ SemVerRange('< 6.0.0') {
    add_progress()
  }

  hiera_include('classes')
}
