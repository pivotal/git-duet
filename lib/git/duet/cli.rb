# vim:fileencoding=utf-8
require 'optparse'
require 'git/duet'
require 'git/duet/cli_options'
require 'git/duet/script_die_error'

module Git
  module Duet
    class Cli
      class << self
        def run(prog, argv)
          invoke(File.basename(prog), argv.clone, ENV)
          0
        rescue NoMethodError
          raise ScriptError, 'How did you get here???'
        rescue Git::Duet::ScriptDieError => e
          e.exit_code
        end

        private

        def invoke(prog_name, args, environment)
          method_name = prog_name
                        .sub(/^git-duet-/, '')
                        .sub(/^git-/, '')
                        .tr('-', '_')
          options = CliOptions.parse_options(method_name, args)
          if environment['GIT_DUET_GLOBAL']
            options[:global] = parse_boolean(environment['GIT_DUET_GLOBAL'])
          end
          send(method_name, options)
        end

        def parse_boolean(s)
          case s
          when 'true' then true
          when 'false' then false
          else fail ArgumentError, "must be 'true' or 'false': #{s}"
          end
        end

        def solo(options)
          require 'git/duet/solo_command'
          Git::Duet::SoloCommand.new(
            options.fetch(:soloist),
            options[:quiet],
            options[:global]
          ).execute!
        end

        def duet(options)
          require 'git/duet/duet_command'
          Git::Duet::DuetCommand.new(
            options.fetch(:alpha),
            options.fetch(:omega),
            options[:quiet],
            options[:global]
          ).execute!
        end

        def pre_commit(options)
          require 'git/duet/pre_commit_command'
          Git::Duet::PreCommitCommand.new(options[:quiet]).execute!
        end

        def install_hook(options)
          require 'git/duet/install_hook_command'
          Git::Duet::InstallHookCommand.new(options[:quiet]).execute!
        end

        def commit(options)
          require 'git/duet/commit_command'
          Git::Duet::CommitCommand.new(
            options[:passthrough_args],
            options[:quiet]
          ).execute!
        end
      end
    end
  end
end
