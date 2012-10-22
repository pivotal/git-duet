require 'git/duet'
require_relative 'command_methods'

class Git::Duet::CommitCommand
  include Git::Duet::CommandMethods

  def initialize(passthrough_args, verify_duet = false)
    @passthrough_args, @verify_duet = passthrough_args, verify_duet
  end

  def execute!
    add_env_vars_to_env
    if @verify_duet
      prompt_for_verified_duet
    end
    exec 'git commit --signoff ' << @passthrough_args.join(' ')
  end

  private
  def add_env_vars_to_env
    in_repo_root do
      File.readlines(env_cache_path).each do |l|
        key, value = l.chomp.split('=')
        ENV[key] = value.gsub(/^(['"]?)(.*)\1/, '\2')
      end
    end
  end

  def prompt_for_verified_duet
    initials = get_initials
    if initials.length == 1
      require_relative 'solo_command'
      Git::Duet::SoloCommand.new(initials.first).execute!
    elsif initials.length == 2
      require_relative 'duet_command'
      Git::Duet::DuetCommand.new(initials.first, initials.last).execute!
    end
  end

  def get_initials
    loop do
      initials_list = []
      STDOUT.puts "---> Who's in this duet (or solo)?  Please provide initials."
      STDOUT.puts '> '
      STDIN.gets.chomp.split.each do |initials|
        initials_list << initials
      end

      return initials_list if !initials_list.empty?

      STDOUT.puts "---> Seriously,"
    end
  end
end
