module Git
  module Duet
    class ScriptDieError < StandardError
      attr_reader :exit_code

      def initialize(exit_code)
        @exit_code = exit_code
      end
    end
  end
end
