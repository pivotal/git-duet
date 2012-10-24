require 'git/duet'
require_relative 'author_mapper'
require_relative 'command_methods'

class Git::Duet::SoloCommand
  include Git::Duet::CommandMethods

  def initialize(soloist, quiet = false)
    @soloist = soloist
    @quiet = !!quiet
    @author_mapper = Git::Duet::AuthorMapper.new
  end

  def execute!
    set_soloist_as_git_config_user
    unset_committer_vars
    report_env_vars
    write_env_vars
  end

  private
  attr_accessor :soloist, :author_mapper

  def set_soloist_as_git_config_user
    exec_check("git config user.name '#{soloist_info[:name]}'")
    exec_check("git config user.email '#{soloist_info[:email]}'")
  end

  def unset_committer_vars
    exec_check("git config --unset-all duet.env.git-committer-name", [0, 5])
    exec_check("git config --unset-all duet.env.git-committer-email", [0, 5])
  end

  def var_map
    {
      'GIT_AUTHOR_NAME' => soloist_info[:name],
      'GIT_AUTHOR_EMAIL' => soloist_info[:email]
    }
  end

  def soloist_info
    @soloist_info ||= author_mapper.map(@soloist).fetch(@soloist)
  end
end
