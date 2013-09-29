# vim:fileencoding=utf-8
require 'git/duet'
require 'git/duet/script_die_error'

module Git::Duet::CommandMethods

  private

  def report_env_vars
    var_map.each do |key, value|
      info("#{key}='#{value}'")
    end
  end

  def write_env_vars
    in_repo_root do
      var_map.each do |key, value|
        exec_check(
          "#{git_config} duet.env.#{key.downcase.gsub(/_/, '-')} '#{value}'"
        )
      end
      exec_check("#{git_config} duet.env.mtime #{Time.now.to_i}")
    end
  end

  def git_config
    "git config#{@global ? ' --global' : ''}"
  end

  def author_env_vars_set?
    %x(#{get_author_name} && #{get_author_email})
    $CHILD_STATUS == 0
  end

  def get_author_name
    'git config --get duet.env.git-author-name'
  end

  def get_author_email
    'git config --get duet.env.git-author-email'
  end

  def get_current_config
    'git config --get-regexp duet.env'
  end

  def show_current_config
    info(exec_check(get_current_config))
  end

  def dump_env_vars
    extract_env_vars_from_git_config.each do |k, v|
      puts "#{k}='#{v}'"
    end
  end

  def extract_env_vars_from_git_config
    dest = {}
    env_vars.each do |env_var, config_key|
      begin
        value = exec_check("git config duet.env.#{config_key}").chomp
        dest[env_var] = value unless value.empty?
      rescue StandardError => e
        error("#{e.message}")
      end
    end
    dest
  end

  def exec_git_commit
    if author_env_vars_set?
      exec 'git commit ' << signoff_arg << quoted_passthrough_args
    else
      raise Git::Duet::ScriptDieError.new(17)
    end
  end

  def in_repo_root
    Dir.chdir(exec_check('git rev-parse --show-toplevel').chomp) do
      yield
    end
  end

  def exec_check(command, okay_statuses = [0].freeze)
    output = `#{command}`
    unless okay_statuses.include?($CHILD_STATUS.exitstatus)
      error("Command #{command.inspect} exited with #{$CHILD_STATUS.to_i}")
      raise Git::Duet::ScriptDieError.new(1)
    end
    output
  end

  def with_output_unquieted(&block)
    @old_quiet = @quiet
    @quiet = false
    block.call
    @quiet = @old_quiet
  rescue StandardError => e
    @quiet = @old_quiet
    raise e
  end

  def with_output_quieted(&block)
    @old_quiet = @quiet
    @quiet = true
    block.call
  rescue StandardError => e
    raise e
  ensure
    @quiet = @old_quiet
  end

  def info(msg)
    $stdout.puts(msg) unless quiet?
  end

  def error(msg)
    $stderr.puts(msg) unless quiet?
  end

  def prompt
    $stdout.print '> '
  end

  def quiet?
    ENV['GIT_DUET_QUIET'] == '1' || @quiet
  end
end
