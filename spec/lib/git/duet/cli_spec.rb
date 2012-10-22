require 'git/duet/cli'

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

  it 'should run `solo` when the progname matches /solo$/' do
    subject.should_receive(:parse_solo_options).and_return({})
    subject.should_receive(:solo)
    subject.run('git-solo', ['jd'])
  end
end
