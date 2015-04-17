module Git
  module Duet
    class CliOptions
      class << self
        def parse_options(method_name, argv)
          case method_name
          when 'pre_commit', 'install_hook'
            parse_generic_options(argv)
          else
            send("parse_#{method_name}_options", argv)
          end
        end

        private

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
      end
    end
  end
end
