#! /usr/bin/env ruby
#
require 'spec_helper'
require 'facter/operatingsystem/os'

describe Facter::Operatingsystem do

  it "should return an object of type Linux for linux kernels that are not Cumulus Linux" do
    Facter.fact(:kernel).stubs(:value).returns("Linux")
    Facter::Util::Operatingsystem.expects(:os_release).at_least_once.returns({'NAME' => 'Some Linux'})
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
      os = subject.get_operatingsystem
      expect(os).to eq "Nutmeg"
    end
  end

  describe "Osfamily fact" do
    it "should default to the kernel name" do
      osfamily = subject.get_osfamily
      expect(osfamily).to eq "Nutmeg"
    end
  end

  describe "lsb facts" do
    it "should return nil for the lsb facts by default" do
      lsbhash = subject.get_lsb_facts_hash
      expect(lsbhash).to be_nil
    end
  end

  describe "Operatingsystemrelease fact" do
    it "should return the kernel fact by default" do
      Facter.fact(:kernelrelease).stubs(:value).returns("1.2.3")
      operatingsystemrelease = subject.get_operatingsystemrelease
      expect(operatingsystemrelease).to eq "1.2.3"
    end
  end

  describe "Operatingsystemmajrelease fact" do
    it "should return nil by default" do
      operatingsystemmajrelease = subject.get_operatingsystemmajrelease
      expect(operatingsystemmajrelease).to be_nil
    end
  end
end


