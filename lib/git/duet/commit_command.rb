require 'git/duet'
require_relative 'command_methods'

class Git::Duet::CommitCommand
  include Git::Duet::CommandMethods

  def initialize(quiet = false)
    @quiet = quiet
  end

  def execute!
    in_repo_root do
      add_env_vars_to_env
      exec_git_commit
    end
  end

  private
  def add_env_vars_to_env
    env_vars.each do |env_var,config_key|
      begin
        value = exec_check("git config duet.env.#{config_key}").chomp
        if !value.empty?
          ENV[env_var] = value
        end
      rescue StandardError => e
        unless @quiet
          STDERR.puts "#{e.message}"
        end
      end
    end
  end

  def exec_git_commit
    exec 'git commit --signoff ' << ARGV.join(' ')
  end

  def env_vars
    @env_vars ||= Hash[env_var_pairs]
  end

  def env_var_pairs
    %w(
      GIT_AUTHOR_NAME
      GIT_AUTHOR_EMAIL
      GIT_COMMITTER_NAME
      GIT_COMMITTER_EMAIL
    ).map do |env_var|
      [env_var, env_var.downcase.gsub(/_/, '-')]
    end
  end
end
