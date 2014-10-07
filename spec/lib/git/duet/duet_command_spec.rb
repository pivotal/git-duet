# vim:fileencoding=utf-8
require 'git/duet/duet_command'
require 'support/author_mapper_helper'

describe Git::Duet::DuetCommand do
  include SpecSupport::AuthorMapperHelper

  let(:alpha) { random_author }
  let(:omega) { random_author }
  subject(:cmd) { described_class.new(alpha, omega) }

  before :each do
    allow(cmd).to receive(:author_mapper).and_return(
      double('author mapper').tap do |am|
        allow(am).to receive(:map).and_return(author_mapping)
      end
    )
    allow(cmd).to receive(:`).and_return('')
    allow(cmd).to receive(:report_env_vars)
    allow(Dir).to receive(:chdir) do |&block|
      block.call
    end
    allow(File).to receive(:open) do |_, _, &block|
      block.call(double('outfile').as_null_object)
    end
  end

  it 'requires alpha and omega sets of initials' do
    expect { described_class.new }.to raise_error(ArgumentError)
  end

  it 'responds to `execute!`' do
    expect(cmd).to respond_to(:execute!)
  end

  it '(privately) responds to `write_env_vars`' do
    expect(cmd.private_methods.map(&:to_sym)).to include(:write_env_vars)
  end

  it 'sets the alpha name as git config user.name' do
    allow(cmd).to receive(:`).with(/git config user\.email/)
    expect(cmd).to receive(:`)
      .with("git config user.name '#{author_mapping[alpha][:name]}'")
    cmd.execute!
  end

  it 'sets the alpha email as git config user.email' do
    allow(cmd).to receive(:`).with(/git config user\.name/)
    expect(cmd).to receive(:`)
      .with("git config user.email '#{author_mapping[alpha][:email]}'")
    cmd.execute!
  end

  it 'reports env vars to $stdout' do
    expect(cmd).to receive(:report_env_vars).and_call_original
    expect($stdout).to receive(:puts)
      .with(/^GIT_AUTHOR_NAME='#{author_mapping[alpha][:name]}'/)
    expect($stdout).to receive(:puts)
      .with(/^GIT_AUTHOR_EMAIL='#{author_mapping[alpha][:email]}'/)
    expect($stdout).to receive(:puts)
      .with(/^GIT_COMMITTER_NAME='#{author_mapping[omega][:name]}'/)
    expect($stdout).to receive(:puts)
      .with(/^GIT_COMMITTER_EMAIL='#{author_mapping[omega][:email]}'/)
    cmd.execute!
  end

  it 'sets the alpha as author and omega as committer in custom git config' do
    expect(cmd).to receive(:write_env_vars)
    cmd.execute!
  end

  %w(alpha omega).each do |author_type|
    context "when the #{author_type} cannot be found" do
      let(:"#{author_type}") { 'brzzzt' }

      it 'aborts' do
        allow(cmd).to receive(:error).and_return(nil)
        expect { cmd.execute! }.to raise_error(Git::Duet::ScriptDieError)
      end
    end
  end

  context 'when configured to operate on the global config' do
    subject(:cmd) { described_class.new(alpha, omega, false, true) }

    it 'sets the alpha name as global git config user.name' do
      allow(cmd).to receive(:`).with(/git config --global user\.email/)
      alpha_name = author_mapping[alpha][:name]
      expect(cmd).to receive(:`)
        .with("git config --global user.name '#{alpha_name}'")
      cmd.execute!
    end

    it 'sets the alpha email as global git config user.email' do
      allow(cmd).to receive(:`).with(/git config --global user\.name/)
      alpha_email = author_mapping[alpha][:email]
      expect(cmd).to receive(:`)
        .with("git config --global user.email '#{alpha_email}'")
      cmd.execute!
    end
  end

  context 'when given no arguments' do
    let(:alpha) { nil }
    let(:omega) { nil }

    it 'shows the current duet author settings' do
      git_config_output = <<-EOF.gsub(/^ {8}/, '')
        #{Git::Duet::Config.namespace}.git-author-name Test Author
        #{Git::Duet::Config.namespace}.git-author-email author@test.com
        #{Git::Duet::Config.namespace}.git-committer-name Test Committer
        #{Git::Duet::Config.namespace}.git-committer-email committer@test.com
        #{Git::Duet::Config.namespace}.mtime 138039#{rand(1000..9999)}
      EOF

      allow(cmd).to receive(:`)
        .with("git config --get-regexp #{Git::Duet::Config.namespace}") do
        git_config_output
      end
      expect($stdout).to receive(:puts).with(git_config_output)

      cmd.execute!
    end
  end
end