describe Facter::Operatingsystem::Linux do
  subject { described_class.new }

  describe "Operating system fact" do
    describe "When lsbdistid is available" do
      it "on Ubuntu should use the lsbdistid fact" do
        subject.expects(:get_lsbdistid).returns("Ubuntu")
        os = subject.get_operatingsystem
        expect(os).to eq "Ubuntu"
      end

      it "on LinuxMint should use the lsbdistid fact" do
        subject.expects(:get_lsbdistid).returns("LinuxMint")
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
          subject.expects(:get_lsbdistid).returns(nil)
          FileTest.expects(:exists?).at_least_once.returns false
          FileTest.expects(:exists?).with(releasefile).returns true
          os = subject.get_operatingsystem
          expect(os).to eq distribution
        end
      end
    end

    describe "on distributions that rely on the contents of /etc/redhat-release" do
      before :each do
        subject.expects(:get_lsbdistid).returns(nil)
      end

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
          os = subject.get_operatingsystem
          expect(os).to eq operatingsystem
        end
      end

      it "should be OEL if /etc/ovs-release doesn't exist" do
        FileTest.expects(:exists?).at_least_once.returns false
        FileTest.expects(:exists?).with("/etc/enterprise-release").returns true
        FileTest.expects(:exists?).with("/etc/ovs-release").returns false
        os = subject.get_operatingsystem
        expect(os).to eq "OEL"
      end

      it "should differentiate between Scientific Linux CERN and Scientific Linux" do
        FileTest.expects(:exists?).at_least_once.returns false
        FileTest.expects(:exists?).with("/etc/redhat-release").returns true
        FileTest.expects(:exists?).with("/etc/enterprise-release").returns false
        File.expects(:read).with("/etc/redhat-release").at_least_once.returns("Scientific Linux CERN SLC 5.7 (Boron)")
        os = subject.get_operatingsystem
        expect(os).to eq "SLC"
      end

      it "should default to RedHat" do
        FileTest.expects(:exists?).at_least_once.returns false
        FileTest.expects(:exists?).with("/etc/redhat-release").returns true
        FileTest.expects(:exists?).with("/etc/enterprise-release").returns false
        File.expects(:read).with("/etc/redhat-release").at_least_once.returns("Mystery RedHat")
        os = subject.get_operatingsystem
        expect(os).to eq "RedHat"
      end

      describe "on Oracle variants" do
        it "should be OVS if /etc/ovs-release exists" do
          FileTest.expects(:exists?).at_least_once.returns false
          FileTest.expects(:exists?).with("/etc/enterprise-release").returns true
          FileTest.expects(:exists?).with("/etc/ovs-release").returns true
          os = subject.get_operatingsystem
          expect(os).to eq "OVS"
        end

        it "should be OEL if /etc/ovs-release doesn't exist" do
          FileTest.expects(:exists?).at_least_once.returns false
          FileTest.expects(:exists?).with("/etc/enterprise-release").returns true
          FileTest.expects(:exists?).with("/etc/ovs-release").returns false
          os = subject.get_operatingsystem
          expect(os).to eq "OEL"
        end
      end
    end

    describe "on distributions that rely on the contents of /etc/SuSE-release" do
      before :each do
        subject.expects(:get_lsbdistid).returns(nil)
      end

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
          os = subject.get_operatingsystem
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
        subject.expects(:get_operatingsystem).returns(os)
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
        Facter.expects(:value).with("kernel").returns "Linux"
        subject.expects(:get_operatingsystem).returns(os)
        osfamily = subject.get_osfamily
        expect(osfamily).to eq "Linux"
      end
    end
  end

  describe "Operatingsystemrelease fact" do
    test_cases = {
      "OpenWrt"    => "/etc/openwrt_version",
      "CentOS"    => "/etc/redhat-release",
      "RedHat"    => "/etc/redhat-release",
      "LinuxMint"   => "/etc/linuxmint/info",
      "Scientific"  => "/etc/redhat-release",
      "Fedora"    => "/etc/fedora-release",
      "MeeGo"     => "/etc/meego-release",
      "OEL"     => "/etc/enterprise-release",
      "oel"     => "/etc/enterprise-release",
      "OVS"     => "/etc/ovs-release",
      "ovs"     => "/etc/ovs-release",
      "OracleLinux" => "/etc/oracle-release",
      "Ascendos"    => "/etc/redhat-release",
    }

    test_cases.each do |system, file|
      describe "with operatingsystem reported as #{system}" do
        it "should read #{file}" do
          subject.expects(:get_operatingsystem).at_least_once.returns(system)
          Facter::Util::FileRead.expects(:read).with(file).at_least_once
          release = subject.get_operatingsystemrelease
        end
      end
    end

    it "should not include trailing whitespace on Debian" do
      subject.expects(:get_operatingsystem).returns("Debian")
      Facter::Util::FileRead.expects(:read).returns("6.0.6\n")
      release = subject.get_operatingsystemrelease
      expect(release).to eq "6.0.6"
    end

    it "should run the vmware -v command in VMWareESX" do
      Facter.fact(:kernel).stubs(:value).returns("VMkernel")
      Facter.fact(:kernelrelease).stubs(:value).returns("4.1.0")
      subject.expects(:get_operatingsystem).returns("VMwareESX")
      Facter::Core::Execution.expects(:exec).with('vmware -v').returns("VMware ESX 4.1.0")
      release = subject.get_operatingsystemrelease
      expect(release).to eq "4.1.0"
    end

    it "should use the contents of /etc/alpine-release in Alpine" do
      subject.expects(:get_operatingsystem).returns("Alpine")
      File.expects(:read).with("/etc/alpine-release").returns("foo")
      release = subject.get_operatingsystemrelease
      expect(release).to eq "foo"
    end

    it "should fall back to kernelrelease fact if lsb facts are not available in Amazon" do
      Facter.fact(:kernelrelease).stubs(:value).returns("1.2.3")
      subject.expects(:get_operatingsystem).returns("Amazon")
      subject.expects(:get_lsbdistrelease).returns(nil)
      release = subject.get_operatingsystemrelease
      expect(release).to eq "1.2.3"
    end

    describe "with operatingsystem reported as Ubuntu" do
      let(:lsbrelease) { 'DISTRIB_ID=Ubuntu\nDISTRIB_RELEASE=10.04\nDISTRIB_CODENAME=lucid\nDISTRIB_DESCRIPTION="Ubuntu 10.04.4 LTS"'}

      it "Returns only the major and minor version (not patch version)" do
        Facter::Util::FileRead.expects(:read).with("/etc/lsb-release").returns(lsbrelease)
        subject.expects(:get_operatingsystem).returns("Ubuntu")
        release = subject.get_operatingsystemrelease
        expect(release).to eq "10.04"
      end
    end
  end

  describe "Operatingsystemmajrelease fact" do
    ['Amazon','CentOS','CloudLinux','Debian','Fedora','OEL','OracleLinux','OVS','RedHat','Scientific','SLC','CumulusLinux'].each do |operatingsystem|
      describe "on #{operatingsystem} operatingsystems" do
        it "should be derived from operatingsystemrelease" do
          subject.expects(:get_operatingsystem).returns(operatingsystem)
          subject.expects(:get_operatingsystemrelease).returns("6.3")
          release = subject.get_operatingsystemmajrelease
          expect(release).to eq "6"
        end
      end
    end
  end

  describe "Lsb facts" do
    let(:lsb_hash) { { "lsbdistcodename"    => "SomeCodeName",
                       "lsbdistid"          => "SomeID",
                       "lsbdistdescription" => "Some Desc",
                       "lsbdistrelease"     => "1.2.3",
                       "lsbrelease"         => "1.2.3",
                       "lsbmajdistrelease"  => "1"
                     }
                  }

    before :each do
    end

    describe "lsbdistcodename fact" do
      [ "Linux", "GNU/kFreeBSD"].each do |kernel|
        describe "on #{kernel}" do
          it "returns the codename through lsb_release -c -s 2>/dev/null" do
            Facter::Core::Execution.expects(:exec).with('lsb_release -c -s 2>/dev/null', anything).returns 'n/a'
            lsbdistcodename = subject.get_lsbdistcodename
            expect(lsbdistcodename).to eq 'n/a'
          end

          it "returns nil if lsb_release is not installed" do
            Facter::Core::Execution.expects(:exec).with('lsb_release -c -s 2>/dev/null').returns nil
            lsbdistcodename = subject.get_lsbdistcodename
            expect(lsbdistcodename).to be_nil
          end
        end
      end

      it "should return the lsbdistcodename" do
        subject.expects(:get_lsb_facts_hash).returns(lsb_hash)
        lsbdistcodename = subject.get_lsb_facts_hash["lsbdistcodename"]
        expect(lsbdistcodename).to eq "SomeCodeName"
      end
    end

    describe "lsbdistid fact" do
      [ "Linux", "GNU/kFreeBSD"].each do |kernel|
        describe "on #{kernel}" do
          it "returns the id through lsb_release -i -s 2>/dev/null" do
            Facter::Core::Execution.expects(:exec).with('lsb_release -i -s 2>/dev/null', anything).returns 'Gentoo'
            lsbdistid = subject.get_lsbdistid
            expect(lsbdistid).to eq 'Gentoo'
          end

          it "returns nil if lsb_release is not installed" do
            Facter::Core::Execution.expects(:exec).with('lsb_release -i -s 2>/dev/null').returns nil
            lsbdistid = subject.get_lsbdistid
            expect(lsbdistid).to be_nil
          end
        end
      end

      it "should return the lsbdistid" do
        subject.expects(:get_lsb_facts_hash).returns(lsb_hash)
        lsbdistid = subject.get_lsb_facts_hash["lsbdistid"]
        expect(lsbdistid).to eq "SomeID"
      end
    end

    describe "lsbdistdescription fact" do
      [ "Linux", "GNU/kFreeBSD"].each do |kernel|
        describe "on #{kernel}" do
          it "returns the description through lsb_release -d -s 2>/dev/null" do
            Facter::Core::Execution.expects(:exec).with('lsb_release -d -s 2>/dev/null', anything).returns '"Gentoo Base System release 2.1"'
            lsbdistdescription = subject.get_lsbdistdescription
            expect(lsbdistdescription).to eq 'Gentoo Base System release 2.1'
          end

          it "returns nil if lsb_release is not installed" do
            Facter::Core::Execution.expects(:exec).with('lsb_release -d -s 2>/dev/null').returns nil
            lsbdistdescription = subject.get_lsbdistdescription
            expect(lsbdistdescription).to be_nil
          end
        end
      end

      it "should return the lsbdistdescription" do
        subject.expects(:get_lsb_facts_hash).returns(lsb_hash)
        lsbdistdescription = subject.get_lsb_facts_hash["lsbdistdescription"]
        expect(lsbdistdescription).to eq "Some Desc"
      end
    end

    describe "lsbrelease fact" do
      [ "Linux", "GNU/kFreeBSD"].each do |kernel|
        describe "on #{kernel}" do
          it "returns the release through lsb_release -v -s 2>/dev/null" do
            Facter::Core::Execution.expects(:exec).with('lsb_release -v -s 2>/dev/null', anything).returns 'n/a'
            lsbrelease = subject.get_lsbrelease
            expect(lsbrelease).to eq 'n/a'
          end

          it "returns nil if lsb_release is not installed" do
            Facter::Core::Execution.expects(:exec).with('lsb_release -v -s 2>/dev/null').returns nil
            lsbrelease = subject.get_lsbrelease
            expect(lsbrelease).to be_nil
          end
        end
      end

      it "should return the lsbrelease" do
        subject.expects(:get_lsb_facts_hash).returns(lsb_hash)
        lsbrelease = subject.get_lsb_facts_hash["lsbrelease"]
        expect(lsbrelease).to eq "1.2.3"
      end
    end

    describe "lsbdistrelease fact" do
      [ "Linux", "GNU/kFreeBSD"].each do |kernel|
        describe "on #{kernel}" do
          it "should return the release through lsb_release -r -s 2>/dev/null" do
            Facter::Core::Execution.expects(:exec).with('lsb_release -r -s 2>/dev/null', anything).returns '2.1'
            lsbdistrelease = subject.get_lsbdistrelease
            expect(lsbdistrelease).to eq '2.1'
          end

          it "should return nil if lsb_release is not installed" do
            Facter::Core::Execution.expects(:exec).with('lsb_release -r -s 2>/dev/null', anything).returns nil
            lsbdistrelease = subject.get_lsbdistrelease
            expect(lsbdistrelease).to be_nil
          end
        end
      end

      it "should return the lsbdistrelease" do
        subject.expects(:get_lsb_facts_hash).returns(lsb_hash)
        lsbdistrelease = subject.get_lsb_facts_hash["lsbdistrelease"]
        expect(lsbdistrelease).to eq "1.2.3"
      end
    end

    describe "lsbmajdistrelease fact" do

      it "should be derived from lsb_release" do
        subject.expects(:get_lsbdistrelease).returns("10.10")
        lsbmajdistrelease = subject.get_lsbmajdistrelease
        expect(lsbmajdistrelease).to eq "10"
      end

      it "should return the lsbmajdistrelease" do
        subject.expects(:get_lsb_facts_hash).returns(lsb_hash)
        lsbmajdistrelease = subject.get_lsb_facts_hash["lsbmajdistrelease"]
        expect(lsbmajdistrelease).to eq "1"
      end
    end
  end
