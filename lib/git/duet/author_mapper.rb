require 'yaml'
require 'git/duet'

class Git::Duet::AuthorMapper
  attr_accessor :authors_file

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
    author, username = author_map.fetch(initials).split(/;/).map(&:strip)

    if email_addresses[initials]
      author_email = email_addresses[initials]
    elsif username
      author_email = "#{username}@#{email_domain}"
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
