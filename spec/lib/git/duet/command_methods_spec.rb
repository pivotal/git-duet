require 'git/duet/command_methods'

describe Git::Duet::CommandMethods do
  subject do
    Class.new do
      include Git::Duet::CommandMethods

      def var_map
        {
          'FIZZLE_BAZ' => 'awesome',
          'OH_SNARF' => 'mumra'
        }
      end
    end.new
  end

  before :each do
    subject.stub(:in_repo_root) do |&block|
      block.call
    end
  end

  it 'should write env vars to the local repo hooks directory' do
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

    subject.send(:write_env_vars)
  end
end
