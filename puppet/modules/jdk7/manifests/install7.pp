# jdk7::instal7
#
# On Linux low entropy can cause certain operations to be very slow.
# Encryption operations need entropy to ensure randomness. Entropy is
# generated by the OS when you use the keyboard, the mouse or the disk.
#
# If an encryption operation is missing entropy it will wait until
# enough is generated.
#
# three options
#  use rngd service (this class)vagrant 
#  set java.security in JDK ( jre/lib/security )
#  set -Djava.security.egd=file:/dev/./urandom param
#
define jdk7::install7 (
  $version              = '7u25',
  $fullVersion          = 'jdk1.7.0_25',
  $x64                  = true,
  $alternativesPriority = 17065,
  $downloadDir          = '/install',
  $urandomJavaFix       = true,
  $sourcePath           = "puppet:///modules/${module_name}/",
) {

  if $x64 == true {
    $type = 'x64'
  } else {
    $type = 'i586'
  }

  case $::kernel {
    Linux   : {
      $installVersion = 'linux'
      $installExtension = '.tar.gz'
      $path = '/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:'
      $user = 'root'
      $group = 'root'
    }
    default : {
      fail('Unrecognized operating system, please use it on a Linux host')
    }
  }

  $jdkfile = "jdk-${version}-${installVersion}-${type}${installExtension}"

  # set the defaults for Exec
  Exec {
    path => $path,
    user => $user,
  }

  # set the defaults for File
  File {
    replace => false,
    owner   => $user,
    group   => $group,
    mode    => 0777,
  }

  exec { "create ${$downloadDir} directory":
    command => "mkdir -p ${$downloadDir}",
    unless  => "test -d ${$downloadDir}",
  }

  # check install folder
  if !defined(File[$downloadDir]) {
    file { $downloadDir:
      ensure  => directory,
      require => Exec["create ${$downloadDir} directory"],
    }
  }

  # download jdk to client
  file { "${downloadDir}/${jdkfile}":
    ensure  => file,
    source  => "${sourcePath}/${jdkfile}",
    require => File[$downloadDir],
  }

  # install on client
  javaexec { "jdkexec ${title} ${version}":
    path                 => $downloadDir,
    fullVersion          => $fullVersion,
    jdkfile              => $jdkfile,
    alternativesPriority => $alternativesPriority,
    user                 => $user,
    group                => $group,
    require              => File["${downloadDir}/${jdkfile}"],
  }

  if ($urandomJavaFix == true) {
    exec { "set urandom ${fullVersion}":
      command => "sed -i -e's/securerandom.source=file:\/dev\/urandom/securerandom.source=file:\/dev\/.\/urandom/g' /usr/java/${fullVersion}/jre/lib/security/java.security",
      unless  => "grep '^securerandom.source=file:/dev/./urandom' /usr/java/${fullVersion}/jre/lib/security/java.security",
      require => Javaexec["jdkexec ${title} ${version}"],
    }
  }
}