require 'git/duet/command_methods'

describe Git::Duet::CommandMethods do
  subject do
    Class.new do
      include Git::Duet::CommandMethods

      def var_map
        {
          'FIZZLE_BAZ' => 'awesome',
          'OH_SNARF' => 'mumra'
        }
      end
    end.new
  end

  before :each do
    subject.stub(:in_repo_root) do |&block|
      block.call
    end
  end

  it 'should write env vars to a custom git config tree' do
    subject.should_receive(:`).with("git config duet.env.FIZZLE_BAZ 'awesome'")
    subject.should_receive(:`).with("git config duet.env.OH_SNARF 'mumra'")
    subject.should_receive(:`).with(/^git config duet.env.touch \d+/)
    subject.send(:write_env_vars)
  end
end
