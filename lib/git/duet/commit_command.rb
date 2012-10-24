require 'git/duet'
require_relative 'command_methods'

class Git::Duet::CommitCommand
  include Git::Duet::CommandMethods

  def initialize(passthrough_argv, quiet = false)
    @passthrough_argv = passthrough_argv
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
        ENV[env_var] = value if !value.empty?
      rescue StandardError => e
        error("#{e.message}")
      end
    end
  end

  def exec_git_commit
    exec_check('git commit --signoff ' << quoted_passthrough_args)
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

  def quoted_passthrough_args
    @passthrough_argv.map do |arg|
      "'#{arg}'"
    end.join(' ')
  end
end
