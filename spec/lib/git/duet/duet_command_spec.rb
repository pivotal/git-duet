# vim:fileencoding=utf-8
require 'git/duet/duet_command'
require 'support/author_mapper_helper'

describe Git::Duet::DuetCommand do
  include SpecSupport::AuthorMapperHelper

  let(:alpha) { random_author }
  let(:omega) { random_author }
  subject(:cmd) { described_class.new(alpha, omega) }

  before :each do
    cmd.stub(author_mapper: double('author mapper').tap do |am|
      am.stub(map: author_mapping)
    end)
    cmd.stub(:` => '')
    cmd.stub(:report_env_vars)
    Dir.stub(:chdir) do |&block|
      block.call
    end
    File.stub(:open) do |filename, mode, &block|
      block.call(double('outfile').as_null_object)
    end
  end

  it 'requires alpha and omega sets of initials' do
    expect { described_class.new }.to raise_error(ArgumentError)
  end

  it 'responds to `execute!`' do
    cmd.should respond_to(:execute!)
  end

  it '(privately) responds to `write_env_vars`' do
    cmd.private_methods.map(&:to_sym).should include(:write_env_vars)
  end

  it 'sets the alpha name as git config user.name' do
    cmd.stub(:`).with(/git config user\.email/)
    cmd.should_receive(:`)
      .with("git config user.name '#{author_mapping[alpha][:name]}'")
    cmd.execute!
  end

  it 'sets the alpha email as git config user.email' do
    cmd.stub(:`).with(/git config user\.name/)
    cmd.should_receive(:`)
      .with("git config user.email '#{author_mapping[alpha][:email]}'")
    cmd.execute!
  end

  it 'reports env vars to $stdout' do
    cmd.unstub(:report_env_vars)
    $stdout.should_receive(:puts)
      .with(/^GIT_AUTHOR_NAME='#{author_mapping[alpha][:name]}'/)
    $stdout.should_receive(:puts)
      .with(/^GIT_AUTHOR_EMAIL='#{author_mapping[alpha][:email]}'/)
    $stdout.should_receive(:puts)
      .with(/^GIT_COMMITTER_NAME='#{author_mapping[omega][:name]}'/)
    $stdout.should_receive(:puts)
      .with(/^GIT_COMMITTER_EMAIL='#{author_mapping[omega][:email]}'/)
    cmd.execute!
  end

  it 'sets the alpha as author and omega as committer in custom git config' do
    cmd.should_receive(:write_env_vars)
    cmd.execute!
  end

  %w(alpha omega).each do |author_type|
    context "when the #{author_type} cannot be found" do
      let(:"#{author_type}") { 'brzzzt' }

      it 'aborts' do
        cmd.stub(error: nil)
        expect { cmd.execute! }.to raise_error(Git::Duet::ScriptDieError)
      end
    end
  end

  context 'when configured to operate on the global config' do
    subject(:cmd) { described_class.new(alpha, omega, false, true) }

    it 'sets the alpha name as global git config user.name' do
      cmd.stub(:`).with(/git config --global user\.email/)
      alpha_name = author_mapping[alpha][:name]
      cmd.should_receive(:`)
        .with("git config --global user.name '#{alpha_name}'")
      cmd.execute!
    end

    it 'sets the alpha email as global git config user.email' do
      cmd.stub(:`).with(/git config --global user\.name/)
      alpha_email = author_mapping[alpha][:email]
      cmd.should_receive(:`)
        .with("git config --global user.email '#{alpha_email}'")
      cmd.execute!
    end
  end

  context 'when given no arguments' do
    let(:alpha) { nil }
    let(:omega) { nil }

    it 'shows the current duet author settings' do
      git_config_output = <<-EOF.gsub(/^ {8}/, '')
        duet.env.git-author-name Test Author
        duet.env.git-author-email author@test.com
        duet.env.git-committer-name Test Committer
        duet.env.git-committer-email committer@test.com
        duet.env.mtime 1380398044
      EOF

      cmd.stub(:`).with('git config --get-regexp duet.env') do
        git_config_output
      end
      $stdout.should_receive(:puts).with(git_config_output)

      cmd.execute!
    end
  end
end
