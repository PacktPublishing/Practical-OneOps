require "chef/mixin/shell_out"

module OO
  class IIS
    class Detection
      class << self
        include Chef::Mixin::ShellOut

        def aspnet_enabled?
          enabled_features.include?("IIS-ASPNET")
        end

        def static_compression_enabled?
          enabled_features.include?("IIS-HttpCompressionStatic")
        end

        def dynamic_compression_enabled?
          enabled_features.include?("IIS-HttpCompressionDynamic")
        end

        def enabled_features
          @enabled_features ||= begin
            cmd = shell_out!("#{dism} /Online /Get-Features", {returns: [0, 42, 127]})
            return [] unless cmd.stderr.empty?

            cmd.stdout.scan(/^Feature Name : ([\w,-]+).?\n^State : (\w+).?\n/i).reduce([]) do |result, item|
              item[1] == "Enabled" ? result << item[0] : result
            end
          end
        end

        def major_version
          @major_version ||= begin
            require "win32/registry"
            key = "Software\\Microsoft\\InetStp"
            access = Win32::Registry::Constants::KEY_READ
            Win32::Registry::HKEY_LOCAL_MACHINE.open(key, access)["MajorVersion"].to_i
          rescue
            -1
          end
        end

        private

        def dism
          @dism ||= begin
            if ::File.exists?(file = "#{ENV["WINDIR"]}\\sysnative\\dism.exe")
              file
            elsif ::File.exists?(file = "#{ENV["WINDIR"]}\\system32\\dism.exe")
              file
            else
              "dism.exe"
            end
          end
        end
      end
    end
  end
end
