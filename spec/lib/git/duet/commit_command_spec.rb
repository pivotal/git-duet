require 'git/duet/commit_command'

describe Git::Duet::CommitCommand do
  subject do
    described_class.new(%w(-v))
  end

  before :each do
    File.stub(readlines: [
      "FASHIZZLE='1'\n",
      "HOGTIED='false'\n"
    ])
    subject.stub(:exec)
  end

  it 'should require passthrough options' do
    expect { described_class.new }.to raise_error(ArgumentError)
  end

  it 'should respond to `execute!`' do
    subject.should respond_to(:execute!)
  end

  it 'should add all cached env vars to the ENV hash' do
    ENV.should_receive(:[]=).with('FASHIZZLE', '1')
    ENV.should_receive(:[]=).with('HOGTIED', 'false')
    subject.execute!
  end

  it 'should exec git commit with --signoff' do
    subject.should_receive(:exec).with(/^git commit --signoff.*-v/)
    subject.execute!
  end

  it 'should not prompt for verified duet by default' do
    subject.should_not_receive(:prompt_for_verified_duet)
  end

  context 'when verify_duet is true' do
    subject do
      described_class.new(%w(-v), true)
    end

    it 'should prompt for duet initials' do
      subject.should_receive(:prompt_for_verified_duet)
      subject.execute!
    end
  end
end
