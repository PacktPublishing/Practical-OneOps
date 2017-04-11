#
# Author:: Didier Bathily (<bathily@njin.fr>)
#
# Copyright 2013, njin
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'chef/resource/remote_file'

class Chef
  class Resource
    class DistRemoteFile < Chef::Resource::RemoteFile

      include Chef::DSL::Recipe
      include Chef::Mixin::FromFile
      include Chef::Mixin::Command

      alias :user :owner
      alias :repository :source

      state_attrs :deploy_to, :revision

      def initialize(name, run_context=nil)
        super
        @resource_name = :dist_remote_file
        @environment = nil
        @provider = Chef::Provider::DistRemoteFile
        @action = :deploy
        @migrate = false
        @rollback_on_error = false
        @allowed_actions.push(:force_deploy, :deploy, :rollback)
        @keep_releases = 5
      end

      def provider
        Chef::Provider::DistRemoteFile
      end

      def deploy_to(args=nil)
        set_or_return(
          :deploy_to,
          args,
          :kind_of => String
        )
      end

      def revision(args=nil)
        set_or_return(
          :revision,
          args,
          :kind_of => String
        )
      end

      def path(args=nil)
        set_or_return(
          :path,
          @shared_path + @revision + ".zip",
          :kind_of => String
        )
      end

      def shared_path(args=nil)
        set_or_return(
          :shared_path,
          @deploy_to + "/shared/",
          :kind_of => String
        )
      end

      def release_path(args=nil)
        set_or_return(
          :release_path,
          args,
          :kind_of => String
        )
      end

      def current_path(args=nil)
        set_or_return(
          :current_path,
          @deploy_to + "/current",
          :kind_of => String
        )
      end

      def scm_provider(arg=nil)
        nil
      end

      def enable_submodules(arg=nil)
        set_or_return(
          :enable_submodules,
          arg,
          :kind_of => [ TrueClass, FalseClass ]
        )
      end

      def shallow_clone(arg=nil)
        set_or_return(
          :shallow_clone,
          arg,
          :kind_of => [ TrueClass, FalseClass ]
        )
      end

      def ssh_wrapper(arg=nil)
      end

      def restart_command(arg=nil, &block)
        arg ||= block
        set_or_return(
          :restart_command,
          arg,
          :kind_of => [ String, Proc ]
        )
      end
      alias :restart :restart_command

      def migrate(arg=nil)
        set_or_return(
          :migrate,
          arg,
          :kind_of => [ TrueClass, FalseClass ]
        )
      end

      def migration_command(arg=nil)
        set_or_return(
          :migration_command,
          arg,
          :kind_of => [ String ]
        )
      end

      def rollback_on_error(arg=nil)
        set_or_return(
          :rollback_on_error,
          arg,
          :kind_of => [ TrueClass, FalseClass ]
        )
      end

      def environment(arg=nil)
        if arg.is_a?(String)
          Chef::Log.debug "Setting RAILS_ENV, RACK_ENV, and MERB_ENV to `#{arg}'"
          Chef::Log.warn "[DEPRECATED] please modify your deploy recipe or attributes to set the environment using a hash"
          arg = {"RAILS_ENV"=>arg,"MERB_ENV"=>arg,"RACK_ENV"=>arg}
        end
        set_or_return(
          :environment,
          arg,
          :kind_of => [ Hash ]
        )
      end

       # The number of old release directories to keep around after cleanup
      def keep_releases(arg=nil)
        [set_or_return(
          :keep_releases,
          arg,
          :kind_of => [ Integer ]), 1].max
      end

      # An array of paths, relative to your app's root, to be purged from a
      # SCM clone/checkout before symlinking. Use this to get rid of files and
      # directories you want to be shared between releases.
      # Default: ["log", "tmp/pids", "public/system"]
      def purge_before_symlink(arg=nil)
        set_or_return(
          :purge_before_symlink,
          arg,
          :kind_of => Array
        )
      end

      # An array of paths, relative to your app's root, where you expect dirs to
      # exist before symlinking. This runs after #purge_before_symlink, so you
      # can use this to recreate dirs that you had previously purged.
      # For example, if you plan to use a shared directory for pids, and you
      # want it to be located in $APP_ROOT/tmp/pids, you could purge tmp,
      # then specify tmp here so that the tmp directory will exist when you
      # symlink the pids directory in to the current release.
      # Default: ["tmp", "public", "config"]
      def create_dirs_before_symlink(arg=nil)
        set_or_return(
          :create_dirs_before_symlink,
          arg,
          :kind_of => Array
        )
      end

      # A Hash of shared/dir/path => release/dir/path. This attribute determines
      # which files and dirs in the shared directory get symlinked to the current
      # release directory, and where they go. If you have a directory
      # $shared/pids that you would like to symlink as $current_release/tmp/pids
      # you specify it as "pids" => "tmp/pids"
      # Default {"system" => "public/system", "pids" => "tmp/pids", "log" => "log"}
      def symlinks(arg=nil)
        set_or_return(
          :symlinks,
          arg,
          :kind_of => Hash
        )
      end

      # A Hash of shared/dir/path => release/dir/path. This attribute determines
      # which files in the shared directory get symlinked to the current release
      # directory and where they go. Unlike map_shared_files, these are symlinked
      # *before* any migration is run.
      # For a rails/merb app, this is used to link in a known good database.yml
      # (with the production db password) before running migrate.
      # Default {"config/database.yml" => "config/database.yml"}
      def symlink_before_migrate(arg=nil)
        set_or_return(
          :symlink_before_migrate,
          arg,
          :kind_of => Hash
        )
      end

      # Callback fires before migration is run.
      def before_migrate(arg=nil, &block)
        arg ||= block
        set_or_return(:before_migrate, arg, :kind_of => [Proc, String])
      end

      # Callback fires before symlinking
      def before_symlink(arg=nil, &block)
        arg ||= block
        set_or_return(:before_symlink, arg, :kind_of => [Proc, String])
      end

      # Callback fires before restart
      def before_restart(arg=nil, &block)
        arg ||= block
        set_or_return(:before_restart, arg, :kind_of => [Proc, String])
      end

      # Callback fires after restart
      def after_restart(arg=nil, &block)
        arg ||= block
        set_or_return(:after_restart, arg, :kind_of => [Proc, String])
      end

    end
  end
end
