# vim:fileencoding=utf-8
require 'git/duet/solo_command'
require 'support/author_mapper_helper'

describe Git::Duet::SoloCommand do
  include SpecSupport::AuthorMapperHelper

  let(:soloist) { random_author }

  subject(:cmd) { described_class.new(soloist) }

  before :each do
    allow(cmd).to receive(:author_mapper).and_return(
      double('author mapper').tap do |am|
        allow(am).to receive(:map).and_return(author_mapping)
      end
    )
    allow(cmd).to receive(:`).and_return('')
    allow(cmd).to receive(:report_env_vars)
    allow(cmd).to receive(:in_repo_root) do |&block|
      block.call
    end
  end

  it 'requires soloist initials' do
    expect { described_class.new }.to raise_error(ArgumentError)
  end

  it 'responds to `execute!`' do
    expect(cmd).to respond_to(:execute!)
  end

  it '(privately) responds to `write_env_vars`' do
    expect(cmd.private_methods.map(&:to_sym)).to include(:write_env_vars)
  end

  it 'sets the soloist name as git config user.name' do
    allow(cmd).to receive(:`).with(/git config user\.email/)
    allow(cmd).to receive(:`).with(
      /git config --unset-all #{Git::Duet::Config.namespace}/
    )
    expect(cmd).to receive(:`)
      .with("git config user.name '#{author_mapping[soloist][:name]}'")
    cmd.execute!
  end

  it 'sets the soloist email as git config user.email' do
    allow(cmd).to receive(:`).with(/git config user\.name/)
    allow(cmd).to receive(:`).with(
      /git config --unset-all #{Git::Duet::Config.namespace}/
    )
    expect(cmd).to receive(:`)
      .with("git config user.email '#{author_mapping[soloist][:email]}'")
    cmd.execute!
  end

  it 'unsets the committer name' do
    allow(cmd).to receive(:`).with(/git config user\.name/)
    allow(cmd).to receive(:`).with(/git config user\.email/)
    allow(cmd).to receive(:`)
      .with(/git config --unset-all #{Git::Duet::Config
                                      .namespace}.git-committer-email/)
    expect(cmd).to receive(:`)
      .with("git config --unset-all #{Git::Duet::Config
                                      .namespace}.git-committer-name")
    cmd.execute!
  end

  it 'unsets the committer email' do
    allow(cmd).to receive(:`).with(/git config user\.name/)
    allow(cmd).to receive(:`).with(/git config user\.email/)
    allow(cmd).to receive(:`)
      .with(/git config --unset-all #{Git::Duet::Config
                                      .namespace}.git-committer-name/)
    expect(cmd).to receive(:`)
      .with("git config --unset-all #{Git::Duet::Config
                                      .namespace}.git-committer-email")
    cmd.execute!
  end

  it 'reports env vars to $stdout' do
    allow(cmd).to receive(:report_env_vars).and_call_original
    expect($stdout).to receive(:puts)
      .with(/^GIT_AUTHOR_NAME='#{author_mapping[soloist][:name]}'/)
    expect($stdout).to receive(:puts)
      .with(/^GIT_AUTHOR_EMAIL='#{author_mapping[soloist][:email]}'/)
    cmd.execute!
  end

  it 'sets the soloist as author in custom git config' do
    expect(cmd).to receive(:write_env_vars)
    cmd.execute!
  end

  context 'when soloist is missing' do
    let(:soloist) { 'bzzzrt' }

    it 'aborts' do
      allow(cmd).to receive(:error).and_return(nil)
      expect { cmd.execute! }.to raise_error(Git::Duet::ScriptDieError)
    end
  end

  context 'when given no arguments' do
    let(:soloist) { nil }

    it 'shows the current duet author settings' do
      git_config_output = <<-EOF.gsub(/^ {8}/, '')
        #{Git::Duet::Config.namespace}.git-author-name Test Author
        #{Git::Duet::Config.namespace}.git-author-email author@test.com
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

  context 'when configured to operate on the global config' do
    subject(:cmd) { described_class.new(soloist, false, true) }

    it 'sets the soloist name as global git config user.name' do
      allow(cmd).to receive(:`).with(/git config --global user\.email/)
      allow(cmd).to receive(:`)
        .with(/git config --global --unset-all #{Git::Duet::Config.namespace}/)
      soloist_name = author_mapping[soloist][:name]
      expect(cmd).to receive(:`)
        .with("git config --global user.name '#{soloist_name}'")
      cmd.execute!
    end

    it 'sets the soloist email as global git config user.email' do
      allow(cmd).to receive(:`).with(/git config --global user\.name/)
      allow(cmd).to receive(:`)
        .with(/git config --global --unset-all #{Git::Duet::Config.namespace}/)
      soloist_email = author_mapping[soloist][:email]
      expect(cmd).to receive(:`)
        .with("git config --global user.email '#{soloist_email}'")
      cmd.execute!
    end

    it 'unsets the global committer name' do
      allow(cmd).to receive(:`).with(/git config --global user\.name/)
      allow(cmd).to receive(:`).with(/git config --global user\.email/)
      allow(cmd).to receive(:`)
        .with(
          /git config --global --unset-all #{Git::Duet::Config
                                             .namespace}.git-committer-email/
        )
      expect(cmd).to receive(:`)
        .with('git config --global --unset-all ' \
              "#{Git::Duet::Config.namespace}.git-committer-name")
      cmd.execute!
    end

    it 'unsets the global committer email' do
      allow(cmd).to receive(:`).with(/git config --global user\.name/)
      allow(cmd).to receive(:`).with(/git config --global user\.email/)
      allow(cmd).to receive(:`)
        .with(
          /git config --global --unset-all #{Git::Duet::Config
                                             .namespace}.git-committer-name/
        )
      expect(cmd).to receive(:`)
        .with('git config --global --unset-all ' \
              "#{Git::Duet::Config.namespace}.git-committer-email")
      cmd.execute!
    end
  end
end
