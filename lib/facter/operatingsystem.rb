# Fact: operatingsystem
#
# Purpose: Return the name of the operating system.
#
# Resolution:
#   Uses the operatingsystem key of the operatingsystem_hash structured
#   fact, which itself operates on the following conditions:
#
#
#   If the kernel is a Linux kernel, check for the existence of a selection of
#   files in `/etc/` to find the specific flavour.
#   On SunOS based kernels, attempt to determine the flavour, otherwise return Solaris.
#   On systems other than Linux, use the kernel fact's value.
#
# Caveats:
#

Facter.add(:operatingsystem) do
  setcode { Facter["operatingsystem_hash"].value["operatingsystem"] }
end
