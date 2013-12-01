TARGET="libssl0.9.8_0.9.8o-4squeeze14_amd64.deb"
TDAGENT="td-agent_1.1.17-1_amd64.deb"

execute "apt_get_update" do
  command "apt-get update"
end

%w{build-essential libxml2-dev libxslt1-dev libyaml-dev}.each do |pkgs|
  package pkgs do
    action :install
  end
end

execute "install_#{TARGET}" do
  command "dpkg -i /tmp/#{TARGET}"
  action :nothing
end

remote_file "/tmp/#{TARGET}" do
  source "http://ftp.us.debian.org/debian/pool/main/o/openssl/#{TARGET}"
  action :create
  not_if {File.exists?("/tmp/#{TARGET}")}
  notifies :run, "execute[install_#{TARGET}]", :immediately
end

execute "install_#{TDAGENT}" do
  command "dpkg -i /tmp/#{TDAGENT}"
  action :nothing
end

remote_file "/tmp/#{TDAGENT}" do
  source "http://packages.treasure-data.com/debian/pool/contrib/t/td-agent/#{TDAGENT}"
  action :create
  not_if {File.exists?("/tmp/#{TDAGENT}")}
  notifies :run, "execute[install_#{TDAGENT}]", :immediately
end

service "td-agent" do
  supports :status => true, :start => true, :restart => true
  action :restart
end
