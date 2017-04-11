require 'mixlib/shellout'

module SupervisordHelper
	def set_system_startup
		cmd = Mixlib::ShellOut.new('ps u --pid 1')
		pid = cmd.run_command

		if pid.stdout =~ /systemd/
			node.set['system_startup'] = "systemd"
		else
			node.set['system_startup'] = "initd"
		end
	end

	# Define package name for python-setuptools
	# base on platform
	def get_setuptools
		package_name = "python-setuptools"
		case node.platform
		when /fedora|redhat|centos|ubuntu/
		  package_name = "python-setuptools"
		end
		package_name
	end

	def install_pip
		pip_installed = false
		begin
			pip_check = Mixlib::ShellOut.new('python -c "import pip"')
			output = pip_check.run_command
			if output.stderr.include? "ImportError"
				pip_installed = false
			else
				pip_installed = true
			end
		rescue Exception => e
			puts e.inspect
			# It's probably not installed on the system.
		end

		begin
			if !pip_installed
				install_pip = Mixlib::ShellOut.new(node[:supervisord][:pip])
				output = install_pip.run_command
				puts output.stdout
				puts output.stderr
			end
		rescue Exception => e
			puts e.inspect
			puts "***FAULT:FATAL=Failed to install Python PIP"
			raise e
		end
	end

	# Install supervisord using configured command
	# e.g. easy_install supervisor
	# this can be substitute with any valid commands,
	# scripts, or system packing
	# 
	# Make sure pip is installed before proceed to
	# install supervisord
	def install
		install_pip()
		begin
			cmd = Mixlib::ShellOut.new('pip install supervisor')
			output = cmd.run_command

			if cmd.exitstatus != 0
				puts "***FAULT:FATAL=Failed to install supervisor using pip"
				e = Exception.new("no backtrace")
				e.set_backtrace("")
				raise e
			end
		rescue Exception => e
			puts e.inspect
			puts "***FAULT:FATAL=Failed to install supervisor using pip"
			raise e
		end
	end

	# 
	# Remove supervisord from system
	def uninstall
		begin
			cmd = Mixlib::ShellOut.new('pip uninstall -y supervisor')
			output = cmd.run_command
			puts "#"*100
			puts "OUTPUT: #{output.stdout}"
			puts "#"*100
			puts "STDERR: #{output.stderr}"
			if cmd.exitstatus != 0
				puts "***FAULT:FATAL=Failed to uninstall supervisor using pip"
				e = Exception.new("no backtrace")
				e.set_backtrace("")
				raise e
			end
		rescue Exception => e
			puts e.inspect
			puts "***FAULT:FATAL=Failed to uninstall supervisor using pip"
			raise e
		end
	end
end