end

describe Facter::Operatingsystem::CumulusLinux do
  subject { described_class.new }

  before :all do
    Facter.fact(:kernel).stubs(:value).returns("Linux")
  end

  describe "Operating system fact" do
    it "should identify Cumulus Linux" do
      os = subject.get_operatingsystem
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
    it "uses '/etc/os-release" do
      Facter::Util::Operatingsystem.expects(:os_release).returns({"VERSION_ID" => "1.5.0"})
      release = subject.get_operatingsystemrelease
      expect(release).to eq "1.5.0"
    end
  end

  describe "Operatingsystemmajrelease fact" do
    it "should return the majrelease value based on its operatingsystemrelease" do
      subject.expects(:get_operatingsystemrelease).returns("1.5.0")
      release = subject.get_operatingsystemmajrelease
      expect(release).to eq "1"
    end
  end
end

describe Facter::Operatingsystem::SunOS do
  subject { described_class.new }

  describe "Operating system fact" do
    it "should be Nexenta if /etc/debian_version is present" do
      FileTest.expects(:exists?).with("/etc/debian_version").returns true
      os = subject.get_operatingsystem
      expect(os).to eq "Nexenta"
    end

    it "should be Solaris if /etc/debian_version is missing and uname -v failed to match" do
      FileTest.expects(:exists?).with("/etc/debian_version").returns false
      os = subject.get_operatingsystem
      expect(os).to eq "Solaris"
    end

    {
      "SmartOS"     => "joyent_20120629T002039Z",
      "OmniOS"      => "omnios-dda4bb3",
      "OpenIndiana" => "oi_151a",
    }.each_pair do |distribution, string|
      it "should be #{distribution} if uname -v is '#{string}'" do
        Facter::Core::Execution.expects(:exec).with('uname -v').returns(string)
        os = subject.get_operatingsystem
        expect(os).to eq distribution
      end
    end
  end

  describe "Osfamily fact" do
    it "should return Solaris" do
      osfamily = subject.get_osfamily
      expect(osfamily).to eq "Solaris"
    end
  end

  describe "Operatingsystemrelease fact" do
    {
      'Solaris 8 s28_38shwp2 SPARC'                  => '28',
      'Solaris 8 6/00 s28s_u1wos_08 SPARC'           => '28_u1',
      'Solaris 8 10/00 s28s_u2wos_11b SPARC'         => '28_u2',
      'Solaris 8 1/01 s28s_u3wos_08 SPARC'           => '28_u3',
      'Solaris 8 4/01 s28s_u4wos_08 SPARC'           => '28_u4',
      'Solaris 8 7/01 s28s_u5wos_08 SPARC'           => '28_u5',
      'Solaris 8 10/01 s28s_u6wos_08a SPARC'         => '28_u6',
      'Solaris 8 2/02 s28s_u7wos_08a SPARC'          => '28_u7',
      'Solaris 8 HW 12/02 s28s_hw1wos_06a SPARC'     => '28',
      'Solaris 8 HW 5/03 s28s_hw2wos_06a SPARC'      => '28',
      'Solaris 8 HW 7/03 s28s_hw3wos_05a SPARC'      => '28',
      'Solaris 8 2/04 s28s_hw4wos_05a SPARC'         => '28',
      'Solaris 9 s9_58shwpl3 SPARC'                  => '9',
      'Solaris 9 9/02 s9s_u1wos_08b SPARC'           => '9_u1',
      'Solaris 9 12/02 s9s_u2wos_10 SPARC'           => '9_u2',
      'Solaris 9 4/03 s9s_u3wos_08 SPARC'            => '9_u3',
      'Solaris 9 8/03 s9s_u4wos_08a SPARC'           => '9_u4',
      'Solaris 9 12/03 s9s_u5wos_08b SPARC'          => '9_u5',
      'Solaris 9 4/04 s9s_u6wos_08a SPARC'           => '9_u6',
      'Solaris 9 9/04 s9s_u7wos_09 SPARC'            => '9_u7',
      'Solaris 9 9/05 s9s_u8wos_05 SPARC'            => '9_u8',
      'Solaris 9 9/05 HW s9s_u9wos_06b SPARC'        => '9_u9',
      'Solaris 10 3/05 s10_74L2a SPARC'              => '10',
      'Solaris 10 3/05 HW1 s10s_wos_74L2a SPARC'     => '10',
      'Solaris 10 3/05 HW2 s10s_hw2wos_05 SPARC'     => '10',
      'Solaris 10 1/06 s10s_u1wos_19a SPARC'         => '10_u1',
      'Solaris 10 6/06 s10s_u2wos_09a SPARC'         => '10_u2',
      'Solaris 10 11/06 s10s_u3wos_10 SPARC'         => '10_u3',
      'Solaris 10 8/07 s10s_u4wos_12b SPARC'         => '10_u4',
      'Solaris 10 5/08 s10s_u5wos_10 SPARC'          => '10_u5',
      'Solaris 10 10/08 s10s_u6wos_07b SPARC'        => '10_u6',
      'Solaris 10 5/09 s10s_u7wos_08 SPARC'          => '10_u7',
      'Solaris 10 10/09 s10s_u8wos_08a SPARC'        => '10_u8',
      'Oracle Solaris 10 9/10 s10s_u9wos_14a SPARC'  => '10_u9',
      'Oracle Solaris 10 8/11 s10s_u10wos_17b SPARC' => '10_u10',
      'Solaris 10 3/05 HW1 s10x_wos_74L2a X86'       => '10',
      'Solaris 10 1/06 s10x_u1wos_19a X86'           => '10_u1',
      'Solaris 10 6/06 s10x_u2wos_09a X86'           => '10_u2',
      'Solaris 10 11/06 s10x_u3wos_10 X86'           => '10_u3',
      'Solaris 10 8/07 s10x_u4wos_12b X86'           => '10_u4',
      'Solaris 10 5/08 s10x_u5wos_10 X86'            => '10_u5',
      'Solaris 10 10/08 s10x_u6wos_07b X86'          => '10_u6',
      'Solaris 10 5/09 s10x_u7wos_08 X86'            => '10_u7',
      'Solaris 10 10/09 s10x_u8wos_08a X86'          => '10_u8',
      'Oracle Solaris 10 9/10 s10x_u9wos_14a X86'    => '10_u9',
      'Oracle Solaris 10 9/10 s10x_u9wos_14a X86'    => '10_u9',
      'Oracle Solaris 10 8/11 s10x_u10wos_17b X86'   => '10_u10',
      'Oracle Solaris 11 11/11 X86'                  => '11 11/11',
      'Oracle Solaris 11.1 SPARC'                    => '11.1'
    }.each do |fakeinput, expected_output|
      it "should be able to parse a release of #{fakeinput}" do
        Facter::Util::FileRead.expects(:read).with("/etc/release").returns fakeinput
        release = subject.get_operatingsystemrelease
        expect(release).to eq expected_output
      end
    end

    context "malformed /etc/release files" do
      it "should fallback to the kernelrelease fact if /etc/release is empty" do
        Facter::Util::FileRead.expects(:read).with('/etc/release').returns("")
        release = subject.get_operatingsystemrelease
        expect(release).to eq Facter.fact(:kernelrelease).value
      end

      it "should fallback to the kernelrelease fact if /etc/release is not present" do
        Facter::Util::FileRead.expects(:read).with('/etc/release').returns false
        release = subject.get_operatingsystemrelease
        expect(release).to eq Facter.fact(:kernelrelease).value
      end

      it "should fallback to the kernelrelease fact if /etc/release cannot be parsed" do
        Facter::Util::FileRead.expects(:read).with('/etc/release').returns 'some future release string'
        release = subject.get_operatingsystemrelease
        expect(release).to eq Facter.fact(:kernelrelease).value
      end
    end
  end

  describe "Operatingsystemmajrelease fact" do
    before :each do
      Facter.fact(:kernel).stubs(:value).returns("SunOS")
      subject.expects(:get_operatingsystem).returns("Solaris")
    end

    it "should correctly derive from operatingsystemrelease on solaris 10" do
      subject.expects(:get_operatingsystemrelease).returns("10_u8")
      release = subject.get_operatingsystemmajrelease
      expect(release).to eq "10"
    end

    it "should correctly derive from operatingsystemrelease on solaris 11 (old version scheme)" do
      subject.expects(:get_operatingsystemrelease).returns("11 11/11")
      release = subject.get_operatingsystemmajrelease
      expect(release).to eq "11"
    end

    it "should correctly derive from operatingsystemrelease on solaris 11 (new version scheme)" do
      subject.expects(:get_operatingsystemrelease).returns("11.1")
      release = subject.get_operatingsystemmajrelease
      expect(release).to eq "11"
    end
  end
