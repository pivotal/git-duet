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
    in_repo_root do
      var_map.each do |key,value|
        exec_check("git config duet.env.#{key.downcase.gsub(/_/, '-')} '#{value}'")
      end
      exec_check("git config duet.env.touch #{Time.now.to_i}")
    end
  end

  def in_repo_root
    Dir.chdir(exec_check('git rev-parse --show-toplevel').chomp) do
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
