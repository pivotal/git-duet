# vim:fileencoding=utf-8
require 'yaml'
require 'erb'
require 'git/duet'

module Git
  module Duet
    class AuthorMapper
      attr_accessor :authors_file

      def initialize(authors_file = nil, email_lookup = nil)
        @authors_file = authors_file ||
          ENV['GIT_DUET_AUTHORS_FILE'] ||
          File.join(ENV['HOME'], '.git-authors')
        @email_lookup = email_lookup ||
          ENV['GIT_DUET_EMAIL_LOOKUP_COMMAND']
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
        author, username = author_map.fetch(initials).split(/;/).map(&:strip)
        {
          name: author,
          email: lookup_author_email(initials, author, username)
        }
      end

      def lookup_author_email(initials, author, username)
        author_email = email_from_lookup(initials, author, username)
        return author_email unless author_email.empty?
        return email_addresses[initials] if email_addresses[initials]
        return email_from_template(initials, author, username) if email_template
        return "#{username}@#{email_domain}" if username

        author_name_parts = author.split
        "#{author_name_parts.first[0, 1].downcase}." \
        "#{author_name_parts.last.downcase}@#{email_domain}"
      end

      def email_from_lookup(initials, author, username)
        return '' unless @email_lookup
        `#{@email_lookup} '#{initials}' '#{author}' '#{username}'`.strip
      end

      # rubocop:disable Lint/UnusedMethodArgument
      # arguments are used via binding
      def email_from_template(initials, author, username)
        return ERB.new(email_template).result(binding)
      rescue StandardError => e
        $stderr.puts("git-duet: email template rendering error: #{e.message}")
        raise Git::Duet::ScriptDieError, 8
      end

      def author_map
        @author_map ||= (cfg['authors'] || cfg['pairs'])
      end

      def email_addresses
        @email_addresses ||= (cfg['email_addresses'] || {})
      end

      def email_domain
        @email_domain ||= cfg.fetch('email').fetch('domain')
      end

      def email_template
        @email_template || cfg['email_template']
      end

      def cfg
        @cfg ||= YAML.load(IO.read(authors_file))
      rescue StandardError => e
        $stderr.puts("git-duet: Missing or corrupt authors file: #{e.message}")
        raise Git::Duet::ScriptDieError, 3
      end
    end
  end
end
