require_relative 'command_methods'

module Git
  module Duet
    class CommitCommand
      include CommandMethods

      def initialize(passthrough_args)
        @passthrough_args = passthrough_args
      end

      def execute!
        add_env_vars_to_env
        exec 'git commit --signoff ' << @passthrough_args.join(' ')
      end

      def add_env_vars_to_env
        in_repo_root do
          File.readlines(env_cache_path).each do |l|
            key, value = l.chomp.split('=')
            ENV[key] = value.gsub(/^(['"]?)(.*)\1/, '\2')
          end
        end
      end
    end
  end
end
