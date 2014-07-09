#! /usr/bin/env ruby
#
require 'spec_helper'
require 'facter/operatingsystem/os'

describe Facter::Operatingsystem do
  it "should return an object of type Linux for linux kernels that are not Cumulus Linux" do
    Facter.fact(:kernel).stubs(:value).returns("Linux")
    Facter::Util::Operatingsystem.expects(:os_release).returns({'NAME' => 'Some Linux'})
    object = described_class.implementation
    object.should be_a_kind_of(Facter::Operatingsystem::Linux)
  end

  it "should identify Cumulus Linux when a Linux kernel is encountered" do
    Facter.fact(:kernel).stubs(:value).returns("Linux")
    Facter::Util::Operatingsystem.expects(:os_release).at_least_once.returns({'NAME' => 'Cumulus Linux'})
    object = described_class.implementation
    object.should be_a_kind_of(Facter::Operatingsystem::CumulusLinux)
  end

  it "should return an object of type SunOS for SunOS kernels" do
    Facter.fact(:kernel).stubs(:value).returns("SunOS")
    object = described_class.implementation
    object.should be_a_kind_of(Facter::Operatingsystem::SunOS)
  end

  it "should return an object of type VMkernel for VMkernel kernels" do
    Facter.fact(:kernel).stubs(:value).returns("VMkernel")
    object = described_class.implementation
    object.should be_a_kind_of(Facter::Operatingsystem::VMkernel)
  end

  it "should return an object of type Base for other kernels" do
    Facter.fact(:kernel).stubs(:value).returns("Nutmeg")
    object = described_class.implementation
    object.should be_a_kind_of(Facter::Operatingsystem::Base)
  end
end

describe Facter::Operatingsystem::Base do
  subject { described_class.new }

  before :each do
    Facter.fact(:kernel).stubs(:value).returns("Nutmeg")
  end

  describe "Operating system fact" do
    it "should default to the kernel name" do
      os = subject.operatingsystem
      expect(os).to eq "Nutmeg"
    end
  end

  describe "Osfamily fact" do
    it "should default to the kernel name" do
      osfamily = subject.get_osfamily
      expect(osfamily).to eq "Nutmeg"
    end

    [
      'ESXi',
      'windows',
      'HP-UX'
    ].each do |os|
      it "should return the kernel fact on operatingsystem #{os}" do
        subject.instance_variable_set :@operatingsystem, os
        Facter.fact(:kernel).stubs(:value).returns "random_kernel_fact"
        osfamily = subject.get_osfamily
        expect(osfamily).to eq "random_kernel_fact"
      end
    end
  end

  describe "lsb facts" do
    it "should return nil for lsbdistcodename by default" do
      lsbdistcodename = subject.get_lsbdistcodename
      expect(lsbdistcodename).to be_nil
    end

    it "should return nil for lsbdistid by default" do
      lsbdistid = subject.get_lsbdistid
      expect(lsbdistid).to be_nil
    end

    it "should return nil for lsbdistdescription by default" do
      lsbdistdescription = subject.get_lsbdistdescription
      expect(lsbdistdescription).to be_nil
    end

    it "should return nil for lsbrelease by default" do
      lsbrelease = subject.get_lsbrelease
      expect(lsbrelease).to be_nil
    end

    it "should return nil for lsbdistrelease by default" do
      lsbdistrelease = subject.get_lsbdistrelease
      expect(lsbdistrelease).to be_nil
    end

    it "should return nil for lsbmajdistrelease" do
      lsbmajdistrelease = subject.get_lsbmajdistrelease
      expect(lsbmajdistrelease).to be_nil
    end

  end
end

