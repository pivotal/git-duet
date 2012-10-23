require 'git/duet/pre_commit_command'

describe Git::Duet::PreCommitCommand do
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
    expect { described_class.new }.to_not raise_error(ArgumentError)
  end

  it 'should yell and leave if STDIN is not a tty' do
    STDIN.stub(tty?: false)
    STDERR.stub(:puts)
    subject.should_not_receive(:in_repo_root)
    expect { subject.execute! }.to raise_error(Git::Duet::ScriptDieError)
  end

  it 'should do nothing if the env cache is not stale' do
    subject.stub(:exec_check).with('git config duet.env.touch').and_return(Time.now.to_i)
    subject.should_not_receive(:set_duet!)
    subject.execute!
  end

  it 'should set the duet if the env cache does not exist' do
    subject.stub(:exec_check).with('git config duet.env.touch').and_raise(StandardError)
    subject.should_receive(:set_duet!)
    subject.execute!
  end

  context 'when setting the duet (or solo)' do
    it 'should run the solo command if one set of initials is provided' do
      subject.stub(get_initials: ['zx'])
      subject.instance_variable_set(:@quiet, true)
      Git::Duet::SoloCommand.should_receive(:new).with('zx', true)
        .and_return(double('solo').tap { |solo| solo.should_receive(:execute!) })
      subject.send(:set_duet!)
    end
  end
end
