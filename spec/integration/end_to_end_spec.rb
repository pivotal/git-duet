require 'tmpdir'

describe 'git-duet end to end', :integration => true do
  EMAIL_LOOKUP_SCRIPT = <<-EOF.gsub(/^  /, '')
  #!/usr/bin/env ruby
  addr = {
    'jd' => 'jane_doe@lookie.me',
    'fb' => 'fb9000@dalek.info'
  }[ARGV.first]
  puts addr
  EOF

  def install_hook
    Dir.chdir(@repo_dir)
    `git duet-install-hook -q`
  end

  def uninstall_hook
    FileUtils.rm_f('.git/hooks/pre-commit')
  end

  before :all do
    @startdir = Dir.pwd
    @tmpdir = Dir.mktmpdir('git-duet-specs')
    @git_authors = File.join(@tmpdir, '.git-authors')
    @email_lookup_path = File.join(@tmpdir, 'email-lookup')
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
    ENV['PATH'] = "#{File.expand_path('../../../bin', __FILE__)}:#{ENV['PATH']}"
    File.open(@email_lookup_path, 'w') { |f| f.puts EMAIL_LOOKUP_SCRIPT }
    FileUtils.chmod(0755, @email_lookup_path)
    @repo_dir = File.join(@tmpdir, 'foo')
    Dir.chdir(@tmpdir)
    `git init #{@repo_dir}`
  end

  after :all do
    Dir.chdir(@startdir)
    if ENV['RSPEC_NO_CLEANUP']
      File.open('integration-end-to-end-test-dir.txt', 'w') { |f| f.puts @tmpdir }
    else
      FileUtils.rm_rf(@tmpdir)
    end
  end

  context 'when installing the pre-commit hook' do
    before(:each) { install_hook }
    after(:each) { uninstall_hook }

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
      `git solo jd -q`
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
        `git solo jd -q`
      end

      it 'should set the author email address given by the external email lookup' do
        `git config duet.env.git-author-email`.chomp.should == 'jane_doe@lookie.me'
      end
    end

    context 'when setting author and committer via duet' do
      before :each do
        Dir.chdir(@repo_dir)
        `git duet jd fb -q`
      end

      it 'should set the author email address given by the external email lookup' do
        `git config duet.env.git-author-email`.chomp.should == 'jane_doe@lookie.me'
      end

      it 'should set the committer email address given by the external email lookup' do
        `git config duet.env.git-committer-email`.chomp.should == 'fb9000@dalek.info'
      end
    end
  end

  context 'when setting author and committer via duet' do
    before :each do
      Dir.chdir(@repo_dir)
      `git duet jd fb -q`
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
    context 'after running git-duet' do
      before :each do
        Dir.chdir(@repo_dir)
        `git duet jd fb -q`
        File.open('file.txt', 'w') { |f| f.puts "foo-#{rand(100000)}" }
        `git add file.txt`
      end

      it 'should list the alpha of the duet as author in the log' do
        `git duet-commit -q -m 'Testing set of alpha as author'`
        `git log -1 --format='%an <%ae>'`.chomp.should == 'Jane Doe <jane@hamsters.biz>'
      end

      it 'should list the omega of the duet as committer in the log' do
        `git duet-commit -q -m 'Testing set of omega as committer'`
        `git log -1 --format='%cn <%ce>'`.chomp.should == 'Frances Bar <f.bar@hamster.info>'
      end

      context 'with the pre-commit hook in place' do
        before :each do
          install_hook
          `git config --unset-all duet.env.mtime`
          ENV['GIT_DUET_PRE_COMMIT_INITIALS'] = 'jd fb'
          ENV['GIT_DUET_QUIET'] = '1'
        end

        after :each do
          uninstall_hook
          ENV.delete('GIT_DUET_PRE_COMMIT_INITIALS')
          ENV.delete('GIT_DUET_QUIET')
        end

        it 'should fire the hook and set author before allowing commit' do
          `git duet-commit -q -m 'Testing hook firing with author set'`
          `git log -1 --format='%an <%ae>'`.chomp.should == 'Jane Doe <jane@hamsters.biz>'
        end

        it 'should fire the hook and set committer before allowing commit' do
          `git duet-commit -q -m 'Testing hook firing with committer set'`
          `git log -1 --format='%cn <%ce>'`.chomp.should == 'Frances Bar <f.bar@hamster.info>'
        end

        context 'when new initials are provided at hook time' do
          before :each do
            `git duet fb jd`
            `git config --unset-all duet.env.mtime`
          end

          xit 'should use the latest provided author' do
            `git duet-commit -q -m 'Testing use of author initials provided during hook'`
            `git log -1 --format='%an <%ae>'`.chomp.should == 'Jane Doe <jane@hamsters.biz>'
          end

          xit 'should use the latest provided committer' do
            `git duet-commit -q -m 'Testing use of committer initials provided during hook'`
            `git log -1 --format='%cn <%ce>'`.chomp.should == 'Frances Bar <f.bar@hamster.info>'
          end
        end
      end
    end

    context 'after running git-solo' do
      before :each do
        Dir.chdir(@repo_dir)
        `git solo jd -q`
        File.open('file.txt', 'w') { |f| f.puts "foo-#{rand(100000)}" }
        `git add file.txt`
      end

      it 'should list the soloist as author in the log' do
        `git duet-commit -m 'Testing set of soloist as author' 2>/dev/null`
        `git log -1 --format='%an <%ae>'`.chomp.should == 'Jane Doe <jane@hamsters.biz>'
      end

      it 'should list the soloist as committer in the log' do
        `git duet-commit -m 'Testing set of soloist as committer' 2>/dev/null`
        `git log -1 --format='%cn <%ce>'`.chomp.should == 'Jane Doe <jane@hamsters.biz>'
      end

      context 'with the pre-commit hook in place' do
        before :each do
          install_hook
          `git config --unset-all duet.env.mtime`
          ENV['GIT_DUET_PRE_COMMIT_INITIALS'] = 'jd'
          ENV['GIT_DUET_QUIET'] = '1'
        end

        after :each do
          uninstall_hook
          ENV.delete('GIT_DUET_PRE_COMMIT_INITIALS')
          ENV.delete('GIT_DUET_QUIET')
        end

        it 'should fire the hook and set author before allowing commit' do
          `git duet-commit -q -m 'Testing hook firing with author set'`
          `git log -1 --format='%an <%ae>'`.chomp.should == 'Jane Doe <jane@hamsters.biz>'
        end

        it 'should fire the hook and set author as committer before allowing commit' do
          `git duet-commit -q -m 'Testing hook firing with author set as committer'`
          `git log -1 --format='%cn <%ce>'`.chomp.should == 'Jane Doe <jane@hamsters.biz>'
        end

        context 'when new initials are provided at hook time' do
          before :each do
            `git duet fb`
            `git config --unset-all duet.env.mtime`
          end

          xit 'should use the latest provided author' do
            `git duet-commit -q -m 'Testing use of author initials provided during hook'`
            `git log -1 --format='%an <%ae>'`.chomp.should == 'Jane Doe <jane@hamsters.biz>'
          end

          xit 'should use the latest provided author as committer' do
            `git duet-commit -q -m 'Testing use of author initials provided during hook as committer'`
            `git log -1 --format='%cn <%ce>'`.chomp.should == 'Jane Doe <jane@hamsters.biz>'
          end
        end
      end
    end
  end
end
