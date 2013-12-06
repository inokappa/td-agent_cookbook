TDAGENT="1.1.17"

%w{libxslt1.1 libyaml-0-2}.each do |packages|
  package packages do
    action :install
  end
end

platform = node['platform']
if platform = "debian"
  package 'monit' do
      action :install
  end
else
  package 'monit' do
      action :nothing
  end
end

directory "/etc/monit/monitrc.d" do
  owner "root"
  group "root"
  mode "00755"
  action :create
  not_if {File.exists?("/etc/monit/monitrc.d")}
end

template "/etc/monit/monitrc" do
  source "monitrc.erb"
  owner "root"
  group "root"
  mode "00644"
  action :create
end

template "/etc/monit/conf.d/td-agent.conf" do
  source "monit_td-agent.conf.erb"
  owner "root"
  group "root"
  mode "00644"
  action :create
  only_if {File.exists?("/etc/monit/conf.d")}
end

remote_file "/tmp/libssl0.9.8_0.9.8o-4squeeze14_amd64.deb" do
  source "http://ftp.us.debian.org/debian/pool/main/o/openssl/libssl0.9.8_0.9.8o-4squeeze14_amd64.deb"
  owner "root"
  group "root"
  mode 00644
  action :create
end

version = node['platform_version'].to_f
if (version >= 7.0)
  execute "install_openssl_0.9.8" do
    command "dpkg -i /tmp/libssl0.9.8_0.9.8o-4squeeze14_amd64.deb"
    action :run
    only_if {File.exists?("/tmp/libssl0.9.8_0.9.8o-4squeeze14_amd64.deb")}
  end
else
  execute "install_openssl_0.9.8" do
    command "dpkg -i /tmp/libssl0.9.8_0.9.8o-4squeeze14_amd64.deb"
    action :nothing
    only_if {File.exists?("/tmp/libssl0.9.8_0.9.8o-4squeeze14_amd64.deb")}
  end
end

execute "install_td-agent" do
  command "dpkg -i /tmp/td-agent_#{TDAGENT}-1_amd64.deb"
  action :nothing
end

remote_file "/tmp/td-agent_#{TDAGENT}-1_amd64.deb" do
  source "http://packages.treasure-data.com/debian/pool/contrib/t/td-agent/td-agent_#{TDAGENT}-1_amd64.deb"
  notifies :run, "execute[install_td-agent]", :immediately
  not_if {File.exists?("/etc/init.d/td-agent")}
end

%w{fluent-plugin-mongo fluent-plugin-elasticsearch fluent-plugin-redis}.each do |p|
  gem_package p do
    gem_binary("/usr/lib/fluent/ruby/bin/fluent-gem")
    options("--no-ri --no-rdoc -V")
  end
end

service "td-agent" do
  supports :restart => true
end

template "/etc/td-agent/td-agent.conf" do
  source "td-agent_collector.conf.erb"
  owner "root"
  group "root"
  mode "00644"
  notifies :restart, "service[td-agent]"
end
