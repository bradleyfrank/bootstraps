# Brad's Puppet Manifest

Bootstraps and manages MacOS and RedHat-based distros.

## Bootstrap

### AWS

The AWS script acts as a wrapper to create and grant `sudo` access to `[username]`. It then runs the regular bootstrap script as the new user.

`curl -fsSL https://bradleyfrank.github.io/puppet/bin/aws.sh | sudo bash -s -- -u [username]`

### Linux & MacOS

`curl -fsSL https://bradleyfrank.github.io/puppet/bin/run.sh | bash`

