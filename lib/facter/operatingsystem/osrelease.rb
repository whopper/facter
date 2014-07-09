require 'facter/util/file_read'
require 'facter/util/operatingsystem'
require 'facter/operatingsystem/lsb'

module Facter
  module Operatingsystem
    class Osrelease

      attr_reader :release

      def initialize(operatingsystem)
        @operatingsystem = operatingsystem
        @release         = get_release
      end

      def get_release
        case @operatingsystem
        when "Alpine"
          get_alpine_release_from_releasefile
        when "Amazon"
          get_amazon_release_from_lsb
        when "Bluewhite64"
          get_bluewhite_release_from_releasefile
        when "CentOS", "RedHat", "Scientific", "SLC", "Ascendos", "CloudLinux", "PSBM", "XenServer",
             "Fedora", "MeeGo", "OracleLinux", "OEL", "oel", "OVS", "ovs"
          get_redhatish_release_from_releasefile
        when "CumulusLinux"
          get_cumulus_linux_release_from_releasefile
        when "Debian"
          get_debian_release_from_releasefile
        when "LinuxMint"
          get_linux_mint_release_from_releasefile
        when "Mageia"
          get_mageia_release_from_releasefile
        when "OpenWrt"
          get_openwrt_release_from_releasefile
        when "Slackware"
          get_slackware_release_from_releasefile
        when "Slamd64"
          get_slamd64_release_from_releasefile
        when "SLES", "SLED", "OpenSuSE"
          get_suse_release_from_releasefile
        when "Solaris", "Nexenta", "OmniOS", "OpenIndiana", "SmartOS"
          get_solaris_release_from_releasefile
        when "Ubuntu"
          get_ubuntu_release_from_releasefile
        when "VMwareESX"
          get_vmwareESX_release_from_releasefile
        when "windows"
          get_windows_release_from_wmi
        else
          Facter[:kernelrelease].value
        end
      end

      def get_maj_release
        case @operatingsystem
        when "Amazon", "CentOS", "CloudLinux", "Debian", "Fedora", "OEL", "OracleLinux", "OVS",
              "RedHat", "Scientific", "SLC", "CumulusLinux"
          if @release
            @release.split(".").first
          end
        when "Solaris"
          if match = @release.match(/^(\d+)/)
            match.captures[0]
          end
        end
      end

      private

      def get_alpine_release_from_releasefile
        if release = Facter::Util::FileRead.read('/etc/alpine-release')
          release.sub!(/\s*$/, '')
          release
        end
      end

      def get_amazon_release_from_lsb
        lsb_obj = Facter::Operatingsystem::Lsb.new
        if lsbdistrelease = lsb_obj.get_lsbdistrelease
          lsbdistrelease
        else
          Facter[:kernelrelease].value
        end
      end

      def get_bluewhite_release_from_releasefile
        if release = Facter::Util::FileRead.read('/etc/bluewhite64-version')
          if match = /^\s*\w+\s+(\d+)\.(\d+)/.match(release)
            match[1] + "." + match[2]
          else
            "unknown"
          end
        end
      end

      def get_redhatish_release_from_releasefile
        case @operatingsystem
        when "CentOS", "RedHat", "Scientific", "SLC", "Ascendos", "CloudLinux", "PSBM", "XenServer"
          releasefile = "/etc/redhat-release"
        when "Fedora"
          releasefile = "/etc/fedora-release"
        when "MeeGo"
          releasefile = "/etc/meego-release"
        when "OracleLinux"
          releasefile = "/etc/oracle-release"
        when "OEL", "oel"
          releasefile = "/etc/enterprise-release"
        when "OVS", "ovs"
          releasefile = "/etc/ovs-release"
        end

        if release = Facter::Util::FileRead.read(releasefile)
          line = release.split("\n").first.chomp
          if match = /\(Rawhide\)$/.match(line)
            "Rawhide"
          elsif match = /release (\d[\d.]*)/.match(line)
            match[1]
          end
        end
      end

      def get_cumulus_linux_release_from_releasefile
        Facter::Util::Operatingsystem.os_release['VERSION_ID']
      end

      def get_debian_release_from_releasefile
        if release = Facter::Util::FileRead.read('/etc/debian_version')
          release.sub!(/\s*$/, '')
          release
        end
      end

      def get_linux_mint_release_from_releasefile
        regex_search_releasefile(/RELEASE\=(\d+)/, "/etc/linuxmint/info")
      end

      def get_mageia_release_from_releasefile
        regex_search_releasefile(/Mageia release ([0-9.]+)/, "/etc/mageia-release")
      end

      def get_openwrt_release_from_releasefile
        regex_search_releasefile(/^(\d+\.\d+.*)/, "/etc/openwrt_version")
      end

      def get_slackware_release_from_releasefile
        regex_search_releasefile(/Slackware ([0-9.]+)/, "/etc/slackware-version")
      end

      def get_slamd64_release_from_releasefile
        regex_search_releasefile(/^\s*\w+\s+(\d+)\.(\d+)/, "/etc/slamd64-version")
      end

      def get_suse_release_from_releasefile
        if release = Facter::Util::FileRead.read('/etc/SuSE-release')
          if match = /^VERSION\s*=\s*(\d+)/.match(release)
            releasemajor = match[1]
            if match = /^PATCHLEVEL\s*=\s*(\d+)/.match(release)
              releaseminor = match[1]
            elsif match = /^VERSION\s=.*.(\d+)/.match(release)
              releaseminor = match[1]
            else
              releaseminor = "0"
            end
            releasemajor + "." + releaseminor
          else
            "unknown"
          end
        end
      end

      def get_solaris_release_from_releasefile
        if release = Facter::Util::FileRead.read('/etc/release')
          begin
            line = release.split("\n").first.chomp
          rescue NoMethodError
            Facter[:kernelrelease].value
          end

          # Solaris 10: Solaris 10 10/09 s10x_u8wos_08a X86
          # Solaris 11 (old naming scheme): Oracle Solaris 11 11/11 X86
          # Solaris 11 (new naming scheme): Oracle Solaris 11.1 SPARC
          if match = /\s+s(\d+)[sx]?(_u\d+)?.*(?:SPARC|X86)/.match(line)
            match.captures.join('')
          elsif match = /Solaris ([0-9\.]+(?:\s*[0-9\.\/]+))\s*(?:SPARC|X86)/.match(line)
            match.captures[0]
          else
            Facter[:kernelrelease].value
          end
        else
          Facter[:kernelrelease].value
        end
      end

      def get_ubuntu_release_from_releasefile
        if release = Facter::Util::FileRead.read('/etc/lsb-release')
          if match = release.match(/DISTRIB_RELEASE=((\d+.\d+)(\.(\d+))?)/)
            # Return only the major and minor version numbers.  This behavior must
            # be preserved for compatibility reasons.
            match[2]
          end
        end
      end

      def get_vmwareESX_release_from_releasefile
        release = Facter::Core::Execution.exec('vmware -v')
        if match = /VMware ESX .*?(\d.*)/.match(release)
          match[1]
        end
      end

      def get_windows_release_from_wmi
        require 'facter/util/wmi'
        result = nil
        Facter::Util::WMI.execquery("SELECT version, producttype FROM Win32_OperatingSystem").each do |os|
          result =
            case os.version
            when /^6\.2/
              os.producttype == 1 ? "8" : "2012"
            when /^6\.1/
              os.producttype == 1 ? "7" : "2008 R2"
            when /^6\.0/
              os.producttype == 1 ? "Vista" : "2008"
            when /^5\.2/
              if os.producttype == 1
                "XP"
              else
                begin
                  os.othertypedescription == "R2" ? "2003 R2" : "2003"
                rescue NoMethodError
                  "2003"
                end
              end
            else
              Facter[:kernelrelease].value
            end
          break
        end
        result
      end

      def regex_search_releasefile(regex, releasefile)
        if release = Facter::Util::FileRead.read(releasefile)
          if match = release.match(regex)
            match[1]
          end
        end
      end
    end
  end
end
