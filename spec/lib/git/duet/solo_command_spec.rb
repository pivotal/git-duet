require 'git/duet/solo_command'
require 'support/author_mapper_helper'

describe Git::Duet::SoloCommand do
  include SpecSupport::AuthorMapperHelper

  let :soloist do
    random_author
  end

  subject do
    described_class.new(soloist)
  end

  before :each do
    subject.stub(author_mapper: double('author mapper').tap do |am|
      am.stub(map: author_mapping)
    end)
    subject.stub(:` => '')
    subject.stub(:report_env_vars)
    Dir.stub(:chdir) do |&block|
      block.call
    end
    File.stub(:open) do |filename,mode,&block|
      block.call(double('outfile').as_null_object)
    end
  end

  it 'should require soloist initials' do
    expect { described_class.new }.to raise_error(ArgumentError)
  end

  it 'should respond to `execute!`' do
    subject.should respond_to(:execute!)
  end

  it 'should (privately) respond to `write_env_vars`' do
    subject.private_methods.should include(:write_env_vars)
  end

  it 'should set the soloist name as git config user.name' do
    subject.stub(:`).with(/git config user\.email/)
    subject.should_receive(:`).with("git config user.name '#{author_mapping[soloist][:name]}'")
    subject.execute!
  end

  it 'should set the soloist email as git config user.email' do
    subject.stub(:`).with(/git config user\.name/)
    subject.should_receive(:`).with("git config user.email '#{author_mapping[soloist][:email]}'")
    subject.execute!
  end

  it 'should report env vars to STDOUT' do
    subject.unstub(:report_env_vars)
    STDOUT.should_receive(:puts).with(/^GIT_AUTHOR_NAME='#{author_mapping[soloist][:name]}'/)
    STDOUT.should_receive(:puts).with(/^GIT_AUTHOR_EMAIL='#{author_mapping[soloist][:email]}'/)
    subject.execute!
  end

  it 'should set the soloist as author in env var cache' do
    subject.should_receive(:write_env_vars)
    subject.execute!
  end
end
