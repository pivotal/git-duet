require 'optparse'

require 'git/duet'
require 'git/duet/author_mapper'

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
      options = {}
      leftover_argv = OptionParser.new do |opts|
        opts.banner = "Usage: #{opts.program_name} -- [git passthrough options]"
      end.parse!(argv)
      options[:passthrough_argv] = leftover_argv
      options
    end

    def exec_check(command)
      output = `#{command}`
      if $?.exitstatus != 0
        raise RuntimeError.new("Command '#{command}' failed with #{$?.to_i}")
      end
      output
    end

    def solo(options)
      soloist = options.fetch(:soloist)
      author = Git::Duet::AuthorMapper.new.map(soloist).fetch(soloist)
      exec_check("git config user.name '#{author[:name]}'")
      exec_check("git config user.email '#{author[:email]}'")
      env_vars = %W(
          GIT_AUTHOR_NAME=#{author[:name]}
          GIT_AUTHOR_EMAIL=#{author[:email]}
      ).join("\n")
      STDOUT.puts env_vars
      write_pre_commit_author_set(env_vars)
    end

    def duet(options)
      require_relative 'duet_command'
      Git::Duet::DuetCommand.new(
        options.fetch(:alpha),
        options.fetch(:omega)
      ).execute!
      #authors_info = Git::Duet::AuthorMapper.new.map(alpha, omega)
      #author = authors_info[alpha]
      #committer = authors_info[omega]
      #exec_check("git config user.name '#{author[:name]}'")
      #exec_check("git config user.email '#{author[:email]}'")
      #env_vars = %W(
          #GIT_AUTHOR_NAME=#{author[:name]}
          #GIT_AUTHOR_EMAIL=#{author[:email]}
          #GIT_COMMITTER_NAME=#{committer[:name]}
          #GIT_COMMITTER_EMAIL=#{committer[:email]}
      #).join("\n")
      #STDOUT.puts env_vars
      #write_pre_commit_author_set(env_vars)
    end

    def write_pre_commit_author_set(body)
      in_repo_root do
        File.open(pre_commit_author_set_path, 'w') do |f|
          f.puts body
        end
      end
    end

    def commit(options)
      in_repo_root do
        File.readlines(pre_commit_author_set_path).each do |l|
          key, value = l.chomp.split('=')
          ENV[key] = value
        end
        exec 'git commit --signoff ' << options[:passthrough_argv].join(' ')
      end
    end

    def in_repo_root
      Dir.chdir(exec_check('git rev-parse --show-toplevel').chomp) do
        yield
      end
    end

    def pre_commit_author_set_path
      '.git/hooks/pre-commit-author-set'
    end
  end
end
