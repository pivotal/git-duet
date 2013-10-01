# vim:fileencoding=utf-8
require 'git/duet/solo_command'
require 'support/author_mapper_helper'

describe Git::Duet::SoloCommand do
  include SpecSupport::AuthorMapperHelper

  let(:soloist) { random_author }

  subject(:cmd) { described_class.new(soloist) }

  before :each do
    cmd.stub(author_mapper: double('author mapper').tap do |am|
      am.stub(map: author_mapping)
    end)
    cmd.stub(:` => '')
    cmd.stub(:report_env_vars)
    cmd.stub(:in_repo_root) do |&block|
      block.call
    end
  end

  it 'requires soloist initials' do
    expect { described_class.new }.to raise_error(ArgumentError)
  end

  it 'responds to `execute!`' do
    cmd.should respond_to(:execute!)
  end

  it '(privately) responds to `write_env_vars`' do
    cmd.private_methods.map(&:to_sym).should include(:write_env_vars)
  end

  it 'sets the soloist name as git config user.name' do
    cmd.stub(:`).with(/git config user\.email/)
    cmd.stub(:`).with(/git config --unset-all #{Git::Duet::Config.namespace}/)
    cmd.should_receive(:`)
      .with("git config user.name '#{author_mapping[soloist][:name]}'")
    cmd.execute!
  end

  it 'sets the soloist email as git config user.email' do
    cmd.stub(:`).with(/git config user\.name/)
    cmd.stub(:`).with(/git config --unset-all #{Git::Duet::Config.namespace}/)
    cmd.should_receive(:`)
      .with("git config user.email '#{author_mapping[soloist][:email]}'")
    cmd.execute!
  end

  it 'unsets the committer name' do
    cmd.stub(:`).with(/git config user\.name/)
    cmd.stub(:`).with(/git config user\.email/)
    cmd.stub(:`).with(/git config --unset-all #{Git::Duet::Config.namespace}.git-committer-email/)
    cmd.should_receive(:`)
      .with("git config --unset-all #{Git::Duet::Config.namespace}.git-committer-name")
    cmd.execute!
  end

  it 'unsets the committer email' do
    cmd.stub(:`).with(/git config user\.name/)
    cmd.stub(:`).with(/git config user\.email/)
    cmd.stub(:`).with(/git config --unset-all #{Git::Duet::Config.namespace}.git-committer-name/)
    cmd.should_receive(:`)
      .with("git config --unset-all #{Git::Duet::Config.namespace}.git-committer-email")
    cmd.execute!
  end

  it 'reports env vars to $stdout' do
    cmd.unstub(:report_env_vars)
    $stdout.should_receive(:puts)
      .with(/^GIT_AUTHOR_NAME='#{author_mapping[soloist][:name]}'/)
    $stdout.should_receive(:puts)
      .with(/^GIT_AUTHOR_EMAIL='#{author_mapping[soloist][:email]}'/)
    cmd.execute!
  end

  it 'sets the soloist as author in custom git config' do
    cmd.should_receive(:write_env_vars)
    cmd.execute!
  end

  context 'when soloist is missing' do
    let(:soloist) { 'bzzzrt' }

    it 'aborts' do
      cmd.stub(error: nil)
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

      cmd.stub(:`).with("git config --get-regexp #{Git::Duet::Config.namespace}") do
        git_config_output
      end
      $stdout.should_receive(:puts).with(git_config_output)

      cmd.execute!
    end
  end

  context 'when configured to operate on the global config' do
    subject(:cmd) { described_class.new(soloist, false, true) }

    it 'sets the soloist name as global git config user.name' do
      cmd.stub(:`).with(/git config --global user\.email/)
      cmd.stub(:`).with(/git config --global --unset-all #{Git::Duet::Config.namespace}/)
      soloist_name = author_mapping[soloist][:name]
      cmd.should_receive(:`)
        .with("git config --global user.name '#{soloist_name}'")
      cmd.execute!
    end

    it 'sets the soloist email as global git config user.email' do
      cmd.stub(:`).with(/git config --global user\.name/)
      cmd.stub(:`).with(/git config --global --unset-all #{Git::Duet::Config.namespace}/)
      soloist_email = author_mapping[soloist][:email]
      cmd.should_receive(:`)
        .with("git config --global user.email '#{soloist_email}'")
      cmd.execute!
    end

    it 'unsets the global committer name' do
      cmd.stub(:`).with(/git config --global user\.name/)
      cmd.stub(:`).with(/git config --global user\.email/)
      cmd.stub(:`)
        .with(/git config --global --unset-all #{Git::Duet::Config.namespace}.git-committer-email/)
      cmd.should_receive(:`)
        .with("git config --global --unset-all #{Git::Duet::Config.namespace}.git-committer-name")
      cmd.execute!
    end

    it 'unsets the global committer email' do
      cmd.stub(:`).with(/git config --global user\.name/)
      cmd.stub(:`).with(/git config --global user\.email/)
      cmd.stub(:`)
        .with(/git config --global --unset-all #{Git::Duet::Config.namespace}.git-committer-name/)
      cmd.should_receive(:`)
        .with("git config --global --unset-all #{Git::Duet::Config.namespace}.git-committer-email")
      cmd.execute!
    end
  end
end
