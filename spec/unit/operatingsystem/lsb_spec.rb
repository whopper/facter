#! /usr/bin/env ruby

require 'spec_helper'
require 'facter/operatingsystem/os'

describe Facter::Operatingsystem::Lsb do
  subject { described_class.new }

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

  end

  describe "lsbmajdistrelease fact" do
    it "should be derived from lsb_release" do
        subject.expects(:get_lsbdistrelease).returns("10.10")
        lsbmajdistrelease = subject.get_lsbmajdistrelease
        expect(lsbmajdistrelease).to eq "10"
    end
  end
end
