# Fact: lsbmajdistrelease
#
# Purpose: Returns the major version of the operation system version as gleaned
# from the lsbdistrelease fact.
#
# Resolution:
#   Uses the lsbmajdistrelease key of the operatingsystem_hash structured
#   fact, which itself parses the lsbdistrelease fact for numbers followed by a period and
#   returns those, or just the lsbdistrelease fact if none were found.
#
# Caveats:
#

require 'facter'

Facter.add(:lsbmajdistrelease) do
  confine :kernel => [ :linux, :"gnu/kfreebsd" ]
  setcode { Facter.fact("operatingsystem_hash").value["lsbmajdistrelease"] }
end
