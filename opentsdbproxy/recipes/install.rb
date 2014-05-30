app_dir = node[:opentsdbproxy][:appdir]
ve_dir = node[:opentsdbproxy][:virtualenv][:path]

include_recipe "git"
include_recipe "python"
include_recipe "virtualenv"

[ :create, :activate ].each do |act|
  virtualenv ve_dir do
    owner node[:opentsdbproxy][:username]
    group node[:opentsdbproxy][:groupname]
    python node[:opentsdbproxy][:virtualenv][:python]
    virtualenv node[:opentsdbproxy][:virtualenv][:virtualenv]
    action act
  end
end

case node[:platform]
when "debian", "ubuntu"
  %w{ libmysqlclient-dev python-dev }.each do |pkg|
      package pkg
  end
end

retrieve_method = node[:opentsdbproxy][:retrieve_method]
src_dir = unpack_dir = "#{Dir.tmpdir}/opentsdbproxy"

if retrieve_method == "offline_archive"
  # TODO
  archive_path = "#{Dir.tmpdir}/opentsdbproxy-#{Time.now.to_i}.tar.gz"

  directory app_dir do
    owner node[:opentsdbproxy][:username]
    group node[:opentsdbproxy][:groupname]
  end

  directory "#{app_dir}/logs" do
    owner node[:opentsdbproxy][:username]
    group node[:opentsdbproxy][:groupname]
  end

  remote_file archive_path do
    source node[:opentsdbproxy][:retrieve_config][:archive_url]
    owner node[:opentsdbproxy][:username]
    group node[:opentsdbproxy][:groupname]
  end

  directory unpack_dir do
    owner node[:opentsdbproxy][:username]
    group node[:opentsdbproxy][:groupname]
    mode "0755"
  end

  execute "unpack #{archive_path} into #{unpack_dir}" do
    user node[:opentsdbproxy][:username]
    group node[:opentsdbproxy][:groupname]
    command "tar xzf #{archive_path} -C #{unpack_dir}"
  end

else
  directory app_dir do
    owner node[:opentsdbproxy][:username]
    group node[:opentsdbproxy][:groupname]
  end

  directory "#{app_dir}/logs" do
    owner node[:opentsdbproxy][:username]
    group node[:opentsdbproxy][:groupname]
  end

  git app_dir do
    repository node[:opentsdbproxy][:git_repo]
    reference node[:opentsdbproxy][:git_branch]
    action :sync
    user node[:opentsdbproxy][:username]
    group node[:opentsdbproxy][:groupname]
  end
end

install_method = node[:opentsdbproxy][:install_method]

if not node[:opentsdbproxy][:extras].nil?
    requirements_extras = "_#{node[:opentsdbproxy][:extras]}"
    setup_py_extras = "[#{node[:opentsdbproxy][:extras]}]"
end

if install_method == "py_venv_offline_setup"
  execute "run install" do
    cwd src_dir
    user node[:opentsdbproxy][:username]
    group node[:opentsdbproxy][:groupname]
     environment({
       "HOME" => "/home/#{node[:opentsdbproxy][:username]}"
     })
    command "env >/tmp/env ; pip install -r ./opentsdbproxy/requirements#{requirements_extras}.txt --no-index --find-links=file://`pwd`/packages/ --upgrade ./opentsdbproxy"
  end
  execute "install-supervisor" do
    cwd app_dir
    user node[:opentsdbproxy][:username]
    group node[:opentsdbproxy][:groupname]
     environment({
       "HOME" => "/home/#{node[:username]}"
     })
    command "pip install --no-index --find-links=file://`pwd`/packages/ supervisor"
  end
else
  execute "install-celery" do
    cwd app_dir
    user node[:opentsdbproxy][:username]
    group node[:opentsdbproxy][:groupname]
     environment({
       "HOME" => "/home/#{node[:username]}"
     })
    command "pip install celery"
  end
  execute "install-supervisor" do
    cwd app_dir
    user node[:opentsdbproxy][:username]
    group node[:opentsdbproxy][:groupname]
     environment({
       "HOME" => "/home/#{node[:username]}"
     })
    command "pip install supervisor"
  end
  execute "run install" do
    cwd app_dir
    user node[:opentsdbproxy][:username]
    group node[:opentsdbproxy][:groupname]
    command "pip install opentsdbproxy#{setup_py_extras}"
  end
end

exe = File.join(app_dir, "start-opentsdbproxy.sh")
template exe do
    source "start_opentsdbproxy.sh.erb"
    owner node[:opentsdbproxy][:username]
    group node[:opentsdbproxy][:groupname]
    mode 0755
end

