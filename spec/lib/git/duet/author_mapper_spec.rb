require 'git/duet/author_mapper'

describe Git::Duet::AuthorMapper do
  before :each do
    subject.instance_variable_set(:@cfg, {
      'authors' => {
        'jd' => 'Jane Doe; jdoe',
        'fb' => 'Frances Bar; frances',
        'qx' => 'Quincy Xavier; qx',
        'hb' => 'Hampton Bones'
      },
      'email' => {
        'domain' => 'awesometown.me'
      },
      'email_addresses' => {
        'jd' => 'jane@awesome.biz'
      }
    })
  end

  after :each do
    ENV.delete('GIT_DUET_AUTHORS_FILE')
  end

  it 'should use an authors file given at initialization' do
    instance = described_class.new('/blarggie/blarggie/new/friend/.git-authors')
    instance.authors_file.should == '/blarggie/blarggie/new/friend/.git-authors'
  end

  it 'should use the `GIT_DUET_AUTHORS_FILE` if provided' do
    ENV['GIT_DUET_AUTHORS_FILE'] = '/fizzle/bizzle/.git-authors'
    instance = described_class.new
    instance.authors_file.should == '/fizzle/bizzle/.git-authors'
  end

  it 'should fall back to using `~/.git-authors` for the author map' do
    subject.authors_file.should == File.join(ENV['HOME'], '.git-authors')
  end

  it 'should let missing author errors bubble up' do
    expect { subject.map('bzzzrt') }.to raise_error
  end

  it 'should map initials to name -> email pairs' do
    subject.map('jd').fetch('jd').should == {
      :name => 'Jane Doe',
      :email => 'jane@awesome.biz'
    }
  end

  it 'should construct default email addresses from first initial and last name plus domain' do
    subject.map('hb').should == {
      'hb' => {
        :name => 'Hampton Bones',
        :email => 'h.bones@awesometown.me'
      }
    }
  end

  it 'should construct email addresses from optional username (if given) plus domain' do
    subject.map('fb').should == {
      'fb' => {
        :name => 'Frances Bar',
        :email => 'frances@awesometown.me'
      }
    }
  end

  it 'should use an explicitly-configured email address if given' do
    subject.map('jd').should == {
      'jd' => {
        :name => 'Jane Doe',
        :email => 'jane@awesome.biz'
      }
    }
  end

  it 'should map any number of initials to name -> email pairs' do
    subject.map('jd', 'fb', 'qx', 'hb').should == {
      'jd' => {
        :name => 'Jane Doe',
        :email => 'jane@awesome.biz'
      },
      'fb' => {
        :name => 'Frances Bar',
        :email => 'frances@awesometown.me'
      },
      'qx' => {
        :name => 'Quincy Xavier',
        :email => 'qx@awesometown.me'
      },
      'hb' => {
        :name => 'Hampton Bones',
        :email => 'h.bones@awesometown.me'
      }
    }
  end

  context 'when using a `~/.pairs` config' do
    before :each do
      subject.stub(:cfg => {
        'pairs' => {
          'jd' => 'Jane Doe; jdoe',
          'fb' => 'Frances Bar; frances',
          'qx' => 'Quincy Xavier; qx',
          'hb' => 'Hampton Bones'
        },
        'email' => {
          'domain' => 'awesometown.me'
        },
        'email_addresses' => {
          'jd' => 'jane@awesome.biz'
        }
      })
    end

    it 'should map initials to name -> email pairs' do
      subject.map('jd').fetch('jd').should == {
        :name => 'Jane Doe',
        :email => 'jane@awesome.biz'
      }
    end

    it 'should map any number of initials to name -> email pairs' do
      subject.map('jd', 'fb', 'qx', 'hb').should == {
        'jd' => {
          :name => 'Jane Doe',
          :email => 'jane@awesome.biz'
        },
        'fb' => {
          :name => 'Frances Bar',
          :email => 'frances@awesometown.me'
        },
        'qx' => {
          :name => 'Quincy Xavier',
          :email => 'qx@awesometown.me'
        },
        'hb' => {
          :name => 'Hampton Bones',
          :email => 'h.bones@awesometown.me'
        }
      }
    end
  end

  context 'when the authors file does not exist' do
    let :bad_path do
      "/its/#{rand(999)}/hosed/#{rand(999)}/captain/#{rand(999)}/.git-authors"
    end

    subject do
      described_class.new(bad_path)
    end

    before :each do
      subject.instance_variable_set(:@cfg, nil)
      IO.stub(:read).with(bad_path).and_raise(
        Errno::ENOENT.new("No such file or directory - #{bad_path}")
      )
    end

    it 'should warn about missing authors file' do
      $stderr.should_receive(:puts).with(
        /Missing or corrupt authors file.*#{bad_path}/i
      )
      expect { subject.map('zzz') }.to raise_error
    end

    it 'should raise a ScriptDieError' do
      $stderr.stub(:puts)
      expect { subject.map('zzz') }.to raise_error(Git::Duet::ScriptDieError)
    end
  end
end
