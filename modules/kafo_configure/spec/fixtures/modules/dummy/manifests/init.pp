class dummy (
  String $first = $dummy::params::first,
  Optional[Integer] $second = undef,
  Sensitive[String[1]] $password = $dummy::params::password,
) inherits dummy::params {
}
