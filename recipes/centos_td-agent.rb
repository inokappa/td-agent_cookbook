#
TDREPO="/etc/yum.repos.d/td.repo"
cookbook_file "#{TDREPO}" do
  source "td.repo"
  mode 00644
  owner "root"
  group "root"
  action :create
  not_if {File.exists?("#{TDREPO}")}
end
#
package "td-agent" do
  action :install
end

plugins = ['fluent-plugin-growthforecast','fluent-plugin-elasticsearch','fluent-plugin-tail-ex','fluent-plugin-typecast']
plugins.each do |p|
  gem_package p do
    gem_binary("/usr/lib64/fluent/ruby/bin/fluent-gem")
    options("--no-ri --no-rdoc -V")
  end
end

service "td-agent" do
  supports :restart => true
  action [:enable]
end
