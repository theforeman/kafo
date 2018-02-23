# This class is called from the kafo configure script
# and expects a yaml file to exist at either:
#   optional $answers class parameter
#   $modulepath/config/answers.yaml
#   /etc/kafo-configure/answers.yaml
#
class kafo_configure {

  if $kafo_add_progress == 'true' {
    add_progress()
  }

  hiera_include('classes')
}
