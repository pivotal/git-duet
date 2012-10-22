# git duet

An opinionated alternative to Pivotal's `git-pair` executable.  Working
in a pair doesn't mean you've both lost your identity.  `git duet` helps
with blaming/praising by using stuff that's already in `git` rather than
littering your repo history with fictitous user identities.

## Installation

Add this line to your application's Gemfile:

~~~~~ ruby
gem 'git-duet'
~~~~~

And then execute:

~~~~~ bash
bundle
~~~~~

Or install it yourself as:

~~~~~ bash
gem install git-duet
~~~~~

## Usage

Set up an authors file with email domain, or just symlink your Pivotal
`~/.pairs` file over to `~/.git-authors`.

~~~~~ yaml
authors:
  jd: Jane Doe
  fb: Frances Bar
email:
  domain: awesometown.me
~~~~~

`git duet` will use the Pivotal YAML structure if it has to, e.g.:

~~~~~ yaml
pairs:
  jd: Jane Doe
  fb: Frances Bar
email:
  domain: awesometown.me
~~~~~

Set the author and committer via `git duet`:

~~~~~ bash
git duet jd fb
~~~~~

When you're ready to commit, use `git duet-commit` (or add an alias like
a normal person.  something like `dci = duet-commit --`)

~~~~~ bash
git duet-commit -- -v [any other git options]
~~~~~

When you're done pairing, set the author back to yourself with `git solo`:

~~~~~ bash
git solo jd
~~~~~

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
