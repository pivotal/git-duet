# vim:fileencoding=utf-8
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
      allow(subject).to receive(m)
    end
    allow(subject).to receive(:in_repo_root) do |&block|
      block.call
    end
  end

  it 'writes env vars to a custom git config tree' do
    expect(subject).to receive(:`)
      .with("git config #{Git::Duet::Config.namespace}.fizzle-baz 'awesome'")
    expect(subject).to receive(:`)
      .with("git config #{Git::Duet::Config.namespace}.oh-snarf 'mumra'")
    expect(subject).to receive(:`)
      .with(/^git config #{Git::Duet::Config.namespace}.mtime \d+/)
    subject.send(:write_env_vars)
  end

  it 'explodes if a subshell returns non-zero' do
    allow(subject).to receive(:`)
    expect($CHILD_STATUS).to receive(:exitstatus).and_return(1)
    expect { subject.send(:exec_check, 'ls hamsters') }
      .to raise_error(StandardError)
  end

  context 'when configured to operate on the global config' do
    before :each do
      subject.instance_variable_set(:@global, true)
    end

    it 'writes env vars to a custom global git config tree' do
      expect(subject).to receive(:`)
        .with("git config --global #{Git::Duet::Config.namespace}" \
              ".fizzle-baz 'awesome'")
      expect(subject).to receive(:`)
        .with("git config --global #{Git::Duet::Config.namespace}" \
              ".oh-snarf 'mumra'")
      expect(subject).to receive(:`)
        .with(/^git config --global #{Git::Duet::Config.namespace}.mtime \d+/)
      subject.send(:write_env_vars)
    end
  end
end
