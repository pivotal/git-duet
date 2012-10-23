require 'git/duet'

module Git::Duet::CommandMethods
  private
  def report_env_vars
    return if @quiet
    var_map.each do |key,value|
      STDOUT.puts "#{key}='#{value}'"
    end
  end

  def write_env_vars
    out = []
    var_map.each do |key,value|
      out << "#{key}='#{value}'"
    end
    in_repo_root do
      File.open(env_cache_path, 'w') do |f|
        f.puts out.join($/)
      end
    end
  end

  def env_cache_path
    '.git/hooks/git-duet-env-cache.txt'
  end

  def in_repo_root
    Dir.chdir(`git rev-parse --show-toplevel`.chomp) do
      yield
    end
  end

  def exec_check(command)
    output = `#{command}`
    if $?.exitstatus != 0
      raise StandardError.new(
        "Command #{command.inspect} exited with #{$?.to_i}"
      )
    end
    output
  end
end