describe Facter::Operatingsystem::GNU do
  subject { described_class.new }
  let(:lsb_obj) { stub 'lsb object' }
  let(:osrelease_obj) { stub 'osrelease object' }

  before :all do
    Facter.fact(:kernel).stubs(:value).returns("Linux")
    Facter::Operatingsystem::Lsb.stubs(:new).returns lsb_obj
    Facter::Operatingsystem::Osrelease.stubs(:new).returns osrelease_obj
    subject.instance_variable_set :@operatingsystem, "SomeGNU"
    subject.instance_variable_set :@lsb_obj, lsb_obj
    subject.instance_variable_set :@osrelease_obj, osrelease_obj
  end

  describe "Lsb facts" do
    describe "lsbdistcodename fact" do
      it "should return the lsbdistcodename from its lsb object" do
        lsb_obj.expects(:get_lsbdistcodename).returns("SomeGNU")
        lsbdistcodename = subject.get_lsbdistcodename
        expect(lsbdistcodename).to eq "SomeGNU"
      end
    end

    describe "lsbdistid fact" do
      it "should return the lsbdistid from its lsb object" do
        lsb_obj.expects(:get_lsbdistid).returns("SomeGNUID")
        lsbdistid = subject.get_lsbdistid
        expect(lsbdistid).to eq "SomeGNUID"
      end
    end

    describe "lsbdistdescription fact" do
      it "should return the lsbdistdescription from its lsb object" do
        lsb_obj.expects(:get_lsbdistdescription).returns("SomeGNU Version 1.5")
        lsbdistdescription = subject.get_lsbdistdescription
        expect(lsbdistdescription).to eq "SomeGNU Version 1.5"
      end
    end

    describe "lsbrelease fact" do
      it "should return the lsbdistrelease from its lsb object" do
        lsb_obj.expects(:get_lsbrelease).returns("1.5")
        lsbrelease = subject.get_lsbrelease
        expect(lsbrelease).to eq "1.5"
      end
    end

    describe "lsbdistrelease fact" do
      it "should return the lsbdistrelease from its lsb object" do
        lsb_obj.expects(:get_lsbdistrelease).returns("1.5")
        lsbdistrelease = subject.get_lsbdistrelease
        expect(lsbdistrelease).to eq "1.5"
      end
    end

    describe "lsbmajdistrelease fact" do
      it "should return the lsbmajdistrelease from its lsb object" do
        lsb_obj.expects(:get_lsbmajdistrelease).returns("1")
        lsbmajdistrelease = subject.get_lsbmajdistrelease
        expect(lsbmajdistrelease).to eq "1"
      end
    end
  end
end

describe Facter::Operatingsystem::CumulusLinux do
  subject { described_class.new }
  let(:lsb_obj) { stub 'lsb object' }
  let(:osrelease_obj) { stub 'osrelease object' }

  before :all do
    Facter.fact(:kernel).stubs(:value).returns("Linux")
    Facter::Operatingsystem::Lsb.stubs(:new).returns lsb_obj
    Facter::Operatingsystem::Osrelease.stubs(:new).returns osrelease_obj
    subject.instance_variable_set :@operatingsystem, "CumulusLinux"
    subject.instance_variable_set :@lsb_obj, lsb_obj
    subject.instance_variable_set :@osrelease_obj, osrelease_obj
  end

  describe "Operating system fact" do
    it "should identify Cumulus Linux" do
      os = subject.operatingsystem
      expect(os).to eq "CumulusLinux"
    end
  end

  describe "Osfamily fact" do
    it "should return Debian" do
      osfamily = subject.get_osfamily
      expect(osfamily).to eq "Debian"
    end
  end

  describe "Operatingsystemrelease fact" do
    it "should return the release value from its osrelease object" do
      subject.expects(:get_operatingsystem_release).returns("1.5.0")
      release = subject.get_operatingsystem_release
      expect(release).to eq "1.5.0"
    end
  end

  describe "Operatingsystemmajrelease fact" do
    it "should return the majrelease value from its osrelease object" do
      subject.expects(:get_operatingsystem_maj_release).returns("1")
      release = subject.get_operatingsystem_maj_release
      expect(release).to eq "1"
    end
  end
end

