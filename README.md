# Brad's Puppet Manifest

## AWS Bootstrap

```bash
#!/bin/bash

srv_dir="/srv/puppet"
git_dir="$srv_dir/repos/bmf.git"
pup_dir="$srv_dir/manifests/bmf"

# Set hostname
hostnamectl set-hostname www-prod.franklybrad.com

# Install Puppet and EPEL repo
rpm -Uvh https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm
yum install -y epel-release
yum clean all
yum update

# Install packages for bootstrapping Puppet
yum install -y puppet-agent git

# Create CI and Git directories
mkdir -p "$git_dir" "$pup_dir"
git --git-dir "$git_dir" init --bare

# Create Puppet apply script
cat <<-EOF > /usr/local/bin/puppet-apply
#!/bin/bash
/opt/puppetlabs/bin/puppet apply $pup_dir/manifests/site.pp --hiera_config $pup_dir/hiera.yaml --modulepath $pup_dir/modules
EOF

# Fix permissions on Puppet script
chown centos:centos /usr/local/bin/puppet-apply
chmod 775 /usr/local/bin/puppet-apply

# Install post-receive hook
cat <<-EOF > "$git_dir"/hooks/post-receive
#!/bin/bash
set -eu
git --work-tree=$pup_dir checkout -f
cd $pup_dir || echo "ERROR: cannot find the Puppet directory!"
if git --git-dir=$git_dir --work-tree=$pup_dir submodule status | grep -qE '^-'; then
	git --git-dir=$git_dir --work-tree=$pup_dir submodule update --init
else
	git --git-dir=$git_dir --work-tree=$pup_dir submodule update --merge
fi
sudo /usr/local/bin/puppet-apply
EOF

# Fix permissions on CI directories
chown -R centos:centos "$srv_dir"
chmod u+x "$git_dir"/hooks/post-receive

# Install Acme to manage SSL certs
curl https://get.acme.sh | sh
```

1. `export GIT_SSH_COMMAND='ssh -i ~/.ssh/www-us-east-2.pem -o "IdentitiesOnly=yes"'`

