require 'git/duet/cli'
require 'tmpdir'

describe 'git-duet end to end', integration: true do
  before :all do
    @startdir = Dir.pwd
    @tmpdir = Dir.mktmpdir('git-duet-specs')
    @git_authors = File.join(@tmpdir, '.git-authors')
    File.open(@git_authors, 'w') do |f|
      f.puts YAML.dump(
        'pairs' => {
          'jd' => 'Jane Doe',
          'fb' => 'Frances Bar'
        },
        'email' => {
          'domain' => 'hamster.info'
        },
        'email_addresses' => {
          'jd' => 'jane@hamsters.biz'
        }
      )
    end
    ENV['GIT_DUET_AUTHORS_FILE'] = @git_authors
    @repo_dir = File.join(@tmpdir, 'foo')
    Dir.chdir(@tmpdir)
    `git init #{@repo_dir}`
  end

  after :all do
    Dir.chdir(@startdir)
    FileUtils.rm_rf(@tmpdir)
  end

  before :each do
    STDOUT.stub(:puts)
    STDERR.stub(:puts)
  end

  context 'when installing the pre-commit hook' do
    before :each do
      Dir.chdir(@repo_dir)
      FileUtils.rm_f('.git/hooks/pre-commit')
      load File.expand_path('../../../bin/git-duet-install-hook', __FILE__)
      git_duet_install_hook_main
    end

    it 'should write the hook to the `pre-commit` hook file' do
      File.exist?('.git/hooks/pre-commit').should be_true
    end

    it 'should make the `pre-commit` hook file executable' do
      File.executable?('.git/hooks/pre-commit').should be_true
    end
  end

  context 'when setting the author via solo' do
    before :each do
      Git::Duet::Cli.run('git-solo', %w(jd))
    end

    it 'should set the git user name' do
      `git config user.name`.chomp.should == 'Jane Doe'
    end

    it 'should set the git user email' do
      `git config user.email`.chomp.should == 'jane@hamsters.biz'
    end
  end
end
