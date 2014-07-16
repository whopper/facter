# Fact: operatingsystemrelease
#
# Purpose: Returns the release of the operating system.
#
# Resolution:
#   Uses the operatingsystemrelease key of the operatingsystem_hash
#   structured fact, which itself operates on the following conditions:
#
#   On RedHat derivatives, returns their `/etc/<variant>-release` file.
#   On Debian, returns `/etc/debian_version`.
#   On Ubuntu, parses `/etc/lsb-release` for the release version.
#   On Suse, derivatives, parses `/etc/SuSE-release` for a selection of version
#   information.
#   On Slackware, parses `/etc/slackware-version`.
#   On Amazon Linux, returns the `lsbdistrelease` value.
#   On Mageia, parses `/etc/mageia-release` for the release version.
#
#   On all remaining systems, returns the kernelrelease fact's value.
#
# Caveats:
#

Facter.add(:operatingsystemrelease) do
  setcode { Facter.fact("operatingsystem_hash").value["release"]["operatingsystemrelease"] }
end
