# Fact: operatingsystem_hash
#
#  Purpose:
#     Return various facts related to the machine's operating system.
#
#  Resolution:
#    For operatingsystem, if the kernel is a Linux kernel, check for the
#    existence of a selection of files in `/etc` to find the specific flavor.
#    On SunOS based kernels, attempt to determine the flavor, otherwise return Solaris.
#    On systems other than Linux, use the kernel value.
#
#    For operatingsystemrelease, on RedHat derivatives, we return their `/etc/<varient>-release` file.
#    On Debian, returns `/etc/debian_version`.
#    On Ubuntu, parses `/etc/lsb-release` for the release version
#    On Suse and derivatives, parses `/etc/SuSE-release` for a selection of version information.
#    On Slackware, parses `/etc/slackware-version`.
#    On Amazon Linux, returns the lsbdistrelease fact's value.
#    On Mageia, parses `/etc/mageia-release` for the release version.
#    On all remaining systems, returns the kernelrelease fact's value.
#
#    For the lsb facts, uses the `lsb_release` system command.
#
#   Caveats:
#     Lsb facts only work on Linux (and the kfreebsd derivative) systems.
#     Requires the `lsb_release` program, which may not be installed by default.
#     It is only as accurate as the ourput of lsb_release.
#

require 'facter/operatingsystem/os'

os = Facter::Operatingsystem.implementation
Facter.add("operatingsystem_hash", :type => :aggregate) do

  chunk(:operatingsystem) do
    os_hash = {}
    if operatingsystem = os.get_operatingsystem
      os_hash["operatingsystem"] = operatingsystem
      os_hash
    end
  end

  chunk(:osfamily) do
    os_hash = {}
    if osfamily = os.get_osfamily
      os_hash["osfamily"] = osfamily
    end
    os_hash
  end

  chunk(:release) do
    release_hash = {}
    release_hash["release"] = {}
    if osrelease = os.get_operatingsystem_release
      release_hash["release"]["operatingsystemrelease"] = osrelease
    end

    if osmajrelease = os.get_operatingsystem_maj_release
      release_hash["release"]["operatingsystemmajrelease"] = osmajrelease
    end
    release_hash
  end

  chunk(:lsb) do
    lsb_hash = {}
    lsb_hash["lsb"] = {}
    if lsbdistid = os.get_lsbdistid
      lsb_hash["lsb"]["lsbdistid"] = lsbdistid
    end

    if lsbdistcodename = os.get_lsbdistcodename
      lsb_hash["lsb"]["lsbdistcodename"] = lsbdistcodename
    end

    if lsbdistdescription = os.get_lsbdistdescription
      lsb_hash["lsb"]["lsbdistdescription"] = lsbdistdescription
    end

    if lsbrelease = os.get_lsbrelease
      lsb_hash["lsb"]["lsbrelease"] = lsbrelease
    end

    if lsbdistrelease = os.get_lsbdistrelease
      lsb_hash["lsb"]["lsbdistrelease"] = lsbdistrelease
    end

    if lsbmajdistrelease = os.get_lsbmajdistrelease
      lsb_hash["lsb"]["lsbmajdistrelease"] = lsbmajdistrelease
    end
    lsb_hash unless lsb_hash["lsb"].empty?
  end
end
