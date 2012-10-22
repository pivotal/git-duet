require 'optparse'
require 'git/duet'

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
      when /commit$/
        return commit(parse_commit_options(argv.clone))
      else
        raise ScriptError.new('How did you get here???')
      end
    end

    private
    def parse_solo_options(argv)
      options = {}
      leftover_argv = OptionParser.new do |opts|
        opts.banner = "Usage: #{opts.program_name} [options] <soloist-initials>"
      end.parse!(argv)
      options[:soloist] = leftover_argv.first
      options
    end

    def parse_duet_options(argv)
      options = {}
      leftover_argv = OptionParser.new do |opts|
        opts.banner = "Usage: #{opts.program_name} [options] " <<
                      "<alpha-initials> <omega-initials>"
      end.parse!(argv)
      options[:alpha], options[:omega] = leftover_argv[0..1]
      options
    end

    def parse_commit_options(argv)
      options = {verify_duet: false}
      leftover_argv = OptionParser.new do |opts|
        opts.banner = "Usage: #{opts.program_name} -- [git passthrough options]"
        opts.on('--verify-duet',
                'Check the duet (or solo) members before committing') do |v|
          options[:verify_duet] = true
        end
      end.parse!(argv)
      options[:passthrough_argv] = leftover_argv
      options
    end

    def solo(options)
      require_relative 'solo_command'
      Git::Duet::SoloCommand.new(options.fetch(:soloist)).execute!
    end

    def duet(options)
      require_relative 'duet_command'
      Git::Duet::DuetCommand.new(
        options.fetch(:alpha), options.fetch(:omega)
      ).execute!
    end

    def commit(options)
      require_relative 'commit_command'
      Git::Duet::CommitCommand.new(
        options.fetch(:passthrough_argv), options.fetch(:verify_duet)
      ).execute!
    end
  end
end
