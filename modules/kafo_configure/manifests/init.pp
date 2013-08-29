# This class is called from the kafo configure script
# and expects a yaml file to exist at either:
#   optional $answers class parameter
#   $modulepath/config/answers.yaml
#   /etc/kafo-configure/answers.yaml
#
class kafo_configure(
  $answers = undef
) {

  $password = load_kafo_password()
  $params   = loadanyyaml($answers,
                      "/etc/kafo-configure/answers.yaml",
                      "config/answers.yaml")
  $keys     = kafo_ordered(hash_keys($params))

  kafo_configure::yaml_to_class { $keys: }
}
