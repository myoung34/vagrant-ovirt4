describe command('uname -a') do
  its(:exit_status) { should eq 0 }
  its(:stderr) { should be_empty }
  its(:stdout) { should match(/^Linux kitchen-static-[0-9]+-[a-f0-9\-]+/) }
end

describe command("ip route get 1 | awk '{print $NF;exit}'") do
  its(:exit_status) { should eq 0 }
  its(:stderr) { should be_empty }
  its(:stdout) { should match(/^192.168.2.254$/) }
end
