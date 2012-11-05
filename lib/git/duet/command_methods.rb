require 'git/duet'
require 'git/duet/script_die_error'

module Git::Duet::CommandMethods
  private
  def report_env_vars
    var_map.each do |key,value|
      info("#{key}='#{value}'")
    end
  end

  def write_env_vars
    in_repo_root do
      var_map.each do |key,value|
        exec_check("git config #{@global ? '--global ' : ''}duet.env.#{key.downcase.gsub(/_/, '-')} '#{value}'")
      end
      exec_check("git config #{@global ? '--global ' : ''}duet.env.mtime #{Time.now.to_i}")
    end
  end

  def dump_env_vars
    extract_env_vars_from_git_config.each do |k,v|
      puts "#{k}='#{v}'"
    end
  end

  def extract_env_vars_from_git_config
    dest = {}
    env_vars.each do |env_var,config_key|
      begin
        value = exec_check("git config duet.env.#{config_key}").chomp
        dest[env_var] = value if !value.empty?
      rescue StandardError => e
        error("#{e.message}")
      end
    end
    dest
  end

  def exec_git_commit
    exec 'git commit --signoff ' << quoted_passthrough_args
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

  def in_repo_root
    Dir.chdir(exec_check('git rev-parse --show-toplevel').chomp) do
      yield
    end
  end

  def exec_check(command, okay_statuses = [0].freeze)
    output = `#{command}`
    if !okay_statuses.include?($?.exitstatus)
      error("Command #{command.inspect} exited with #{$?.to_i}")
      raise Git::Duet::ScriptDieError.new(1)
    end
    output
  end

  def info(msg)
    STDOUT.puts(msg) unless @quiet
  end

  def error(msg)
    STDERR.puts(msg) unless @quiet
  end

  def prompt
    STDOUT.print '> '
  end
end
