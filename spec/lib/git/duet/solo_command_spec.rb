require 'git/duet/solo_command'

describe Git::Duet::SoloCommand do
  def random_author
    %w(jd fb qx hb).sample
  end

  let :author_mapping do
    {
      'jd' => {
        name: 'Jane Doe',
        email: 'jane@awesome.biz'
      },
      'fb' => {
        name: 'Frances Bar',
        email: 'frances@awesometown.me'
      },
      'qx' => {
        name: 'Quincy Xavier',
        email: 'qx@awesometown.me'
      },
      'hb' => {
        name: 'Hampton Bones',
        email: 'h.bones@awesometown.me'
      }
    }
  end

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

  xit 'should set the alpha email as git config user.email' do
    subject.stub(:`).with(/git config user\.name/)
    subject.should_receive(:`).with("git config user.email '#{author_mapping[alpha][:email]}'")
    subject.execute!
  end

  xit 'should report env vars to STDOUT' do
    subject.unstub(:report_env_vars)
    STDOUT.should_receive(:puts).with(/^GIT_AUTHOR_NAME='#{author_mapping[alpha][:name]}'/)
    STDOUT.should_receive(:puts).with(/^GIT_AUTHOR_EMAIL='#{author_mapping[alpha][:email]}'/)
    STDOUT.should_receive(:puts).with(/^GIT_COMMITTER_NAME='#{author_mapping[omega][:name]}'/)
    STDOUT.should_receive(:puts).with(/^GIT_COMMITTER_EMAIL='#{author_mapping[omega][:email]}'/)
    subject.execute!
  end

  xit 'should set the alpha as author and omega as committer in env var cache' do
    subject.should_receive(:write_env_vars)
    subject.execute!
  end

  xit 'should write env vars to the local repo hooks directory' do
    written = []
    File.should_receive(:open) do |filename,mode,&block|
      filename.should =~ %r{\.git/hooks/git-duet-env-cache\.txt}
      block.call(double('outfile').tap do |f|
        f.stub(:puts) do |string|
          written += string.split($/)
        end
      end)
      written.should include("FIZZLE_BAZ='awesome'")
    end

    subject.stub(var_map: {
      'FIZZLE_BAZ' => 'awesome',
      'OH_SNARF' => 'mumra'
    })
    subject.send(:write_env_vars)
  end
end
