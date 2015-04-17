# vim:fileencoding=utf-8
require 'optparse'
require 'git/duet'
require 'git/duet/script_die_error'

module Git
  module Duet
    class Cli
      class << self
        def run(prog, argv)
          method_name = File.basename(prog)
                        .sub(/^git-duet-/, '').sub(/^git-/, '').tr('-', '_')
          options = parse_options(method_name, argv.clone)
          if ENV['GIT_DUET_GLOBAL']
            options[:global] = parse_boolean(ENV['GIT_DUET_GLOBAL'])
          end
          send(method_name, options)
          0
        rescue NoMethodError
          raise ScriptError, 'How did you get here???'
        rescue Git::Duet::ScriptDieError => e
          e.exit_code
        end

        private

        def parse_options(method_name, argv)
          case method_name
          when 'pre_commit', 'install_hook'
            parse_generic_options(argv)
          else
            send("parse_#{method_name}_options", argv)
          end
        end

        def with_common_opts(argv, banner)
          options = {}
          leftover_argv = OptionParser.new do |opts|
            opts.banner = banner.gsub(/__PROG__/, opts.program_name)
            opts.on('-q', 'Silence output') do |_|
              options[:quiet] = true
            end
            yield opts, options if block_given?
          end.parse!(argv)
          [leftover_argv, options]
        end

        def parse_solo_options(argv)
          parse_options_with_positional_args(
            argv, '<soloist-initials>') do |leftover_argv, options|
              options[:soloist] = leftover_argv.first
            end
        end

        def parse_duet_options(argv)
          parse_options_with_positional_args(
            argv,
            '<alpha-initials> <omega-initials>'
          ) do |leftover_argv, options|
            options[:alpha], options[:omega] = leftover_argv[0..1]
          end
        end

        def parse_options_with_positional_args(argv, usage)
          leftover_argv, options = with_common_opts(
            argv, 'Usage: __PROG__ [options] ' << usage
          ) do |opts, options_hash|
            opts.on('-g', '--global', 'Change global git config') do |_|
              options_hash[:global] = true
            end
          end
          yield leftover_argv, options
          options
        end

        def parse_generic_options(argv)
          with_common_opts(argv, 'Usage: __PROG__').last
        end

        def parse_commit_options(argv)
          opts_argv = []
          opts_argv << '-q' if argv.delete('-q')
          options = with_common_opts(opts_argv, 'Usage: __PROG__').last
          options[:passthrough_args] = argv
          options
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
