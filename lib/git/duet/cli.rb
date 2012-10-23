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
        pre_commit(parse_pre_commit_options(argv.clone))
        return 0
      else
        raise ScriptError.new('How did you get here???')
      end
    rescue Git::Duet::ScriptDieError => e
      return Integer(e.message)
    end

    private
    def parse_solo_options(argv)
      options = {}
      leftover_argv = OptionParser.new do |opts|
        opts.banner = "Usage: #{opts.program_name} [options] <soloist-initials>"
        opts.on('-q', 'Silence output') do |q|
          options[:quiet] = true
        end
      end.parse!(argv)
      options[:soloist] = leftover_argv.first
      options
    end

    def parse_duet_options(argv)
      options = {}
      leftover_argv = OptionParser.new do |opts|
        opts.banner = "Usage: #{opts.program_name} [options] " <<
                      "<alpha-initials> <omega-initials>"
        opts.on('-q', 'Silence output') do |q|
          options[:quiet] = true
        end
      end.parse!(argv)
      options[:alpha], options[:omega] = leftover_argv[0..1]
      options
    end

    def parse_pre_commit_options(argv)
      options = {}
      OptionParser.new do |opts|
        opts.banner = "Usage: #{opts.program_name}"
        opts.on('-q', 'Silence output') do |q|
          options[:quiet] = true
        end
      end.parse!(argv)
      options
    end

    def solo(options)
      require_relative 'solo_command'
      Git::Duet::SoloCommand.new(
        options.fetch(:soloist), options[:quiet]
      ).execute!
    end

    def duet(options)
      require_relative 'duet_command'
      Git::Duet::DuetCommand.new(
        options.fetch(:alpha), options.fetch(:omega), options[:quiet]
      ).execute!
    end

    def pre_commit(options)
      require_relative 'pre_commit_command'
      Git::Duet::PreCommitCommand.new(options[:quiet]).execute!
    end
  end
end
