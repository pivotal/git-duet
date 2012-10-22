require 'git/duet'

module Git
  module Duet
    module CommandMethods
      private
      def report_env_vars
        var_map.each do |key,value|
          STDOUT.puts "#{key}='#{value}'"
        end
      end

      def write_env_vars
        out = []
        var_map.each do |key,value|
          out << "#{key}='#{value}'"
        end
        in_repo_root do
          File.open(env_cache_path, 'w') do |f|
            f.puts out.join($/)
          end
        end
      end

      def env_cache_path
        '.git/hooks/git-duet-env-cache.txt'
      end

      def in_repo_root
        Dir.chdir(`git rev-parse --show-toplevel`.chomp) do
          yield
        end
      end
    end
  end
end