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
        exec_check("git config duet.env.#{key.downcase.gsub(/_/, '-')} '#{value}'")
      end
      exec_check("git config duet.env.mtime #{Time.now.to_i}")
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
