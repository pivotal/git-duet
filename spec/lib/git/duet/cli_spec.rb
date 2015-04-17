# vim:fileencoding=utf-8
require 'git/duet/cli'
require 'git/duet/solo_command'
require 'git/duet/duet_command'
require 'git/duet/pre_commit_command'

describe Git::Duet::Cli do
  subject(:cli) { described_class }

  it 'responds to `.main`' do
    expect(cli).to respond_to(:run)
  end

  it 'requires the prog name and argv array' do
    expect { cli.run }.to raise_error(ArgumentError)
  end

  it 'explodes on unknown prog names' do
    expect { cli.run('bork', []) }.to raise_error(ScriptError)
  end

  it 'returns the exit status from any script error deaths' do
    allow(cli).to receive(:solo).and_raise(Git::Duet::ScriptDieError.new(99))
    expect(cli.run('git-solo', %w(ty -q))).to eq(99)
  end

  it 'runs `solo` when the progname matches /solo$/' do
    allow(Git::Duet::SoloCommand).to receive(:new).and_return(
      double('solo').tap { |solo| expect(solo).to receive(:execute!) }
    )
    cli.run('git-solo', %w(jd -q))
  end

  it 'runs `duet` when progname matches /duet$/' do
    allow(Git::Duet::DuetCommand).to receive(:new).and_return(
      double('duet').tap { |duet| expect(duet).to receive(:execute!) }
    )
    cli.run('git-duet', %w(jd fb -q))
  end

  it 'runs `pre_commit` when progname matches /pre-commit$/' do
    allow(Git::Duet::PreCommitCommand).to receive(:new).and_return(
      double('pre-commit').tap { |pc| expect(pc).to receive(:execute!) }
    )
    cli.run('git-duet-pre-commit', %w(-q))
  end

  it 'defaults to loud and local when running `solo`' do
    allow(Git::Duet::SoloCommand).to receive(:new).with('jd', be_falsey, be_falsey).and_return(
      double('solo').as_null_object
    )
    cli.run('git-solo', %w(jd))
  end

  it 'parses options for quietness and globality when running `solo`' do
    allow(Git::Duet::SoloCommand).to receive(:new).with('jd', be_truthy, be_truthy).and_return(
      double('solo').as_null_object
    )
    cli.run('git-solo', %w(jd -q -g))
  end

  it 'defaults to loud and local when running `duet`' do
    allow(Git::Duet::DuetCommand).to receive(:new).with('jd', 'fb', be_falsey, be_falsey).and_return(
      double('duet').as_null_object
    )
    cli.run('git-duet', %w(jd fb))
  end

  it 'parses options for quietness and globality when running `duet`' do
    allow(Git::Duet::DuetCommand).to receive(:new).with('jd', 'fb', be_truthy, be_truthy).and_return(
      double('duet').as_null_object
    )
    cli.run('git-duet', %w(jd fb -q -g))
  end
end
