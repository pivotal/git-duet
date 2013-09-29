# vim:fileencoding=utf-8
require 'optparse'
require 'git/duet'
require 'git/duet/script_die_error'

class Git::Duet::Cli
  class << self
    def run(prog, argv)
      case prog
      when /solo$/
        solo(parse_solo_options(argv.clone))
        return 0
      when /duet$/
        duet(parse_duet_options(argv.clone))
        return 0
      when /pre-commit$/
        pre_commit(parse_generic_options(argv.clone))
        return 0
      when /install-hook$/
        install_hook(parse_generic_options(argv.clone))
        return 0
      when /commit$/
        commit(parse_commit_options(argv.clone))
        return 0
      else
        raise ScriptError.new('How did you get here???')
      end
    rescue Git::Duet::ScriptDieError => e
      return e.exit_code
    end

    private

    def with_common_opts(argv, banner)
      options = {}
      leftover_argv = OptionParser.new do |opts|
        opts.banner = banner.gsub(/__PROG__/, opts.program_name)
        opts.on('-q', 'Silence output') do |q|
          options[:quiet] = true
        end
        if block_given?
          yield opts, options
        end
      end.parse!(argv)
      return leftover_argv, options
    end

    def parse_solo_options(argv)
      leftover_argv, options = with_common_opts(
        argv, 'Usage: __PROG__ [options] <soloist-initials>'
      ) do |opts,options_hash|
        opts.on('-g', '--global', 'Change global git config') do |g|
          options_hash[:global] = true
        end
      end
      options[:soloist] = leftover_argv.first
      options
    end

    def parse_duet_options(argv)
      leftover_argv, options = with_common_opts(
        argv, 'Usage: __PROG__ [options] <alpha-initials> <omega-initials>'
      ) do |opts,options_hash|
        opts.on('-g', '--global', 'Change global git config') do |g|
          options_hash[:global] = true
        end
      end
      options[:alpha], options[:omega] = leftover_argv[0..1]
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
