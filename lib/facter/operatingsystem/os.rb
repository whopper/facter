require 'facter/util/operatingsystem'
require 'facter/operatingsystem/osrelease'

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
      else
          Facter::Operatingsystem::Base.new
      end
    end

    class Base

      attr_reader :operatingsystem

      def initialize
        @operatingsystem = get_operatingsystem
        @osrelease_obj   = Facter::Operatingsystem::Osrelease.new(@operatingsystem)
      end

      def get_operatingsystem
        Facter.value(:kernel)
      end

      def get_osfamily
        Facter.value(:kernel)
      end

      def get_operatingsystem_release
        @osrelease_obj.release
      end

      def get_operatingsystem_maj_release
        @osrelease_obj.get_maj_release
      end

      def get_lsbdistcodename
        nil
      end

      def get_lsbdistid
        nil
      end

      def get_lsbdistdescription
        nil
      end

      def get_lsbrelease
        nil
      end

      def get_lsbdistrelease
        nil
      end

      def get_lsbmajdistrelease
        nil
      end
    end

    class GNU < Base
      def initialize
        @operatingsystem = get_operatingsystem
        @lsb_obj         = Facter::Operatingsystem::Lsb.new
        @osrelease_obj   = Facter::Operatingsystem::Osrelease.new(@operatingsystem)
      end

      def get_lsbdistcodename
        @lsb_obj.get_lsbdistcodename
      end

      def get_lsbdistid
        @lsb_obj.get_lsbdistid
      end

      def get_lsbdistdescription
        @lsb_obj.get_lsbdistdescription
      end

      def get_lsbrelease
        @lsb_obj.get_lsbrelease
      end

      def get_lsbdistrelease
        @lsb_obj.get_lsbdistrelease
      end

      def get_lsbmajdistrelease
        @lsb_obj.get_lsbmajdistrelease
      end
    end

    class CumulusLinux < GNU
      def get_operatingsystem
        "CumulusLinux"
      end

      def get_osfamily
        "Debian"
      end
    end

    class Linux < GNU
      def get_operatingsystem
        if lsbdistid = Facter.value(:lsbdistid)
          if lsbdistid == "Ubuntu"
            operatingsystem = "Ubuntu"
          elsif lsbdistid == "LinuxMint"
            operatingsystem = "LinuxMint"
          else
            operatingsystem = get_operatingsystem_with_release_files
          end
        else
          # Check for the existence of known release and version files to determine OS
          operatingsystem = get_operatingsystem_with_release_files
        end
        operatingsystem
      end

      def get_osfamily
        case @operatingsystem
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
            # We have to do this because other distros include this file as well,
            # so we fall back to Amazon if no other more specific release files
            # are found
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
          match = regex_search_release_file(matches, txt)
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
        match = regex_search_release_file(matches, txt)
        match = "SuSE" if match == nil

        match
      end

      # Iterates over potential matches from a hash argument and returns
      # result of search
      #
      # @return [String, NilClass]
      def regex_search_release_file(regex_os_hash, filecontent)
        match = nil
        regex_os_hash.each do |os, regex|
          match = os if filecontent =~ /#{regex}/i
        end

        match
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
    end

    class VMkernel < Base
      def get_operatingsystem
        "ESXi"
      end
    end
  end
end
