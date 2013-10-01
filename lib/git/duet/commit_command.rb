# vim:fileencoding=utf-8
require 'git/duet'
require 'git/duet/command_methods'

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
    extract_env_vars_from_git_config.each do |k, v|
      ENV[k] = v
    end
  end

  def env_vars
    @env_vars ||= Hash[env_var_pairs]
  end

  def env_var_pairs
    env_var_names.map do |env_var|
      [env_var, env_var.downcase.gsub(/_/, '-')]
    end
  end

  def quoted_passthrough_args
    @passthrough_argv.map do |arg|
      "'#{arg}'"
    end.join(' ')
  end

  def signoff_arg
    soloing? ? '' : '--signoff '
  end

  SOLO_ENV_VARS = %w(
    GIT_AUTHOR_NAME
    GIT_AUTHOR_EMAIL
  )

  DUET_ENV_VARS = %w(
    GIT_AUTHOR_NAME
    GIT_AUTHOR_EMAIL
    GIT_COMMITTER_NAME
    GIT_COMMITTER_EMAIL
  )

  def env_var_names
    return SOLO_ENV_VARS if soloing?
    DUET_ENV_VARS
  end

  def soloing?
    @soloing ||= begin
      with_output_quieted do
        exec_check("git config #{Git::Duet::CONFIG_NAMESPACE}.git-committer-name").chomp
      end
      false
    rescue StandardError
      true
    end
  end
end
