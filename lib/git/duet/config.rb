# vim:fileencoding=utf-8

module Git
  module Duet
    class Config
      def self.namespace
        ENV['GIT_DUET_CONFIG_NAMESPACE'] || 'duet.env'
      end
    end
  end
end
