# Fact: osfamily
#
# Purpose: Returns the operating system
#
# Resolution:
#   Uses the osfamily key of the os structured fact, which itself
#   maps operating systems to operating system families, such as Linux
#   distribution derivatives. Adds mappings from specific operating systems
#   to kernels in the case that it is relevant.
#
# Caveats:
#   This fact is completely reliant on the operatingsystem fact, and no
#   heuristics are used.
#

Facter.add(:osfamily) do
  confine do
    !Facter.value("os")["family"].nil?
  end

  setcode { Facter.value("os")["family"] }
end
