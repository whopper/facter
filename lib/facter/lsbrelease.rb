# Fact: lsbrelease
#
# Purpose: Return Linux Standard Base information for the host.
#
# Resolution:
#   Uses the lsbrelease key of the operatingsystem_hash structured fact,
#   which itself uses the `lsb_release` system command.
#
# Caveats:
#   Only works on Linux (and the kfreebsd derivative) systems.
#   Requires the `lsb_release` program, which may not be installed by default.
#   Also is as only as accurate as that program outputs.

Facter.add(:lsbrelease) do
  confine :kernel => [ :linux, :"gnu/kfreebsd" ]
  setcode { Facter["operatingsystem_hash"].value["lsb"]["lsbrelease"] }
end
