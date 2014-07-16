#! /usr/bin/env ruby

require 'spec_helper'

describe "OS Family fact" do
  let(:operatingsystem_hash) { { "operatingsystem" => "SomeOS",
                                 "osfamily"        => "SomeFamily",
                                 "release"         => {
                                    "operatingsystemrelease"    => "1.2.3",
                                    "operatingsystemmajrelease" => "1"
                                 }
                               }
                             }

  it "should use the 'osfamily' key from the 'operatingsystem_hash' fact" do
    Facter.fact("operatingsystem_hash").stubs(:value).returns(operatingsystem_hash)
    Facter.fact(:osfamily).value.should eq "SomeFamily"
  end

end
