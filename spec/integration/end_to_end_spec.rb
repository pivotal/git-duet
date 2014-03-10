# vim:fileencoding=utf-8
require 'tmpdir'
require 'posix-spawn' unless RUBY_PLATFORM == 'java'

describe 'git-duet end to end', integration: true do
  EMAIL_LOOKUP_SCRIPT = <<-EOF.gsub(/^  /, '')
  #!/usr/bin/env ruby
  addr = {
    'jd' => 'jane_doe@lookie.me.local',
    'fb' => 'fb9000@dalek.info.local'
  }[ARGV.first]
  puts addr
  EOF

  @capture_status = nil

  def sh(cmd)
    return `#{cmd}` if RUBY_PLATFORM == 'java'

    pid, input, output, _ = POSIX::Spawn.popen4(cmd, err: '/dev/null')
    input.close
    @capture_status = Process.waitpid2(pid).last
    output.read
  ensure
    output.close
  end

  def install_hook
    Dir.chdir(@repo_dir) do
      sh('git duet-install-hook -q')
    end
  end

  def uninstall_hook
    Dir.chdir(@repo_dir) do
      FileUtils.rm_f('.git/hooks/pre-commit')
    end
  end

  def make_an_edit
    Dir.chdir(@repo_dir) do
      File.open('file.txt', 'w') { |f| f.puts "foo-#{rand(100_000)}" }
      sh('git add file.txt')
    end
  end

  before :all do
    ENV['GIT_DUET_CONFIG_NAMESPACE'] = 'foo.bar'

    @startdir = Dir.pwd
    @tmpdir = Dir.mktmpdir('git-duet-specs')
    @git_authors = File.join(@tmpdir, '.git-authors')
    @email_lookup_path = File.join(@tmpdir, 'email-lookup')

    File.open(@git_authors, 'w') do |f|
      f.puts YAML.dump(
        'pairs' => {
          'jd' => 'Jane Doe',
          'fb' => 'Frances Bar',
          'zp' => 'Zubaz Pants'
        },
        'email' => {
          'domain' => 'hamster.info.local'
        },
        'email_addresses' => {
          'jd' => 'jane@hamsters.biz.local'
        }
      )
    end
    ENV['GIT_DUET_AUTHORS_FILE'] = @git_authors

    top_bin = File.expand_path('../../../bin', __FILE__)
    ENV['PATH'] = "#{top_bin}:#{ENV['PATH']}"

    File.open(@email_lookup_path, 'w') { |f| f.puts EMAIL_LOOKUP_SCRIPT }
    FileUtils.chmod(0755, @email_lookup_path)

    @repo_dir = File.join(@tmpdir, 'foo')
    Dir.chdir(@tmpdir) do
      sh("git init #{@repo_dir}")
    end
  end

  after :all do
    Dir.chdir(@startdir)
    if ENV['RSPEC_NO_CLEANUP']
      File.open('integration-end-to-end-test-dir.txt', 'w') do |f|
        f.puts @tmpdir
      end
    else
      FileUtils.rm_rf(@tmpdir)
    end
  end

  context 'when installing the pre-commit hook' do
    before(:each) do
      Dir.chdir(@repo_dir)
      install_hook
    end

    after(:each) { uninstall_hook }

    it 'writes the hook to the `pre-commit` hook file' do
      File.exist?('.git/hooks/pre-commit').should be_true
    end

    it 'makes the `pre-commit` hook file executable' do
      File.executable?('.git/hooks/pre-commit').should be_true
    end
  end

  context 'when setting the author via solo' do
    before :each do
      Dir.chdir(@repo_dir)
      sh('git solo jd -q')
    end

    it 'sets the git user name' do
      sh('git config user.name').chomp.should == 'Jane Doe'
    end

    it 'sets the git user email' do
      sh('git config user.email').chomp.should == 'jane@hamsters.biz.local'
    end

    it 'caches the git user name as author name' do
      sh("git config #{Git::Duet::Config.namespace}.git-author-name").chomp
        .should == 'Jane Doe'
    end

    it 'caches the git user email as author email' do
      sh("git config #{Git::Duet::Config.namespace}.git-author-email").chomp
        .should == 'jane@hamsters.biz.local'
    end
  end

  context 'when an external email lookup is provided' do
    before :each do
      @old_email_lookup = ENV.delete('GIT_DUET_EMAIL_LOOKUP_COMMAND')
      ENV['GIT_DUET_EMAIL_LOOKUP_COMMAND'] = @email_lookup_path
    end

    after :each do
      ENV['GIT_DUET_EMAIL_LOOKUP_COMMAND'] = @old_email_lookup
    end

    context 'when setting the author via solo' do
      before :each do
        Dir.chdir(@repo_dir)
        sh('git solo jd -q')
      end

      it 'sets the author email given by the external email lookup' do
        sh("git config #{Git::Duet::Config.namespace}.git-author-email").chomp
          .should == 'jane_doe@lookie.me.local'
      end
    end

    context 'when setting author and committer via duet' do
      before :each do
        Dir.chdir(@repo_dir)
        sh('git duet jd fb -q')
      end

      it 'sets the author email given by the external email lookup' do
        sh("git config #{Git::Duet::Config.namespace}.git-author-email").chomp
          .should == 'jane_doe@lookie.me.local'
      end

      it 'sets the committer email given by the external email lookup' do
        sh(
          "git config #{Git::Duet::Config.namespace}.git-committer-email"
        ).chomp.should == 'fb9000@dalek.info.local'
      end
    end
  end

  context 'when a custom email template is provided' do
    before :each do
      authors_cfg = YAML.load_file(@git_authors)
      @name_suffix = rand(9999)
      authors_cfg['email_template'] =
        %Q^<%= '' << author.split.first.downcase << ^ <<
          %Q^author.split.last[0].chr.downcase << ^ <<
          %Q^'#{@name_suffix}@mompopshop.local' %>^
      File.open(@git_authors, 'w') do |f|
        f.puts YAML.dump(authors_cfg)
      end
    end

    after :each do
      authors_cfg = YAML.load_file(@git_authors)
      authors_cfg.delete('email_template')
      File.open(@git_authors, 'w') do |f|
        f.puts YAML.dump(authors_cfg)
      end
    end

    context 'after running git-solo' do
      before :each do
        Dir.chdir(@repo_dir)
        sh('git solo zp -q')
        make_an_edit
      end

      it 'uses the email template to construct the author email' do
        sh("git duet-commit -q -m 'Testing custom email template for author'")
        sh("git log -1 --format='%an <%ae>'").chomp
          .should == "Zubaz Pants <zubazp#{@name_suffix}@mompopshop.local>"
      end

      it 'uses the email template to construct the committer email' do
        sh('git duet-commit -q ' <<
           "-m 'Testing custom email template for committer'")
        sh("git log -1 --format='%cn <%ce>'").chomp
          .should == "Zubaz Pants <zubazp#{@name_suffix}@mompopshop.local>"
      end
    end

    context 'after running git-duet' do
      before :each do
        Dir.chdir(@repo_dir)
        sh('git duet zp fb -q')
        make_an_edit
      end

      it 'uses the email template to construct the author email' do
        sh("git duet-commit -q -m 'Testing custom email template for author'")
        sh("git log -1 --format='%an <%ae>'").chomp
          .should == "Zubaz Pants <zubazp#{@name_suffix}@mompopshop.local>"
      end

      it 'uses the email template to construct the committer email' do
        sh('git duet-commit -q ' <<
           "-m 'Testing custom email template for committer'")
        sh("git log -1 --format='%cn <%ce>'").chomp
          .should == "Frances Bar <francesb#{@name_suffix}@mompopshop.local>"
      end
    end
  end

  context 'when setting author and committer via duet' do
    before :each do
      Dir.chdir(@repo_dir)
      sh('git duet jd fb -q')
    end

    it 'sets the git user name' do
      sh('git config user.name').chomp.should == 'Jane Doe'
    end

    it 'sets the git user email' do
      sh('git config user.email').chomp.should == 'jane@hamsters.biz.local'
    end

    it 'caches the git committer name' do
      sh("git config #{Git::Duet::Config.namespace}.git-committer-name").chomp
        .should == 'Frances Bar'
    end

    it 'caches the git committer email' do
      sh("git config #{Git::Duet::Config.namespace}.git-committer-email").chomp
        .should == 'f.bar@hamster.info.local'
    end
  end

  context 'when committing via git-duet-commit' do
    context 'after running git-duet' do
      before :each do
        Dir.chdir(@repo_dir)
        sh('git duet jd fb -q')
        make_an_edit
      end

      it 'lists the alpha of the duet as author in the log' do
        sh("git duet-commit -q -m 'Testing set of alpha as author'")
        sh("git log -1 --format='%an <%ae>'").chomp
          .should == 'Jane Doe <jane@hamsters.biz.local>'
      end

      it 'lists the omega of the duet as committer in the log' do
        sh("git duet-commit -q -m 'Testing set of omega as committer'")
        sh("git log -1 --format='%cn <%ce>'").chomp
          .should == 'Frances Bar <f.bar@hamster.info.local>'
      end

      context 'when no author has been set' do
        before do
          Dir.chdir(@repo_dir)
          %w(git-author-email git-author-name).each do |config|
            sh("git config --unset #{Git::Duet::Config.namespace}.#{config}")
          end
          make_an_edit
        end

        it 'raises an error if committed without the -q option' do
          sh("git duet-commit -q -m 'Testing commit with no author'")
          @capture_status.to_i.should_not == 0
        end

        it 'fails to add a commit' do
          expect do
            sh("git duet-commit -q -m 'testing commit with no author'")
          end.to_not change { sh('git log -1 --format=%H').chomp }
        end
      end

      context 'with the pre-commit hook in place' do
        before :each do
          sh("git commit -m 'Committing before installing the hook'")
          @latest_sha1 = sh('git log -1 --format=%H').chomp
          make_an_edit
          install_hook
          sh("git config --unset-all #{Git::Duet::Config.namespace}.mtime")
          ENV['GIT_DUET_QUIET'] = '1'
        end

        after :each do
          uninstall_hook
          ENV.delete('GIT_DUET_QUIET')
        end

        it 'fires the hook and reject the commit' do
          sh("git duet-commit -q -m 'Testing hook firing'")
          sh('git log -1 --format=%H').chomp.should == @latest_sha1
        end
      end
    end

    context 'after running git-solo' do
      before :each do
        Dir.chdir(@repo_dir)
        sh('git solo jd -q')
        make_an_edit
      end

      it 'lists the soloist as author in the log' do
        sh("git duet-commit -m 'Testing set of soloist as author'")
        sh("git log -1 --format='%an <%ae>'").chomp
          .should == 'Jane Doe <jane@hamsters.biz.local>'
      end

      it 'lists the soloist as committer in the log' do
        sh("git duet-commit -m 'Testing set of soloist as committer'")
        sh("git log -1 --format='%cn <%ce>'").chomp
          .should == 'Jane Doe <jane@hamsters.biz.local>'
      end

      it 'does not include "Signed-off-by" in the commit message' do
        sh("git duet-commit -m 'Testing omitting signoff'")
        sh("grep 'Signed-off-by' .git/COMMIT_EDITMSG").chomp.should == ''
      end

      context 'with the pre-commit hook in place' do
        before :each do
          sh("git commit -m 'Committing before installing the hook'")
          @latest_sha1 = sh('git log -1 --format=%H').chomp
          make_an_edit
          install_hook
          sh("git config --unset-all #{Git::Duet::Config.namespace}.mtime")
          ENV['GIT_DUET_QUIET'] = '1'
        end

        after :each do
          uninstall_hook
          ENV.delete('GIT_DUET_QUIET')
        end

        it 'fires the hook and reject the commit' do
          sh("git duet-commit -q -m 'Testing hook firing'")
          sh('git log -1 --format=%H').chomp.should == @latest_sha1
        end
      end
    end
  end
end
