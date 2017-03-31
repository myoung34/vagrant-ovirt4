describe command('dmidecode -s system-serial-number') do
  its(:exit_status) { should eq 0 }
  its(:stderr) { should be_empty }
  its(:stdout) { should match(/^banana-hammock$/) }
end

