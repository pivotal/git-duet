# vim:fileencoding=utf-8
require 'git/duet/pre_commit_command'

describe Git::Duet::PreCommitCommand do
  subject(:cmd) { described_class.new(true) }

  before :each do
    cmd.stub(:in_repo_root) do |&block|
      block.call
    end
    @old_seconds_ago_stale = ENV.delete('GIT_DUET_SECONDS_AGO_STALE')
    ENV['GIT_DUET_SECONDS_AGO_STALE'] = '300'
  end

  after :each do
    ENV['GIT_DUET_SECONDS_AGO_STALE'] = @old_seconds_ago_stale
  end

  it 'does not require any params to initialize' do
    expect { described_class.new }.to_not raise_error
  end

  it 'does nothing if the env cache is not stale' do
    cmd.stub(:exec_check).with(/git config #{Git::Duet::Config.namespace}.git/)
    cmd.stub(:exec_check).with("git config #{Git::Duet::Config.namespace}.mtime")
      .and_return(Time.now.to_i)
    cmd.should_not_receive(:explode!)
    cmd.execute!
  end

  it 'explodes if the env cache does not exist' do
    cmd.stub(:exec_check).with(/git config #{Git::Duet::Config.namespace}.git/)
    cmd.stub(:exec_check).with("git config #{Git::Duet::Config.namespace}.mtime")
      .and_raise(StandardError)
    expect { cmd.execute! }.to raise_error(Git::Duet::ScriptDieError)
  end
end
