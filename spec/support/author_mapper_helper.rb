# vim:fileencoding=utf-8

module SpecSupport
  module AuthorMapperHelper
    def random_author
      author_mapping.keys.send(RUBY_VERSION < '1.9' ? :choice : :sample)
    end

    def author_mapping
      {
        'jd' => {
          name: 'Jane Doe',
          email: 'jane@awesome.biz'
        },
        'fb' => {
          name: 'Frances Bar',
          email: 'frances@awesometown.me'
        },
        'qx' => {
          name: 'Quincy Xavier',
          email: 'qx@awesometown.me'
        },
        'hb' => {
          name: 'Hampton Bones',
          email: 'h.bones@awesometown.me'
        }
      }
    end
  end
end
