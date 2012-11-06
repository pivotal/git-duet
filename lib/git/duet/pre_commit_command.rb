require 'git/duet'
require 'git/duet/command_methods'
require 'git/duet/script_die_error'

class Git::Duet::PreCommitCommand
  include Git::Duet::CommandMethods

  def initialize(quiet = false)
    @quiet = !!quiet
  end

  def execute!
    return explode! if !STDIN.tty?
    in_repo_root do
      if !env_cache_exists? || env_cache_stale?
        set_duet!
      else
        dump_env_vars
      end
    end
  end

  private
  def explode!
    error("Standard input is not a tty, human!")
    error("I'm going home.")
    raise Git::Duet::ScriptDieError.new(1)
  end

  def env_cache_exists?
    with_output_quieted do
      exec_check('git config duet.env.mtime')
    end
    true
  rescue
    false
  end

  def env_cache_stale?
    Integer(exec_check('git config duet.env.mtime')) < stale_cutoff
  end

  def stale_cutoff
    Integer(Time.now - Integer(ENV.fetch('GIT_DUET_SECONDS_AGO_STALE', '300')))
  end

  def set_duet!
    require 'git/duet/author_mapper'
    initials = get_initials
    if initials.length == 1
      require 'git/duet/solo_command'
      Git::Duet::SoloCommand.new(initials.first, @quiet).execute!
    elsif initials.length == 2
      require 'git/duet/duet_command'
      Git::Duet::DuetCommand.new(initials.first, initials.last, @quiet).execute!
    end
  end

  def author_mapper
    @author_mapper ||= Git::Duet::AuthorMapper.new
  end

  def get_initials
    if ENV['GIT_DUET_PRE_COMMIT_INITIALS']
      env_initials = ENV['GIT_DUET_PRE_COMMIT_INITIALS'].chomp.split
      if initials_valid?(env_initials)
        return env_initials
      else
        error("Initials provided in GIT_DUET_PRE_COMMIT_INITIALS are invalid, human.")
        raise Git::Duet::ScriptDieError.new(11)
      end
    end

    loop do
      with_output_unquieted do
        info("---> Who's in this duet (or solo)?")
        prompt
      end
      initials = STDIN.gets.chomp.split
      return initials if initials_valid?(initials)
    end
  end

  def initials_valid?(initials)
    if [1, 2].include?(initials.length) && author_mapper.map(*initials)
      return true
    end
    with_output_unquieted do
      if initials.length > 2
        error('---> Too many initials!')
      else
        error('---> Seriously...')
      end
    end
    false
  rescue IndexError, KeyError => e
    with_output_unquieted do
      error("---> #{e.message}")
    end
    false
  end
end
