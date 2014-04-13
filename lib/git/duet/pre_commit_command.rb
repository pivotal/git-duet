# vim:fileencoding=utf-8
require 'git/duet'
require 'git/duet/command_methods'
require 'git/duet/script_die_error'

module Git
  module Duet
    class PreCommitCommand
      include Git::Duet::CommandMethods

      def initialize(quiet = false)
        @quiet = !!quiet
      end

      def execute!
        in_repo_root do
          explode! if !env_cache_exists? || env_cache_stale?
        end
      end

      private

      def explode!
        error('Your git duet settings are stale, human!')
        error('Update them with `git duet` or `git solo`.')
        fail Git::Duet::ScriptDieError, 1
      end

      def env_cache_exists?
        with_output_quieted do
          exec_check("git config #{Git::Duet::Config.namespace}.mtime")
        end
        true
      rescue
        false
      end

      def env_cache_stale?
        Integer(
          exec_check("git config #{Git::Duet::Config.namespace}.mtime")
        ) < stale_cutoff
      end

      def stale_cutoff
        Integer(
          Time.now - Integer(ENV.fetch('GIT_DUET_SECONDS_AGO_STALE', '1200'))
        )
      end
    end
  end
end
