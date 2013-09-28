# encoding: utf-8
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
    [:info, :error].each do |m|
      subject.stub(m)
    end
    subject.stub(:in_repo_root) do |&block|
      block.call
    end
  end

  it 'should write env vars to a custom git config tree' do
    subject.should_receive(:`).with("git config duet.env.fizzle-baz 'awesome'")
    subject.should_receive(:`).with("git config duet.env.oh-snarf 'mumra'")
    subject.should_receive(:`).with(/^git config duet\.env\.mtime \d+/)
    subject.send(:write_env_vars)
  end

  it 'should explode if a subshell returns non-zero' do
    subject.stub(:`)
    $?.should_receive(:exitstatus).and_return(1)
    expect { subject.send(:exec_check, 'ls hamsters') }.to raise_error(StandardError)
  end

  context 'when configured to operate on the global config' do
    before :each do
      subject.instance_variable_set(:@global, true)
    end

    it 'should write env vars to a custom global git config tree' do
      subject.should_receive(:`).with("git config --global duet.env.fizzle-baz 'awesome'")
      subject.should_receive(:`).with("git config --global duet.env.oh-snarf 'mumra'")
      subject.should_receive(:`).with(/^git config --global duet\.env\.mtime \d+/)
      subject.send(:write_env_vars)
    end
  end
end
