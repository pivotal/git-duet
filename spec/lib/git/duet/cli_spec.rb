# vim:fileencoding=utf-8
require 'git/duet/cli'
require 'git/duet/solo_command'
require 'git/duet/duet_command'
require 'git/duet/pre_commit_command'

describe Git::Duet::Cli do
  subject(:cli) { described_class }

  it 'responds to `.main`' do
    cli.should respond_to(:run)
  end

  it 'requires the prog name and argv array' do
    expect { cli.run }.to raise_error(ArgumentError)
  end

  it 'explodes on unknown prog names' do
    expect { cli.run('bork', []) }.to raise_error(ScriptError)
  end

  it 'returns the exit status from any script error deaths' do
    cli.stub(:solo).and_raise(Git::Duet::ScriptDieError.new(99))
    cli.run('git-solo', %w(ty -q)).should == 99
  end

  it 'runs `solo` when the progname matches /solo$/' do
    Git::Duet::SoloCommand.stub(new: double('solo').tap do |solo|
      solo.should_receive(:execute!)
    end)
    cli.run('git-solo', %w(jd -q))
  end

  it 'runs `duet` when progname matches /duet$/' do
    Git::Duet::DuetCommand.stub(new: double('duet').tap do |duet|
      duet.should_receive(:execute!)
    end)
    cli.run('git-duet', %w(jd fb -q))
  end

  it 'runs `pre_commit` when progname matches /pre-commit$/' do
    Git::Duet::PreCommitCommand.stub(new: double('pre-commit').tap do |pc|
      pc.should_receive(:execute!)
    end)
    cli.run('git-duet-pre-commit', %w(-q))
  end
end
