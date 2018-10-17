# Class: bmf
# ===========================
#
# Authors
# -------
#
# Brad Frank <bradley.frank@gmail.com>
#
class bmf (
  $configs,
  $config_defaults,
  $users,
  $user_defaults,
  $repos,
  $repos_defaults,
  $packages,
  $package_defaults,
  $services,
  $service_defaults,
  $ssh_keys,
) {

  include selinux

  ## Configs & Files
  create_resources(file, $configs, $config_defaults)

  ## Users & Groups
  create_resources(user, $users, $user_defaults)
  create_resources(ssh_authorized_key, $ssh_keys)

  ## Packages
  create_resources(package, $packages, $package_defaults)

  ## Repos
  create_resources(yumrepo, $repos, $repos_defaults)

  ## Services
  create_resources(service, $services, $service_defaults)

}
