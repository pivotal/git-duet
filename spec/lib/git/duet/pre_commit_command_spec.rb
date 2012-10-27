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
    expect { described_class.new }.to_not raise_error(ArgumentError)
  end

  it 'should yell and leave if STDIN is not a tty' do
    STDIN.stub(:tty? => false)
    subject.stub(:error)
    subject.should_not_receive(:in_repo_root)
    expect { subject.execute! }.to raise_error(Git::Duet::ScriptDieError)
  end

  it 'should do nothing if the env cache is not stale' do
    subject.stub(:exec_check).with('git config duet.env.mtime').and_return(Time.now.to_i)
    subject.should_not_receive(:set_duet!)
    subject.execute!
  end

  it 'should set the duet if the env cache does not exist' do
    subject.stub(:exec_check).with('git config duet.env.mtime').and_raise(StandardError)
    subject.should_receive(:set_duet!)
    subject.execute!
  end

  context 'when setting the duet (or solo)' do
    before :each do
      subject.stub(:info)
      subject.stub(:error)
      subject.stub(:prompt)
    end

    it 'should run the solo command if one set of initials is provided' do
      subject.stub(:get_initials => ['zx'])
      Git::Duet::SoloCommand.should_receive(:new).with('zx', true)\
        .and_return(double('solo').tap { |solo| solo.should_receive(:execute!) })
      subject.send(:set_duet!)
    end

    it 'should run the duet command if two sets of initials are provided' do
      subject.stub(:get_initials => ['zx', 'aq'])
      Git::Duet::DuetCommand.should_receive(:new).with('zx', 'aq', true)\
        .and_return(double('duet').tap { |duet| duet.should_receive(:execute!) })
      subject.send(:set_duet!)
    end

    it 'should keep prompting for initials on standard input until valid ones are provided' do
      STDIN.should_receive(:gets).and_return("\n")
      STDIN.should_receive(:gets).and_return("az zq xq\n")
      STDIN.should_receive(:gets).and_return("nm\n")
      STDIN.should_receive(:gets).and_return("jd\n")
      subject.should_receive(:initials_valid?).with([]).and_return(false)
      subject.should_receive(:initials_valid?).with(['az', 'zq', 'xq']).and_return(false)
      subject.should_receive(:initials_valid?).with(['nm']).and_return(false)
      subject.should_receive(:initials_valid?).with(['jd']).and_return(true)
      subject.send(:get_initials).should == ['jd']
    end
  end

  context 'when validating initials' do
    before :each do
      subject.stub(:error)
    end

    it 'should return false if no initials are provided' do
      subject.send(:initials_valid?, []).should == false
    end

    it 'should return false if more than two sets of initials are provided' do
      subject.send(:initials_valid?, ['zx', 'aq', 'mp']).should == false
    end

    it 'should return false if author mapping fails' do
      subject.send(:author_mapper).stub(:map).and_raise(KeyError)
      subject.send(:initials_valid?, ['zx', 'aq']).should == false
    end

    it 'should return true if one or two sets of initials are provided and authors exist' do
      subject.send(:author_mapper).stub(:map).and_return({})
      subject.send(:initials_valid?, ['zx', 'aq']).should be_true
    end
  end
end
