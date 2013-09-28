# encoding: utf-8
require 'git/duet/pre_commit_command'

describe Git::Duet::PreCommitCommand do
  subject do
    described_class.new(true)
  end

  before :each do
    subject.stub(:in_repo_root) do |&block|
      block.call
    end
    @old_seconds_ago_stale = ENV.delete('GIT_DUET_SECONDS_AGO_STALE')
    ENV['GIT_DUET_SECONDS_AGO_STALE'] = '300'
  end

  after :each do
    ENV['GIT_DUET_SECONDS_AGO_STALE'] = @old_seconds_ago_stale
  end

  it 'should not require any params to initialize' do
    expect { described_class.new }.to_not raise_error
  end

  it 'should do nothing if the env cache is not stale' do
    subject.stub(:exec_check).with(/git config duet\.env\.git/)
    subject.stub(:exec_check).with('git config duet.env.mtime').and_return(Time.now.to_i)
    subject.should_not_receive(:explode!)
    subject.execute!
  end

  it 'should explode if the env cache does not exist' do
    subject.stub(:exec_check).with(/git config duet\.env\.git/)
    subject.stub(:exec_check).with('git config duet.env.mtime').and_raise(StandardError)
    expect { subject.execute! }.to raise_error(Git::Duet::ScriptDieError)
  end
end