end

describe Facter::Operatingsystem::VMkernel do
  subject { described_class.new }

  describe "Operating system fact" do
    it "should be ESXi" do
      os = subject.get_operatingsystem
      expect(os).to eq "ESXi"
    end
  end
end

describe Facter::Operatingsystem::Windows do
  require 'facter/util/wmi'
  subject { described_class.new }

  describe "Operatingsystemrelease fact" do
    before do
      Facter.fact(:kernel).stubs(:value).returns("windows")
    end

    {
      ['5.2.3790', 1] => "XP",
      ['6.0.6002', 1] => "Vista",
      ['6.0.6002', 2] => "2008",
      ['6.0.6002', 3] => "2008",
      ['6.1.7601', 1] => "7",
      ['6.1.7601', 2] => "2008 R2",
      ['6.1.7601', 3] => "2008 R2",
      ['6.2.9200', 1] => "8",
      ['6.2.9200', 2] => "2012",
      ['6.2.9200', 3] => "2012",
    }.each do |os_values, expected_output|
      it "should be #{expected_output}  with Version #{os_values[0]}  and ProductType #{os_values[1]}" do
        os = mock('os', :version => os_values[0], :producttype => os_values[1])
        Facter::Util::WMI.expects(:execquery).returns([os])
        release = subject.get_operatingsystemrelease
        expect(release).to eq expected_output
      end
    end

    {
      ['5.2.3790', 2, ""]   => "2003",
      ['5.2.3790', 2, "R2"] => "2003 R2",
      ['5.2.3790', 3, ""]   => "2003",
      ['5.2.3790', 3, "R2"] => "2003 R2",
    }.each do |os_values, expected_output|
      it "should be #{expected_output}  with Version #{os_values[0]}  and ProductType #{os_values[1]} and OtherTypeDescription #{os_values[2]}" do
        os = mock('os', :version => os_values[0], :producttype => os_values[1], :othertypedescription => os_values[2])
        Facter::Util::WMI.expects(:execquery).returns([os])
        release = subject.get_operatingsystemrelease
        expect(release).to eq expected_output
      end
    end

    it "reports '2003' if the WMI method othertypedescription does not exist" do
      os = mock('os', :version => '5.2.3790', :producttype => 2)
      os.stubs(:othertypedescription).raises(NoMethodError)
      Facter::Util::WMI.expects(:execquery).returns([os])
      release = subject.get_operatingsystemrelease
      expect(release).to eq "2003"
    end

    context "Unknown Windows version" do
      before :each do
        Facter.fact(:kernelrelease).stubs(:value).returns("X.Y.ZZZZ")
      end

      it "should be kernel version value with unknown values " do
        os = mock('os', :version => "X.Y.ZZZZ")
        Facter::Util::WMI.expects(:execquery).returns([os])
        release = subject.get_operatingsystemrelease
        expect(release).to eq "X.Y.ZZZZ"
      end
    end
  end
end
