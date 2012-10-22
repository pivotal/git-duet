require 'yaml'

module Git
  module Duet
    class AuthorMapper
      def initialize(authors_file = nil)
        @authors_file = authors_file ||
                        ENV['GIT_DUET_AUTHORS_FILE'] ||
                        File.join(ENV['HOME'], '.git-authors')
      end

      def map(*initials_list)
        author_map = {}
        initials_list.each do |initials|
          author_map[initials] = author_info(initials)
        end
        author_map
      end

      private
      def author_info(initials)
        author = author_map[initials].split(/;/).first

        if user_email_overrides[initials]
          author_email = "#{user_email_overrides[initials]}@#{email_domain}"
        else
          author_name_parts = author.split
          author_email = "#{author_name_parts.first[0,1].downcase}." <<
                         "#{author_name_parts.last.downcase}@#{email_domain}"
        end

        {
          name: author,
          email: author_email
        }
      end

      def author_map
        @author_map ||= (cfg['authors'] || cfg['pairs'])
      end

      def user_email_overrides
        @user_email_overrides ||= (cfg['user_email_overrides'] || {})
      end

      def email_domain
        @email_domain ||= cfg.fetch('email').fetch('domain')
      end

      def cfg
        @cfg ||= YAML.load(IO.read(@authors_file))
      end
    end
  end
end
