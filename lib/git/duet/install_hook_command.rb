# encoding: utf-8
require 'git/duet'
require 'fileutils'
require 'git/duet/command_methods'

class Git::Duet::InstallHookCommand
  include Git::Duet::CommandMethods

  HOOK = <<-EOF.gsub(/^  /, '')
  #!/bin/bash
  exec git duet-pre-commit "$@"
  EOF

  def initialize(quiet = false)
    @quiet = quiet
  end

  def execute!
    Dir.chdir(`git rev-parse --show-toplevel`.chomp) do
      dest = File.join(Dir.pwd, '.git', 'hooks', 'pre-commit')
      if File.exist?(dest)
        error("git-duet-install-hook: A pre-commit hook already exists at #{dest}!")
        error('git-duet-install-hook: Move it out of the way first, mkay?')
        return 1
      end
      File.open(dest, 'w') do |f|
        f.puts HOOK
      end
      FileUtils.chmod(0755, dest)
      info("git-duet-install-hook: Installed hook to #{dest}")
    end
    return 0
  end
end
