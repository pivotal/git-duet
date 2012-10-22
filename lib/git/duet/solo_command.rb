require 'git/duet'
require_relative 'author_mapper'
require_relative 'command_methods'

module Git
  module Duet
    class SoloCommand
      include CommandMethods

      def initialize(soloist)
        @soloist = soloist
        @author_mapper = Git::Duet::AuthorMapper.new
      end

      def execute!
        set_soloist_as_git_config_user
      end

      private
      def set_soloist_as_git_config_user
        `git config user.name '#{soloist_info[:name]}'`
        `git config user.email '#{soloist_info[:email]}'`
      end

      def soloist_info
        @soloist_info ||= author_mapper.map(@soloist).fetch(@soloist)
      end
    end
  end
end
