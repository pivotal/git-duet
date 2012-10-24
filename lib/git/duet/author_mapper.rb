require 'yaml'
require 'git/duet'

class Git::Duet::AuthorMapper
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
    if @email_lookup
      author_email = `#{@email_lookup} '#{initials}' '#{author}' '#{username}'`.strip
      return author_email if !author_email.empty?
    end

    if email_addresses[initials]
      return email_addresses[initials]
    elsif username
      return "#{username}@#{email_domain}"
    else
      author_name_parts = author.split
      return "#{author_name_parts.first[0,1].downcase}." <<
             "#{author_name_parts.last.downcase}@#{email_domain}"
    end
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

  def cfg
    @cfg ||= YAML.load(IO.read(@authors_file))
  end
end
