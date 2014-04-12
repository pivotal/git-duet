# vim:fileencoding=utf-8
require 'git/duet'
require 'git/duet/author_mapper'
require 'git/duet/command_methods'

module Git
  module Duet
    class SoloCommand
      include Git::Duet::CommandMethods

      def initialize(soloist, quiet = false, global = false)
        @soloist = soloist
        @quiet = !!quiet
        @global = !!global
        @author_mapper = Git::Duet::AuthorMapper.new
      end

      def execute!
        unset_committer_vars
        if soloist
          set_soloist_as_git_config_user
          report_env_vars
          write_env_vars
        else
          show_current_config
        end
      end

      private

      attr_accessor :soloist, :author_mapper

      def set_soloist_as_git_config_user
        exec_check("#{git_config} user.name '#{soloist_info[:name]}'")
        exec_check("#{git_config} user.email '#{soloist_info[:email]}'")
      end

      def unset_committer_vars
        exec_check(
          "#{git_config} --unset-all #{Git::Duet::Config.namespace}." \
          'git-committer-name',
          [0, 5]
        )
        exec_check(
          "#{git_config} --unset-all #{Git::Duet::Config.namespace}." \
          'git-committer-email',
          [0, 5]
        )
      end

      def var_map
        {
          'GIT_AUTHOR_NAME' => soloist_info[:name],
          'GIT_AUTHOR_EMAIL' => soloist_info[:email]
        }
      end

      def soloist_info
        @soloist_info ||= author_mapper.map(@soloist).fetch(@soloist)
      rescue KeyError, IndexError => e
        error("git-solo: Failed to find author: #{e}")
        raise Git::Duet::ScriptDieError, 86
      end
    end
  end
end
