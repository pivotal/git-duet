# vim:fileencoding=utf-8
require 'git/duet'
require 'git/duet/author_mapper'
require 'git/duet/command_methods'

class Git::Duet::DuetCommand
  include Git::Duet::CommandMethods

  def initialize(alpha, omega, quiet = false, global = false)
    @alpha, @omega = alpha, omega
    @quiet = !!quiet
    @global = !!global
    @author_mapper = Git::Duet::AuthorMapper.new
  end

  def execute!
    if !(alpha || omega)
      show_current
    else
      set_alpha_as_git_config_user
      report_env_vars
      write_env_vars
    end
  end

  private

  attr_accessor :alpha, :omega, :author_mapper

  def set_alpha_as_git_config_user
    exec_check("#{git_config} user.name '#{alpha_info[:name]}'")
    exec_check("#{git_config} user.email '#{alpha_info[:email]}'")
  end

  def git_config
    "git config#{@global ? ' --global' : ''}"
  end

  def var_map
    {
      'GIT_AUTHOR_NAME' => alpha_info[:name],
      'GIT_AUTHOR_EMAIL' => alpha_info[:email],
      'GIT_COMMITTER_NAME' => omega_info[:name],
      'GIT_COMMITTER_EMAIL' => omega_info[:email]
    }
  end

  def alpha_info
    alpha_omega_info.fetch(@alpha)
  rescue KeyError, IndexError => e
    error("git-duet: Failed to find author: #{e}")
    raise Git::Duet::ScriptDieError.new(86)
  end

  def omega_info
    alpha_omega_info.fetch(@omega)
  rescue KeyError, IndexError => e
    error("git-duet: Failed to find committer: #{e}")
    raise Git::Duet::ScriptDieError.new(86)
  end

  def alpha_omega_info
    @alpha_omega_info ||= author_mapper.map(@alpha, @omega)
  end

  def show_current
    info(exec_check('git config --get-regexp duet.env'))
  end
end
