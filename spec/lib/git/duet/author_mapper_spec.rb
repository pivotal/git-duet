# vim:fileencoding=utf-8
require 'git/duet/author_mapper'

describe Git::Duet::AuthorMapper do
  before :each do
    subject.instance_variable_set(
      :@cfg,
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
    )
  end

  after :each do
    ENV.delete('GIT_DUET_AUTHORS_FILE')
  end

  it 'uses an authors file given at initialization' do
    instance = described_class
               .new('/blarggie/blarggie/new/friend/.git-authors')
    expect(instance.authors_file)
      .to eq('/blarggie/blarggie/new/friend/.git-authors')
  end

  it 'uses the `GIT_DUET_AUTHORS_FILE` if provided' do
    ENV['GIT_DUET_AUTHORS_FILE'] = '/fizzle/bizzle/.git-authors'
    instance = described_class.new
    expect(instance.authors_file).to eq('/fizzle/bizzle/.git-authors')
  end

  it 'falls back to using `~/.git-authors` for the author map' do
    expect(subject.authors_file).to eq(File.join(ENV['HOME'], '.git-authors'))
  end

  it 'lets missing author errors bubble up' do
    expect { subject.map('bzzzrt') }.to raise_error
  end

  it 'maps initials to name -> email pairs' do
    expect(subject.map('jd').fetch('jd'))
      .to eq(name: 'Jane Doe', email: 'jane@awesome.biz')
  end

  it 'constructs default emails from first initial and last name + domain' do
    expect(subject.map('hb')).to eq('hb' => {
                                      name: 'Hampton Bones',
                                      email: 'h.bones@awesometown.me'
                                    })
  end

  it 'constructs emails from optional username (if given) + domain' do
    expect(subject.map('fb')).to eq('fb' => {
                                      name: 'Frances Bar',
                                      email: 'frances@awesometown.me'
                                    })
  end

  it 'uses an explicitly-configured email address if given' do
    expect(subject.map('jd')).to eq('jd' => {
                                      name: 'Jane Doe',
                                      email: 'jane@awesome.biz'
                                    })
  end

  it 'maps any number of initials to name -> email pairs' do
    expect(subject.map('jd', 'fb', 'qx', 'hb')).to eq(
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
    )
  end

  context 'when using a `~/.pairs` config' do
    before :each do
      allow(subject).to receive(:cfg).and_return(
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
      )
    end

    it 'maps initials to name -> email pairs' do
      expect(subject.map('jd').fetch('jd'))
        .to eq(name: 'Jane Doe', email: 'jane@awesome.biz')
    end

    it 'maps any number of initials to name -> email pairs' do
      expect(subject.map('jd', 'fb', 'qx', 'hb')).to eq(
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
      )
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
      allow(IO).to receive(:read).with(bad_path).and_raise(
        Errno::ENOENT.new("No such file or directory - #{bad_path}")
      )
    end

    it 'warns about missing authors file' do
      expect($stderr).to receive(:puts).with(
        /Missing or corrupt authors file.*#{bad_path}/i
      )
      expect { subject.map('zzz') }.to raise_error
    end

    it 'raises a ScriptDieError' do
      allow($stderr).to receive(:puts)
      expect { subject.map('zzz') }.to raise_error(Git::Duet::ScriptDieError)
    end
  end
end
