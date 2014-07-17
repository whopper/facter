#! /usr/bin/env ruby -S rspec

require 'spec_helper'

describe "OS Major Release fact" do
  let(:os_hash) { { "name"         => "SomeOS",
                                 "family"       => "SomeFamily",
                                 "release"      => "1.2.3",
                                 "releasemajor" => "1"
                               }
                             }

  it "should use the 'releasemajor' key of the 'os' fact" do
    Facter.fact(:operatingsystem).stubs(:value).returns("Amazon")
    Facter.fact("os").stubs(:value).returns(os_hash)
    Facter.fact(:operatingsystemmajrelease).value.should eq "1"
  end
end
