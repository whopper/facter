#! /usr/bin/env ruby -S rspec

require 'spec_helper'

describe "OS Major Release fact" do
  let(:operatingsystem_hash) { { "operatingsystem" => "SomeOS",
                                 "osfamily"        => "SomeFamily",
                                 "release"         => {
                                    "operatingsystemrelease"    => "1.2.3",
                                    "operatingsystemmajrelease" => "1"
                                 }
                               }
                             }

  it "should use the 'operatingsystemmajrelease' key from the 'operatingsystem_hash' fact" do
    Facter.fact(:operatingsystem).stubs(:value).returns("Amazon")
    Facter.fact("operatingsystem_hash").stubs(:value).returns(operatingsystem_hash)
    Facter.fact(:operatingsystemmajrelease).value.should eq "1"
  end
end
