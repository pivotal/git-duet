# vim:fileencoding=utf-8
require 'git/duet'
require 'fileutils'
require 'git/duet/command_methods'

module Git
  module Duet
    class InstallHookCommand
      include Git::Duet::CommandMethods

      HOOK = <<-EOF.gsub(/^ {8}/, '')
        #!/bin/bash
        exec git duet-pre-commit "$@"
      EOF

      def initialize(quiet = false)
        @quiet = quiet
      end

      def execute!
        Dir.chdir(`git rev-parse --show-toplevel`.chomp) do
          dest = File.join(Dir.pwd, '.git', 'hooks', 'pre-commit')
          return error_hook_exists(dest) if File.exist?(dest)
          File.open(dest, 'w') { |f| f.puts HOOK }
          FileUtils.chmod(0755, dest)
          info("git-duet-install-hook: Installed hook to #{dest}")
        end
        0
      end

      private

      def error_hook_exists(dest)
        error('git-duet-install-hook: ' \
              "A pre-commit hook already exists at #{dest}!")
        error('git-duet-install-hook: Move it out of the way first, mkay?')
        1
      end
    end
  end
end
