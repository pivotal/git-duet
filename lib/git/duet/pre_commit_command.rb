require 'git/duet'
require_relative 'command_methods'

class Git::Duet::PreCommitCommand
  include Git::Duet::CommandMethods

  def initialize(quiet = false)
    @quiet = !!quiet
  end

  def execute!
    in_repo_root do
      set_duet! if !env_cache_exists? || env_cache_stale?
    end
  end

  private
  attr_accessor :author_mapper

  def env_cache_exists?
    exec_check('git config duet.env.touch')
    true
  rescue
    false
  end

  def env_cache_stale?
    Integer(exec_check('git config duet.env.touch')) < stale_cutoff
  end

  def stale_cutoff
    Integer(Time.now - Integer(ENV.fetch('GIT_DUET_SECONDS_AGO_STALE', '300')))
  end

  def set_duet!
    require_relative 'author_mapper'
    @author_mapper = Git::Duet::AuthorMapper.new
    initials = get_initials
    if initials.length == 1
      require_relative 'solo_command'
      Git::Duet::SoloCommand.new(initials.first, @quiet).execute!
    elsif initials.length == 2
      require_relative 'duet_command'
      Git::Duet::DuetCommand.new(initials.first, initials.last, @quiet).execute!
    else
      raise ScriptError.new(
        "Oh human, I don't know what to do with #{initials.length} " <<
        "sets of initials."
      )
    end
  end

  def get_initials
    loop do
      STDOUT.puts "---> Who's in this duet (or solo)?"
      STDOUT.print '> '
      initials = STDIN.gets.chomp.split
      return initials if validate_initials!(initials)
    end
  end

  def validate_initials!(initials)
    if [1, 2].include?(initials.length) && @author_mapper.map(*initials)
      return true
    end
    if initials.length > 2
      STDERR.puts "---> Too many initials!"
    else
      STDERR.puts "---> Seriously..."
    end
    false
  rescue KeyError => e
    STDERR.puts "---> #{e.message}"
    false
  end
end
