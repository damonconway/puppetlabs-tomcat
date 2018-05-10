# Definition: tomcat::jar
#
# Manage deployment of JAR files.
#
# Parameters:
# @param catalina_base is the base directory for the Tomcat installation
# @param jar_base is the path relative to $catalina_base to deploy the JAR to.
#        Defaults to 'lib'.
# @param deployment_path Optional. Only one of $jar_base and $deployment_path
#        can be specified.
# @param jar_ensure specifies whether you are trying to add or remove the JAR.
#        Valid values are 'present' and 'absent'. Defaults to 'present'.
# @param jar_name Optional. Defaults to $name.
# @param jar_purge is a boolean specifying whether or not to purge the exploded JAR
#        directory. Defaults to true. Only applicable when $jar_ensure is 'absent'
#        or 'false'. Note: if tomcat is running and autodeploy is on, setting
#        $jar_purge to false won't stop tomcat from auto-undeploying exploded JARs.
# @param jar_source is the source to deploy the JAR from. Currently supports
#        http(s)://, puppet://, and ftp:// paths. $jar_source must be specified
#        unless $jar_ensure is set to 'false' or 'absent'.
# @param allow_insecure Specifies if HTTPS errors should be ignored when
#        downloading the jar tarball. Valid options: `true` and `false`.
#        Defaults to `false`.
# @param user specifies the user of the tomcat jar file.
#        Defaults to `$::tomcat::user`.
# @param group specifies the user group of the tomcat jar file.
#        Defaults to `$::tomcat::group`.
define tomcat::jar(
  Optional[Stdlib::Absolutepath] $catalina_base   = undef,
  Optional[String] $jar_base                      = undef,
  Optional[Stdlib::Absolutepath] $deployment_path = undef,
  Enum['present','absent'] $jar_ensure            = 'present',
  Optional[String] $jar_name                      = undef,
  Boolean $jar_purge                              = true,
  $jar_source                                     = undef,
  Boolean $allow_insecure                         = false,
  Optional[String] $user                          = undef,
  Optional[String] $group                         = undef,
) {
  include ::tomcat
  $_catalina_base = pick($catalina_base, $::tomcat::catalina_home)
  tag(sha1($_catalina_base))

  $_user  = pick($user, $::tomcat::user)
  $_group = pick($group, $::tomcat::group)

  if $jar_base and $deployment_path {
    fail('Only one of $jar_base and $deployment_path can be specified.')
  }

  if $jar_name {
    $_jar_name = $jar_name
  } else {
    $_jar_name = $name
  }

  if $_jar_name !~ /\.jar$/ {
    fail('jar_name must end with .jar')
  }

  if $deployment_path {
    $_deployment_path = $deployment_path
  } else {
    if $jar_base {
      $_jar_base = $jar_base
    } else {
      $_jar_base = 'lib'
    }
    $_deployment_path = "${_catalina_base}/${_jar_base}"
  }

  if $jar_ensure =~ /^(absent|false)$/ {
    file { "${_deployment_path}/${_jar_name}":
      ensure => absent,
      force  => false,
    }
    if $jar_purge {
      $jar_dir_name = regsubst($_jar_name, '\.jar$', '')
      if $jar_dir_name != '' {
        file { "${_deployment_path}/${jar_dir_name}":
          ensure => absent,
          force  => true,
        }
      }
    }
  } else {
    if ! $jar_source {
      fail('$jar_source must be specified if you aren\'t removing the JAR')
    }
    archive { "tomcat::jar ${name}":
      extract        => false,
      source         => $jar_source,
      path           => "${_deployment_path}/${_jar_name}",
      allow_insecure => $allow_insecure,
    }
    file { "tomcat::jar ${name}":
      ensure    => file,
      path      => "${_deployment_path}/${_jar_name}",
      owner     => $_user,
      group     => $_group,
      mode      => '0640',
      subscribe => Archive["tomcat::jar ${name}"],
    }
  }
}
