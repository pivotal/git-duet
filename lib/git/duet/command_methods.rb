# vim:fileencoding=utf-8
require 'English'
require 'git/duet'
require 'git/duet/script_die_error'

module Git
  module Duet
    module CommandMethods
      private

      def report_env_vars
        var_map.each do |key, value|
          info("#{key}='#{value}'")
        end
      end

      def write_env_vars
        in_repo_root do
          var_map.each do |key, value|
            exec_check(
              "#{git_config} #{Git::Duet::Config.namespace}." <<
              "#{key.downcase.gsub(/_/, '-')} '#{value}'"
            )
          end
          exec_check("#{git_config} #{Git::Duet::Config
                                  .namespace}.mtime #{Time.now.to_i}")
        end
      end

      def git_config
        "git config#{@global ? ' --global' : ''}"
      end

      def author_env_vars_set?
        %x(#{author_name_command} && #{author_email_command})
        $CHILD_STATUS == 0
      end

      def author_name_command
        "git config --get #{Git::Duet::Config.namespace}.git-author-name"
      end

      def author_email_command
        "git config --get #{Git::Duet::Config.namespace}.git-author-email"
      end

      def current_config_command
        "git config --get-regexp #{Git::Duet::Config.namespace}"
      end

      def show_current_config
        info(exec_check(current_config_command))
      end

      def dump_env_vars
        extract_env_vars_from_git_config.each do |k, v|
          puts "#{k}='#{v}'"
        end
      end

      def extract_env_vars_from_git_config
        dest = {}
        env_vars.each do |env_var, config_key|
          begin
            value = check_env_var_config_key(config_key)
            dest[env_var] = value unless value.empty?
          rescue StandardError => e
            error("#{e.message}")
          end
        end
        dest
      end

      def check_env_var_config_key(config_key)
        exec_check(
          "git config #{Git::Duet::Config.namespace}.#{config_key}"
        ).chomp
      end

      def exec_git_commit
        if author_env_vars_set?
          exec 'git commit ' << signoff_arg << quoted_passthrough_args
        else
          fail Git::Duet::ScriptDieError, 17
        end
      end

      def in_repo_root
        Dir.chdir(exec_check('git rev-parse --show-toplevel').chomp) do
          yield
        end
      end

      def exec_check(command, okay_statuses = [0].freeze)
        output = `#{command}`
        unless okay_statuses.include?($CHILD_STATUS.exitstatus)
          error("Command #{command.inspect} exited with #{$CHILD_STATUS.to_i}")
          fail Git::Duet::ScriptDieError, 1
        end
        output
      end

      def with_output_unquieted(&block)
        @old_quiet = @quiet
        @quiet = false
        block.call
        @quiet = @old_quiet
      rescue StandardError => e
        @quiet = @old_quiet
        raise e
      end

      def with_output_quieted(&block)
        @old_quiet = @quiet
        @quiet = true
        block.call
      rescue StandardError => e
        raise e
      ensure
        @quiet = @old_quiet
      end

      def info(msg)
        $stdout.puts(msg) unless quiet?
      end

      def error(msg)
        $stderr.puts(msg) unless quiet?
      end

      def prompt
        $stdout.print '> '
      end

      def quiet?
        ENV['GIT_DUET_QUIET'] == '1' || @quiet
      end
    end
  end
end
