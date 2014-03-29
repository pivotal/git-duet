# vim:fileencoding=utf-8
require 'git/duet'
require 'git/duet/author_mapper'
require 'git/duet/command_methods'

module Git
  module Duet
    class DuetCommand
      include Git::Duet::CommandMethods

      def initialize(alpha, omega, quiet = false, global = false)
        @alpha, @omega = alpha, omega
        @quiet = quiet
        @global = global
        @author_mapper = Git::Duet::AuthorMapper.new
      end

      def execute!
        if alpha && omega
          set_alpha_as_git_config_user
          report_env_vars
          write_env_vars
        else
          show_current_config
        end
      end

      private

      attr_accessor :alpha, :omega, :author_mapper

      def set_alpha_as_git_config_user
        %w(name email).each do |setting|
          exec_check(
            "#{git_config} user.#{setting} '#{alpha_info[setting.to_sym]}'"
          )
        end
      end

      def var_map
        {
          'GIT_AUTHOR_NAME' => alpha_info[:name],
          'GIT_AUTHOR_EMAIL' => alpha_info[:email],
          'GIT_COMMITTER_NAME' => omega_info[:name],
          'GIT_COMMITTER_EMAIL' => omega_info[:email]
        }
      end

      def alpha_info
        fetch_info(alpha, 'author')
      end

      def omega_info
        fetch_info(omega, 'committer')
      end

      def fetch_info(which, desc)
        alpha_omega_info.fetch(which)
      rescue KeyError, IndexError => e
        error("git-duet: Failed to find #{desc}: #{e}")
        raise Git::Duet::ScriptDieError, 86
      end

      def alpha_omega_info
        @alpha_omega_info ||= author_mapper.map(alpha, omega)
      end
    end
  end
end
