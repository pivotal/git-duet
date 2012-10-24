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
      Git::Duet::Cli.run('git-duet-install-hook', [])
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
      Dir.chdir(@repo_dir)
      Git::Duet::Cli.run('git-solo', %w(jd))
    end

    it 'should set the git user name' do
      `git config user.name`.chomp.should == 'Jane Doe'
    end

    it 'should set the git user email' do
      `git config user.email`.chomp.should == 'jane@hamsters.biz'
    end

    it 'should cache the git user name as author name' do
      `git config duet.env.git-author-name`.chomp.should == 'Jane Doe'
    end

    it 'should cache the git user email as author email' do
      `git config duet.env.git-author-email`.chomp.should == 'jane@hamsters.biz'
    end
  end

  context 'when setting author and committer via duet' do
    before :each do
      Dir.chdir(@repo_dir)
      Git::Duet::Cli.run('git-duet', %w(jd fb))
    end

    it 'should set the git user name' do
      `git config user.name`.chomp.should == 'Jane Doe'
    end

    it 'should set the git user email' do
      `git config user.email`.chomp.should == 'jane@hamsters.biz'
    end

    it 'should cache the git committer name' do
      `git config duet.env.git-committer-name`.chomp.should == 'Frances Bar'
    end

    it 'should cache the git committer email' do
      `git config duet.env.git-committer-email`.chomp.should == 'f.bar@hamster.info'
    end
  end

  context 'when committing via git-duet-commit' do
    before :each do
      Dir.chdir(@repo_dir)
      Git::Duet::Cli.run('git-duet', %w(jd fb))
      Git::Duet::Cli.run('git-duet-commit', ['-m', 'Just testing here'])
    end

    xit 'should list the alpha of the duet as author in the log' do
      `git log -1 --format='%an <%ae>'`.chomp.should == 'Jane Doe <jane@hamsters.biz>'
    end

    xit 'should list the omega of the duet as committer in the log' do
      `git log -1 --format='%cn <%ce>'`.chomp.should == 'Frances Bar <f.bar@hamster.info>'
    end
  end
end
