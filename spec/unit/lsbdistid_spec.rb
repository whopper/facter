#! /usr/bin/env ruby

require 'spec_helper'

describe "lsbdistcodename fact" do
  let(:operatingsystem_hash) { { "operatingsystem" => "SomeOS",
                                 "osfamily"        => "SomeFamily",
                                 "release"         => {
                                    "operatingsystemrelease"    => "1.2.3",
                                    "operatingsystemmajrelease" => "1"
                                 },
                                 "lsb"             => {
                                    "lsbdistcodename"    => "SomeCodeName",
                                    "lsbdistid"          => "SomeID",
                                    "lsbdistdescription" => "SomeDesc",
                                    "lsbdistrelease"     => "1.2.3",
                                    "lsbrelease"         => "1.2.3",
                                    "lsbmajdistrelease"  => "1"
                                 },
                               }
                             }

  it "should use the 'lsbdistcodename' key from the 'operatingsystem_hash' fact" do
    Facter.fact(:kernel).stubs(:value).returns("Linux")
    Facter.fact("operatingsystem_hash").stubs(:value).returns(operatingsystem_hash)
    Facter.fact(:lsbdistid).value.should eq "SomeID"
  end
end
