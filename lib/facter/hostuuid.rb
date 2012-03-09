Facter.add(:hostuuid) do
  confine :kernel => :freebsd
  setcode do
    Facter::Core::Execution.exec('sysctl -n kern.hostuuid')
  end
end
