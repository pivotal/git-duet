require 'git/duet'
require 'fileutils'

class Git::Duet::InstallHookCommand
  HOOK = <<-EOF.gsub(/^  /, '')
  #!/bin/bash
  exec < /dev/tty
  exec git duet-pre-commit
  EOF

  def initialize(quiet = false)
    @quiet = quiet
  end

  def execute!
    Dir.chdir(`git rev-parse --show-toplevel`.chomp) do
      dest = File.join(Dir.pwd, '.git', 'hooks', 'pre-commit')
      if File.exist?(dest)
        unless @quiet
          STDERR.puts "git-duet-install-hook: A pre-commit hook already exists at #{dest}!"
          STDERR.puts "git-duet-install-hook: Move it out of the way first, mkay?"
        end
        return 1
      end
      File.open(dest, 'w') do |f|
        f.puts HOOK
      end
      FileUtils.chmod(0755, dest)
      STDOUT.puts "git-duet-install-hook: Installed hook to #{dest}" unless @quiet
    end
    return 0
  end
end