describe Facter::Operatingsystem::Linux do
  subject { described_class.new }

  before :each do
    Facter.stubs(:value).with(:lsbdistid).returns(nil)
  end

  describe "Operating system fact" do
    describe "When lsbdistid is available" do
      before :each do
        Facter.collection.internal_loader.load(:lsb)
      end

      it "on Ubuntu should use the lsbdistid fact" do
        Facter.stubs(:value).with(:lsbdistid).returns("Ubuntu")
        os = subject.get_operatingsystem
        expect(os).to eq "Ubuntu"
      end

      it "on LinuxMint should use the lsbdistid fact" do
        Facter.stubs(:value).with(:lsbdistid).returns("LinuxMint")
        os = subject.get_operatingsystem
        expect(os).to eq "LinuxMint"
      end
    end

    describe "When lsbdistid is not available" do
     {
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
        "Slackware"   => "/etc/slackware-version",
        "Amazon"      => "/etc/system-release"
      }.each_pair do |distribution, releasefile|
        it "should be #{distribution} if #{releasefile} exists" do
          FileTest.expects(:exists?).at_least_once.returns false
          FileTest.expects(:exists?).with(releasefile).returns true
          os = subject.operatingsystem
          expect(os).to eq distribution
        end
      end
    end

    describe "on distributions that rely on the contents of /etc/redhat-release" do
      {
        "RedHat"     => "Red Hat Enterprise Linux Server release 6.0 (Santiago)",
        "CentOS"     => "CentOS release 5.6 (Final)",
        "Scientific" => "Scientific Linux release 6.0 (Carbon)",
        "SLC"        => "Scientific Linux CERN SLC release 5.7 (Boron)",
        "Ascendos"   => "Ascendos release 6.0 (Nameless)",
        "CloudLinux" => "CloudLinux Server release 5.5",
        "XenServer"  => "XenServer release 5.6.0-31188p (xenenterprise)",
      }.each_pair do |operatingsystem, string|
        it "should be #{operatingsystem} based on /etc/redhat-release contents #{string}" do
          FileTest.expects(:exists?).at_least_once.returns false
          FileTest.expects(:exists?).with("/etc/enterprise-release").returns false
          FileTest.expects(:exists?).with("/etc/redhat-release").returns true
          File.expects(:read).with("/etc/redhat-release").at_least_once.returns string
          os = subject.operatingsystem
          expect(os).to eq operatingsystem
        end
      end

      it "should be OEL if /etc/ovs-release doesn't exist" do
        FileTest.expects(:exists?).at_least_once.returns false
        FileTest.expects(:exists?).with("/etc/enterprise-release").returns true
        FileTest.expects(:exists?).with("/etc/ovs-release").returns false
        os = subject.operatingsystem
        expect(os).to eq "OEL"
      end

      it "should differentiate between Scientific Linux CERN and Scientific Linux" do
        FileTest.expects(:exists?).at_least_once.returns false
        FileTest.expects(:exists?).with("/etc/redhat-release").returns true
        FileTest.expects(:exists?).with("/etc/enterprise-release").returns false
        File.expects(:read).with("/etc/redhat-release").at_least_once.returns("Scientific Linux CERN SLC 5.7 (Boron)")
        os = subject.operatingsystem
        expect(os).to eq "SLC"
      end

      it "should default to RedHat" do
        FileTest.expects(:exists?).at_least_once.returns false
        FileTest.expects(:exists?).with("/etc/redhat-release").returns true
        FileTest.expects(:exists?).with("/etc/enterprise-release").returns false
        File.expects(:read).with("/etc/redhat-release").at_least_once.returns("Mystery RedHat")
        os = subject.operatingsystem
        expect(os).to eq "RedHat"
      end

      describe "on Oracle variants" do
        it "should be OVS if /etc/ovs-release exists" do
          FileTest.expects(:exists?).at_least_once.returns false
          FileTest.expects(:exists?).with("/etc/enterprise-release").returns true
          FileTest.expects(:exists?).with("/etc/ovs-release").returns true
          os = subject.operatingsystem
          expect(os).to eq "OVS"
        end

        it "should be OEL if /etc/ovs-release doesn't exist" do
          FileTest.expects(:exists?).at_least_once.returns false
          FileTest.expects(:exists?).with("/etc/enterprise-release").returns true
          FileTest.expects(:exists?).with("/etc/ovs-release").returns false
          os = subject.operatingsystem
          expect(os).to eq "OEL"
        end
      end
    end

    describe "on distributions that rely on the contents of /etc/SuSE-release" do
      {
        "SLES"     => "SUSE LINUX Enterprise Server",
        "SLED"     => "SUSE LINUX Enterprise Desktop",
        "OpenSuSE" => "openSUSE"
      }.each_pair do |operatingsystem, string|
        it "should be #{operatingsystem} based on /etc/SuSE-release contents #{string}" do
          FileTest.expects(:exists?).at_least_once.returns false
          FileTest.expects(:exists?).with("/etc/enterprise-release").returns false
          FileTest.expects(:exists?).with("/etc/redhat-release").returns false
          FileTest.expects(:exists?).with("/etc/SuSE-release").returns true
          File.expects(:read).with("/etc/SuSE-release").at_least_once.returns string
          os = subject.operatingsystem
          expect(os).to eq operatingsystem
        end
      end
    end
  end

  describe "Osfamily fact" do
    {
      'Archlinux'    => 'Archlinux',
      'Ubuntu'       => 'Debian',
      'Debian'       => 'Debian',
      'LinuxMint'    => 'Debian',
      'Gentoo'       => 'Gentoo',
      'Fedora'       => 'RedHat',
      'Amazon'       => 'RedHat',
      'OracleLinux'  => 'RedHat',
      'OVS'          => 'RedHat',
      'OEL'          => 'RedHat',
      'CentOS'       => 'RedHat',
      'SLC'          => 'RedHat',
      'Scientific'   => 'RedHat',
      'CloudLinux'   => 'RedHat',
      'PSBM'         => 'RedHat',
      'Ascendos'     => 'RedHat',
      'XenServer'    => 'RedHat',
      'RedHat'       => 'RedHat',
      'SLES'         => 'Suse',
      'SLED'         => 'Suse',
      'OpenSuSE'     => 'Suse',
      'SuSE'         => 'Suse',
      'Mageia'       => 'Mandrake',
      'Mandriva'     => 'Mandrake',
      'Mandrake'     => 'Mandrake',
    }.each do |os,family|
      it "should return #{family} on operatingsystem #{os}" do
        subject.instance_variable_set :@operatingsystem, os
        osfamily = subject.get_osfamily
        expect(osfamily).to eq family
      end
    end

    [
      'MeeGo',
      'VMWareESX',
      'Bluewhite64',
      'Slamd64',
      'Slackware',
      'Alpine',
    ].each do |os|
      it "should return the kernel fact on operatingsystem #{os}" do
        subject.instance_variable_set :@operatingsystem, os
        Facter.expects(:value).with("kernel").returns "Linux"
        osfamily = subject.get_osfamily
        expect(osfamily).to eq "Linux"
      end
    end
  end
