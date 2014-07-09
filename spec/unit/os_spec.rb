#! /usr/bin/env ruby

require 'spec_helper'
require 'facter/operatingsystem/os'

describe "os" do
  subject { Facter.fact("os") }
  let(:os) { stub 'OS object' }
  let(:lsb_hash) { { "distcodename"    => "trusty",
                     "distid"          => "Ubuntu",
                     "distdescription" => "Ubuntu 14.04 LTS",
                     "distrelease"     => "14.04",
                     "release"         => "14.04",
                     "majdistrelease"  => "14"
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

    it "should include a name key with the operatingsystem name" do
      expect(subject.value["name"]).to eq "Ubuntu"
    end

    it "should include a family key with the osfamily name" do
      expect(subject.value["family"]).to eq "Debian"
    end

    it "should include a release key with the OS release" do
      expect(subject.value["release"]).to eq "14.04"
    end

    it "should include a releasemajor key with the major release" do
      expect(subject.value["releasemajor"]).to eq "14"
    end

    it "should include a distid key with the distid" do
      expect(subject.value["lsb"]["distid"]).to eq "Ubuntu"
    end

    it "should include an distcodename key with the codename" do
      expect(subject.value["lsb"]["distcodename"]).to eq "trusty"
    end

    it "should include an distdescription key with the description" do
      expect(subject.value["lsb"]["distdescription"]).to eq "Ubuntu 14.04 LTS"
    end

    it "should include an release key with the release" do
      expect(subject.value["lsb"]["release"]).to eq "14.04"
    end

    it "should include an distrelease key with the release" do
      expect(subject.value["lsb"]["distrelease"]).to eq "14.04"
    end

    it "should include an majdistrelease key with the major release" do
      expect(subject.value["lsb"]["majdistrelease"]).to eq "14"
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

    it "should include a name key with the operatingsystem name" do
      expect(subject.value["name"]).to eq "Darwin"
    end

    it "should include a family key with the osfamily name" do
      expect(subject.value["family"]).to eq "Darwin"
    end

    it "should include a release key with the OS release" do
      expect(subject.value["release"]).to eq "13.3.0"
    end

    it "should include a releasemajor with the major release" do
      expect(subject.value["releasemajor"]).to eq "13"
    end

    it "should not include an lsb key" do
      expect(subject.value["lsb"]).to be_nil
    end
  end
end
