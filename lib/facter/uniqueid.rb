Facter.add(:uniqueid) do
  setcode 'hostid'
  confine :kernel => %w{SunOS Linux AIX GNU/kFreeBSD}
end

Facter.add(:uniqueid) do
  confine :kernel => :freebsd
  setcode do
    Facter::Core::Execution.exec('sysctl -n kern.hostid')
  end
end