end

describe Facter::Operatingsystem::SunOS do
  subject { described_class.new }

  describe "Operating system fact" do
    it "should be Nexenta if /etc/debian_version is present" do
      FileTest.expects(:exists?).with("/etc/debian_version").returns true
      os = subject.operatingsystem
      expect(os).to eq "Nexenta"
    end

    it "should be Solaris if /etc/debian_version is missing and uname -v failed to match" do
      FileTest.expects(:exists?).with("/etc/debian_version").returns false
      os = subject.operatingsystem
      expect(os).to eq "Solaris"
    end

    {
      "SmartOS"     => "joyent_20120629T002039Z",
      "OmniOS"      => "omnios-dda4bb3",
      "OpenIndiana" => "oi_151a",
    }.each_pair do |distribution, string|
      it "should be #{distribution} if uname -v is '#{string}'" do
        Facter::Core::Execution.expects(:exec).with('uname -v').returns(string)
        Facter::Util::FileRead.expects(:read).with("/etc/release").returns("Solaris 8 s28_38shwp2 SPARC")
        os = subject.operatingsystem
        expect(os).to eq distribution
      end
    end
  end
end

describe Facter::Operatingsystem::VMkernel do
  subject { described_class.new }

  describe "Operating system fact" do
    it "should be ESXi" do
      os = subject.operatingsystem
      expect(os).to eq "ESXi"
    end
  end
end
