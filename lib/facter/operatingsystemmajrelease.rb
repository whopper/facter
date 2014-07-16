# Fact: operatingsystemmajrelease
#
# Purpose: Returns the major release of the operating system.
#
# Resolution:
#   Uses the operatingsystemmajrelease key of the operatingsystem_hash
#   structured fact, which itself splits down its operatingsystemrelease
#   key at decimal point for osfamily RedHat derivatives and Debian.
#   Uses operatingsystemrelease key to the first non decimal character for
#   operatingsystem Solaris
#
# This should be the same as lsbmajdistrelease, but on minimal systems there
# are too many dependencies to use LSB
#
# List of operatingsystems at time of writing:
#"Alpine" "Amazon" "Archlinux" "Ascendos" "Bluewhite64" "CentOS" "CloudLinux" 
#"Debian" "Fedora" "Gentoo" "Mandrake" "Mandriva" "MeeGo" "OEL" "OpenSuSE" 
#"OracleLinux" "OVS" "PSBM" "RedHat" "Scientific" "Slackware" "Slamd64" "SLC"
#"SLED" "SLES" "SuSE" "Ubuntu" "VMWareESX"

Facter.add(:operatingsystemmajrelease) do
  confine :operatingsystem => [
    :Amazon,
    :CentOS,
    :CloudLinux,
    :Debian,
    :Fedora,
    :OEL,
    :OracleLinux,
    :OVS,
    :RedHat,
    :Scientific,
    :SLC,
    :CumulusLinux,
    :solaris
  ]

  setcode { Facter["operatingsystem_hash"].value["release"]["operatingsystemmajrelease"] }
end
