#! /usr/bin/env ruby

require 'spec_helper'

describe "lsbdistrelease fact" do
  let(:os_hash) { { "name"          => "SomeOS",
                    "family"        => "SomeFamily",
                    "release"       => "1.2.3",
                    "releasemajor"  => "1",
                    "lsb"           => {
                       "distcodename"    => "SomeCodeName",
                       "distid"          => "SomeID",
                       "distdescription" => "SomeDesc",
                       "distrelease"     => "1.2.3",
                       "release"         => "1.2.3",
                       "majdistrelease"  => "1"
                    },
                  }
                }

  it "should use the 'distrelease' key of the 'os' fact" do
    Facter.fact(:kernel).stubs(:value).returns("Linux")
    Facter.fact("os").stubs(:value).returns(os_hash)
    Facter.fact(:lsbdistrelease).value.should eq "1.2.3"
  end
end
