# git duet

An opinionated alternative to Pivotal's `git-pair` executable.  Working
in a pair doesn't mean you've both lost your identity.  `git duet` helps
with blaming/praising by using stuff that's already in `git` rather than
littering your repo history with fictitous user identities.

## Installation

Install it with `gem`:

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

If you want your authors file to live somwhere else, just tell
`git-duet` about it via the `GIT_DUET_AUTHORS_FILE` environmental
variable, e.g.:

~~~~~ bash
export GIT_DUET_AUTHORS_FILE=$HOME/.secret-squirrel/git-authors
# ...
git duet jd am
~~~~~

Explicitly setting email addresses by initials is supported, too:

~~~~~ yaml
pairs:
  jd: Jane Doe
  fb: Frances Bar
email:
  domain: awesometown.me
email_addresses:
  jd: jane@awesome.biz
~~~~~

Set the author and committer via `git duet`:

~~~~~ bash
git duet jd fb
~~~~~

When you're ready to commit, use `git duet-commit` (or add an alias like
a normal person.  Something like `dci = duet-commit` should work.)

~~~~~ bash
git duet-commit -v [any other git options]
~~~~~

When you're done pairing, set the author back to yourself with `git solo`:

~~~~~ bash
git solo jd
~~~~~

If you'd like to regularly remind yourself to set the solo or duet
initials, use `git duet-pre-commit` in your pre-commit hook:

*(in $REPO_ROOT/.git/hooks/pre-commit)*
~~~~~ bash
#!/bin/bash
exec < /dev/tty
exec git duet-pre-commit
~~~~~

This pre-commit hook will prompt for duet/solo initials if the env cache
file is either missing or stale.  The default staleness cutoff is 5
minutes, but may be configured via the `GIT_DUET_SECONDS_AGO_STALE`
environmental variable, which should be an integer of seconds, e.g.:

~~~~~ bash
export GIT_DUET_SECONDS_AGO_STALE=60
# ... do work for more than a minute
git commit -v
# ... pre-commit hook fires
~~~~~

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
