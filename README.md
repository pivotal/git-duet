# git duet

Pair harmoniously!  Working in a pair doesn't mean you've both lost your
identity.  `git duet` helps with blaming/praising by using stuff that's
already in `git` without littering your repo history with fictitous user
identities.

## Installation

Install it with `gem`:

~~~~~ bash
gem install git-duet
~~~~~

## Usage

### Setup

Make an authors file with email domain, or if you're already using
[git pair](https://github.com/pivotal/git_scripts), just symlink your
`~/.pairs` file over to `~/.git-authors`.

~~~~~ yaml
authors:
  jd: Jane Doe; jane
  fb: Frances Bar
email:
  domain: awesometown.me
~~~~~

`git duet` will use the `git pair` YAML structure if it has to, e.g.:

~~~~~ yaml
pairs:
  jd: Jane Doe; jane
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

### Workflow stuff

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

### Email Configuration

Email addresses are constructed from the first initial and last name
(*or* optional username after a `;`) plus email domain, e.g. with the
following authors file:

~~~~~ yaml
pairs:
  jd: Jane Doe; jane
  fb: Frances Bar
email:
  domain: eternalstench.bog
~~~~~

After invoking:

~~~~~ bash
git duet jd fb
~~~~~

Then the configured email addresses will be:

~~~~~ bash
git config duet.env.git-author-email
# -> jane@eternalstench.bog
git config duet.env.git-committer-email
# -> f.bar@eternalstench.bog
~~~~~

If the default email address format doesn't work for you, explicitly
setting email addresses by initials is supported, too, and takes
precedence over the optional username (after `;`):

~~~~~ yaml
pairs:
  jd: Jane Doe; jane
  fb: Frances Bar
email:
  domain: awesometown.me
email_addresses:
  jd: jane@awesome.biz
~~~~~

Which will result in Jane Doe having an email set of `jane@awesome.biz`.

Alternatively, if you have some other preferred way to look up email
addresses by initials, name or username, just use that instead:

~~~~~ bash
export GIT_DUET_EMAIL_LOOKUP_COMMAND="$HOME/bin/custom-ldap-thingy"
# ... do work
git duet jd fb
# ... observe emails being set via the specified executable
~~~~~

The initials, name, and username will be passed as arguments to the
lookup executable.  Anything written to standard output will be used as
the email address:

~~~~~ bash
$HOME/bin/custom-ldap-thingy 'jd' 'Jane Doe' 'jane'
# -> doej@behemoth.org
~~~~~

If nothing is returned on standard output, email construction falls back
to the decisions described above.

### Git hook integration

If you'd like to regularly remind yourself to set the solo or duet
initials, use `git duet-pre-commit` in your pre-commit hook:

*(in $REPO_ROOT/.git/hooks/pre-commit)*
~~~~~ bash
#!/bin/bash
exec < /dev/tty
exec git duet-pre-commit
~~~~~

The `duet-pre-commit` command will prompt for duet/solo initials if the
cached author and committer settings are missing or stale.  The default
staleness cutoff is 5 minutes, but may be configured via the
`GIT_DUET_SECONDS_AGO_STALE` environmental variable, which should be an
integer of seconds, e.g.:

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
