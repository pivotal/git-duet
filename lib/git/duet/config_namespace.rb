# vim:fileencoding=utf-8

unless defined?(Git::Duet::CONFIG_NAMESPACE)
  module Git
    module Duet
      CONFIG_NAMESPACE = 'duet.env'.freeze
    end
  end
end
