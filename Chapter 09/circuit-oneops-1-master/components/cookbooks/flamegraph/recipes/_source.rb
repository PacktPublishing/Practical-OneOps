cache_dir = Chef::Config[:file_cache_path]
cmake_version = node["flamegraph"]["cmake"]["source"]["version"]

cookbook_file "#{cache_dir}/cmake-#{cmake_version}.tar.gz" do
	  source "cmake-#{cmake_version}.tar.gz" # rubocop:disable LineLength
	      notifies :run, "execute[unpack cmake]", :immediate
end

execute "unpack cmake" do
	  command "tar xzvf cmake-#{cmake_version}.tar.gz"
	    cwd cache_dir
	      #notifies :run, "execute[configure cmake]"
	      #  notifies :run, "execute[make cmake]"
	#	  notifies :run, "execute[make install cmake]"
		  notifies :run, "execute[configure perf map]", :immediate
end

execute "configure cmake" do
	  command "./configure"
	    cwd "#{cache_dir}/cmake-#{cmake_version}"
	    action :nothing
end

execute "make cmake" do
	  command "make"
	    cwd "#{cache_dir}/cmake-#{cmake_version}"
	    action :nothing
end

execute "make install cmake" do
	  command "make install"
	    cwd "#{cache_dir}/cmake-#{cmake_version}"
	      creates "/usr/local/bin/cmake"
	    action :nothing
end

execute "configure perf map" do
	        command "sudo -u app bash -c \"export JAVA_HOME=/usr/java/default && #{cache_dir}/cmake-#{cmake_version}/bin/cmake . && make\""
		user "#{node['flamegraph']['app_user']}"
		cwd "#{cache_dir}/perf-map"
end
