require 'git/duet/cli'
require 'git/duet/solo_command'
require 'git/duet/duet_command'
require 'git/duet/pre_commit_command'

describe Git::Duet::Cli do
  subject { described_class }

  it 'should respond to .main`' do
    subject.should respond_to(:run)
  end

  it 'should require the prog name and argv array' do
    expect { subject.run }.to raise_error(ArgumentError)
  end

  it 'should explode on unknown prog names' do
    expect { subject.run('bork', []) }.to raise_error(ScriptError)
  end

  it 'should return the exit status from any script error deaths' do
    subject.stub(:solo).and_raise(Git::Duet::ScriptDieError.new(99))
    subject.run('git-solo', %w(ty -q)).should == 99
  end

  it 'should run `solo` when the progname matches /solo$/' do
    Git::Duet::SoloCommand.stub(:new => double('solo').tap do |solo|
      solo.should_receive(:execute!)
    end)
    subject.run('git-solo', %w(jd -q))
  end

  it 'should run `duet` when progname matches /duet$/' do
    Git::Duet::DuetCommand.stub(:new => double('duet').tap do |duet|
      duet.should_receive(:execute!)
    end)
    subject.run('git-duet', %w(jd fb -q))
  end

  it 'should run `pre_commit` when progname matches /pre-commit$/' do
    Git::Duet::PreCommitCommand.stub(:new => double('pre-commit').tap do |pc|
      pc.should_receive(:execute!)
    end)
    subject.run('git-duet-pre-commit', %w(-q))
  end
end
