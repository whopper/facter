require 'facter/util/file_read'
require 'facter/util/operatingsystem'

module Facter
  module Operatingsystem
    def self.implementation(kernel = Facter.value(:kernel))
      case kernel
      when "Linux"
        release_info = Facter::Util::Operatingsystem.os_release
        if release_info['NAME'] == "Cumulus Linux"
          Facter::Operatingsystem::CumulusLinux.new
        else
          Facter::Operatingsystem::Linux.new
        end
      when "gnu/kfreebsd"
          Facter::Operatingsystem::GNU.new
      when "SunOS"
          Facter::Operatingsystem::SunOS.new
      when "VMkernel"
          Facter::Operatingsystem::VMkernel.new
      when "windows"
          Facter::Operatingsystem::Windows.new
      else
          Facter::Operatingsystem::Base.new
      end
    end

    class Base
      def get_operatingsystem
        @operatingsystem ||= Facter.value(:kernel)
        @operatingsystem
      end

      def get_osfamily
        Facter.value(:kernel)
      end

      def get_operatingsystemrelease
        Facter.value(:kernelrelease)
      end

      def get_operatingsystemmajrelease
        nil
      end

      def get_lsb_facts_hash
        nil
      end
    end

    class Linux < Base
      def get_operatingsystem
        if lsbdistid = get_lsbdistid
          if lsbdistid == "Ubuntu"
            @operatingsystem ||= "Ubuntu"
          elsif lsbdistid == "LinuxMint"
            @operatingsystem ||= "LinuxMint"
          else
            @operatingsystem ||= get_operatingsystem_with_release_files
          end
        else
          @operatingsystem ||= get_operatingsystem_with_release_files
        end
      end

      def get_osfamily
        case get_operatingsystem
        when "RedHat", "Fedora", "CentOS", "Scientific", "SLC", "Ascendos", "CloudLinux", "PSBM", "OracleLinux", "OVS", "OEL", "Amazon", "XenServer"
          "RedHat"
        when "LinuxMint", "Ubuntu", "Debian"
          "Debian"
        when "SLES", "SLED", "OpenSuSE", "SuSE"
          "Suse"
        when "Gentoo"
          "Gentoo"
        when "Archlinux"
          "Archlinux"
        when "Mageia", "Mandriva", "Mandrake"
          "Mandrake"
        else
          Facter.value("kernel")
        end
      end

      def get_operatingsystemrelease
        case get_operatingsystem
        when "Alpine"
          get_alpine_release_with_release_file
        when "Amazon"
          get_amazon_release_with_lsb
        when "BlueWhite64"
          get_bluewhite_release_with_release_file
        when "CentOS", "RedHat", "Scientific", "SLC", "Ascendos", "CloudLinux", "PSBM",
             "XenServer", "Fedora", "MeeGo", "OracleLinux", "OEL", "oel", "OVS", "ovs"
          get_redhatish_release_with_release_file
        when "Debian"
          get_debian_release_with_release_file
        when "LinuxMint"
          get_linux_mint_release_with_release_file
        when "Mageia"
          get_mageia_release_with_release_file
        when "OpenWrt"
          get_openwrt_release_with_release_file
        when "Slackware"
          get_slackware_release_with_release_file
        when "Slamd64"
          get_slamd64_release_with_release_file
       when "SLES", "SLED", "OpenSuSE"
          get_suse_release_with_release_file
        when "Ubuntu"
          get_ubuntu_release_with_release_file
        when "VMwareESX"
          get_vmwareESX_release_with_release_file
        end
      end

      def get_operatingsystemmajrelease
        suitable_systems = ["Amazon", "CentOS", "CloudLinux", "Debian", "Fedora", "OEL", 
                            "OracleLinux", "OVS", "RedHat", "Scientific", "SLC", "CumulusLinux"]

        if suitable_systems.include?(get_operatingsystem)
          if operatingsystemrelease = get_operatingsystemrelease
            operatingsystemrelease.split(".").first
          end
        end
      end

      def get_lsbdistcodename
        lsbdistcodename = Facter::Core::Execution.exec("lsb_release -c -s 2>/dev/null")
        unless lsbdistcodename == ""
          lsbdistcodename
        end
      end

      def get_lsbdistid
        @lsbdistid ||= Facter::Core::Execution.exec("lsb_release -i -s 2>/dev/null")
        unless @lsbdistid == ""
          @lsbdistid
        end
      end

      def get_lsbdistdescription
        lsbdistdescription = Facter::Core::Execution.exec("lsb_release -d -s 2>/dev/null")
        begin
          lsbdistdescription.sub(/^"(.*)"$/,'\1')
        rescue NoMethodError
          nil
        end
      end

      def get_lsbrelease
        lsbrelease = Facter::Core::Execution.exec("lsb_release -v -s 2>/dev/null")
        unless lsbrelease == ""
          lsbrelease
        end
      end

      def get_lsbdistrelease
        lsbdistrelease = Facter::Core::Execution.exec("lsb_release -r -s 2>/dev/null")
        unless lsbdistrelease == ""
          lsbdistrelease
        end
      end

      def get_lsbmajdistrelease
        lsbdistrelease = get_lsbdistrelease
        if /(\d*)\./i =~ lsbdistrelease
          result = $1
        else
          result = lsbdistrelease
        end
        result
      end

      def get_lsb_facts_hash
        lsb_hash = {}
        if lsbdistcodename = get_lsbdistcodename
          lsb_hash["distcodename"] = lsbdistcodename
        end

        if lsbdistid = get_lsbdistid
          lsb_hash["distid"] = lsbdistid
        end

        if lsbdistdescription = get_lsbdistdescription
          lsb_hash["distdescription"] = lsbdistdescription
        end

        if lsbrelease = get_lsbrelease
          lsb_hash["release"] = lsbrelease
        end

        if lsbdistrelease = get_lsbdistrelease
          lsb_hash["distrelease"] = lsbdistrelease
        end

        if lsbmajdistrelease = get_lsbmajdistrelease
          lsb_hash["majdistrelease"]  = lsbmajdistrelease
        end
        lsb_hash
      end

      private

      # Sequentially searches the filesystem for the existence of a release file
      #
      # @return [String, NilClass]
      def get_operatingsystem_with_release_files
        operatingsystem = nil
        release_files = {
          "Debian"      => "/etc/debian_version",
          "Gentoo"      => "/etc/gentoo-release",
          "Fedora"      => "/etc/fedora-release",
          "Mageia"      => "/etc/mageia-release",
          "Mandriva"    => "/etc/mandriva-release",
          "Mandrake"    => "/etc/mandrake-release",
          "MeeGo"       => "/etc/meego-release",
          "Archlinux"   => "/etc/arch-release",
          "OracleLinux" => "/etc/oracle-release",
          "OpenWrt"     => "/etc/openwrt_release",
          "Alpine"      => "/etc/alpine-release",
          "VMWareESX"   => "/etc/vmware-release",
          "Bluewhite64" => "/etc/bluewhite64-version",
          "Slamd64"     => "/etc/slamd64-version",
          "Slackware"   => "/etc/slackware-version"
        }

        release_files.each do |os, releasefile|
          if FileTest.exists?(releasefile)
            operatingsystem = os
          end
        end

        unless operatingsystem
          if FileTest.exists?("/etc/enterprise-release")
            if FileTest.exists?("/etc/ovs-release")
              operatingsystem = "OVS"
            else
              operatingsystem = "OEL"
            end
          elsif FileTest.exists?("/etc/redhat-release")
            operatingsystem = get_redhat_operatingsystem_name
          elsif FileTest.exists?("/etc/SuSE-release")
            operatingsystem = get_suse_operatingsystem_name
          elsif FileTest.exists?("/etc/system-release")
            operatingsystem = "Amazon"
          end
        end

        operatingsystem
      end

      # Uses a regex search on /etc/redhat-release to determine OS
      #
      # @return [String]
      def get_redhat_operatingsystem_name
        txt = File.read("/etc/redhat-release")
        matches = {
          "CentOS"     => "centos",
          "Scientific" => "Scientific",
          "CloudLinux" => "^cloudlinux",
          "PSBM"       => "^Parallels Server Bare Metal",
          "Ascendos"   => "Ascendos",
          "XenServer"  => "^XenServer"
        }

        if txt =~ /CERN/
          "SLC"
        else
          match = regex_search_release_file_for_operatingsystem(matches, txt)
          match = "RedHat" if match == nil

          match
        end
      end

      # Uses a regex search on /etc/SuSE-release to determine OS
      #
      # @return [String]
      def get_suse_operatingsystem_name
        txt = File.read("/etc/SuSE-release")
        matches = {
          "SLES"     => "^SUSE LINUX Enterprise Server",
          "SLED"     => "^SUSE LINUX Enterprise Desktop",
          "OpenSuSE" => "^openSUSE"
        }
        match = regex_search_release_file_for_operatingsystem(matches, txt)
        match = "SuSE" if match == nil

        match
      end

      # Iterates over potential matches from a hash argument and returns
      # result of search
      #
      # @return [String, NilClass]
      def regex_search_release_file_for_operatingsystem(regex_os_hash, filecontent)
        match = nil
        regex_os_hash.each do |os, regex|
          match = os if filecontent =~ /#{regex}/i
        end

        match
      end

      # Read release files to determine operatingsystemrelease
      #
      # @return [String]
      def get_alpine_release_with_release_file
        if release = Facter::Util::FileRead.read('/etc/alpine-release')
          release.sub!(/\s*$/, '')
          release
        end
      end

      def get_amazon_release_with_lsb
        if lsbdistrelease = get_lsbdistrelease
          lsbdistrelease
        else
          Facter[:kernelrelease].value
        end
      end

      def get_bluewhite_release_with_release_file
        if release = Facter::Util::FileRead.read('/etc/bluewhite64-version')
          if match = /^\s*\w+\s+(\d+)\.(\d+)/.match(release)
            match[1] + "." + match[2]
          else
            "unknown"
          end
        end
      end

      def get_redhatish_release_with_release_file
        case get_operatingsystem
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

      def get_debian_release_with_release_file
        if release = Facter::Util::FileRead.read('/etc/debian_version')
          release.sub!(/\s*$/, '')
          release
        end
      end

      def get_linux_mint_release_with_release_file
        regex_search_releasefile_for_release(/RELEASE\=(\d+)/, "/etc/linuxmint/info")
      end

      def get_mageia_release_with_release_file
        regex_search_releasefile_for_release(/Mageia release ([0-9.]+)/, "/etc/mageia-release")
      end

      def get_openwrt_release_with_release_file
        regex_search_releasefile_for_release(/^(\d+\.\d+.*)/, "/etc/openwrt_version")
      end

      def get_slackware_release_with_release_file
        regex_search_releasefile_for_release(/Slackware ([0-9.]+)/, "/etc/slackware-version")
      end

      def get_slamd64_release_with_release_file
        regex_search_releasefile_for_release(/^\s*\w+\s+(\d+)\.(\d+)/, "/etc/slamd64-version")
      end

      def get_ubuntu_release_with_release_file
        if release = Facter::Util::FileRead.read('/etc/lsb-release')
          if match = release.match(/DISTRIB_RELEASE=((\d+.\d+)(\.(\d+))?)/)
            # Return only the major and minor version numbers.  This behavior must
            # be preserved for compatibility reasons.
            match[2]
          end
        end
      end

      def get_vmwareESX_release_with_release_file
        release = Facter::Core::Execution.exec('vmware -v')
        if match = /VMware ESX .*?(\d.*)/.match(release)
          match[1]
        end
      end

      def get_suse_release_with_release_file
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

      def regex_search_releasefile_for_release(regex, releasefile)
        if release = Facter::Util::FileRead.read(releasefile)
          if match = release.match(regex)
            match[1]
          end
        end
      end
    end

    class CumulusLinux < Linux
      def get_operatingsystem
        "CumulusLinux"
      end

      def get_osfamily
        "Debian"
      end

      def get_operatingsystemrelease
        @operatingsystemrelease ||= Facter::Util::Operatingsystem.os_release['VERSION_ID']
        @operatingsystemrelease
      end

      def get_operatingsystemmajrelease
        if operatingsystemrelease = get_operatingsystemrelease
          operatingsystemrelease.split(".").first
        end
      end
    end

    class SunOS < Base
      def get_operatingsystem
        output = Facter::Core::Execution.exec('uname -v')
        if output =~ /^joyent_/
          "SmartOS"
        elsif output =~ /^oi_/
          "OpenIndiana"
        elsif output =~ /^omnios-/
          "OmniOS"
        elsif FileTest.exists?("/etc/debian_version")
          "Nexenta"
        else
          "Solaris"
        end
      end

      def get_osfamily
        "Solaris"
      end

      def get_operatingsystemrelease
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

      def get_operatingsystemmajrelease
        if get_operatingsystem == "Solaris"
          if match = get_operatingsystemrelease.match(/^(\d+)/)
            match.captures[0]
          end
        end
      end
    end

    class VMkernel < Base
      def get_operatingsystem
        "ESXi"
      end
    end

    class Windows < Base
      def get_operatingsystemrelease
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
    end
  end
end
