#! /usr/bin/env ruby

require 'spec_helper'
require 'facter/operatingsystem/os'

describe "operatingsystem_hash" do
  subject { Facter.fact("operatingsystem_hash") }
  let(:os) { stub 'OS object' }
  let(:lsb_hash) { { "lsbdistcodename"    => "trusty",
                     "lsbdistid"          => "Ubuntu",
                     "lsbdistdescription" => "Ubuntu 14.04 LTS",
                     "lsbdistrelease"     => "14.04",
                     "lsbrelease"         => "14.04",
                     "lsbmajdistrelease"  => "14"
                   }
                }

  describe "in Linux with lsb facts available" do
    before do
      Facter::Operatingsystem::Linux.stubs(:new).returns os
    end

    before :each do
      Facter.fact(:kernel).stubs(:value).returns("Linux")
      os.expects(:get_operatingsystem).returns("Ubuntu")
      os.expects(:get_osfamily).returns("Debian")
      os.expects(:get_operatingsystemrelease).returns("14.04")
      os.expects(:get_operatingsystemmajrelease).returns("14")
      os.expects(:get_lsb_facts_hash).returns(lsb_hash)
    end

    it "should include an operatingsystem key with the operatingsystem name" do
      expect(subject.value["operatingsystem"]).to eq "Ubuntu"
    end

    it "should include an osfamily key with the osfamily name" do
      expect(subject.value["osfamily"]).to eq "Debian"
    end

    it "should include an operatingsystemrelease key with the OS release" do
      expect(subject.value["release"]["operatingsystemrelease"]).to eq "14.04"
    end

    it "should include an operatingsystemmajrelease with the major release" do
      expect(subject.value["release"]["operatingsystemmajrelease"]).to eq "14"
    end

    it "should include an lsb_distid key with the distid" do
      expect(subject.value["lsb"]["lsbdistid"]).to eq "Ubuntu"
    end

    it "should include an lsb_distcodename key with the codename" do
      expect(subject.value["lsb"]["lsbdistcodename"]).to eq "trusty"
    end

    it "should include an lsbdistdescription key with the description" do
      expect(subject.value["lsb"]["lsbdistdescription"]).to eq "Ubuntu 14.04 LTS"
    end

    it "should include an lsb_release key with the release" do
      expect(subject.value["lsb"]["lsbrelease"]).to eq "14.04"
    end

    it "should include an lsb_distrelease key with the release" do
      expect(subject.value["lsb"]["lsbdistrelease"]).to eq "14.04"
    end

    it "should include an lsb_majdistrelease key with the major release" do
      expect(subject.value["lsb"]["lsbmajdistrelease"]).to eq "14"
    end

  end

  describe "in an OS without lsb facts available" do
    before do
      Facter::Operatingsystem::Base.stubs(:new).returns os
    end

    before :each do
      Facter.fact(:kernel).stubs(:value).returns("Darwin")
      os.expects(:get_operatingsystem).returns("Darwin")
      os.expects(:get_osfamily).returns("Darwin")
      os.expects(:get_operatingsystemrelease).returns("13.3.0")
      os.expects(:get_operatingsystemmajrelease).returns("13")
      os.expects(:get_lsb_facts_hash).returns(nil)
    end

    it "should include an operatingsystem key with the operatingsystem name" do
      expect(subject.value["operatingsystem"]).to eq "Darwin"
    end

    it "should include an osfamily key with the osfamily name" do
      expect(subject.value["osfamily"]).to eq "Darwin"
    end

    it "should include an operatingsystemrelease key with the OS release" do
      expect(subject.value["release"]["operatingsystemrelease"]).to eq "13.3.0"
    end

    it "should include an operatingsystemmajrelease with the major release" do
      expect(subject.value["release"]["operatingsystemmajrelease"]).to eq "13"
    end

    it "should not include an lsb key" do
      expect(subject.value["lsb"]).to be_nil
    end
  end
end
