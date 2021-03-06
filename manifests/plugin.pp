# munin::plugin
#
# Parameters:
#
# - ensure: "link", "present", "absent" or "". Default is "". The
#   ensure parameter is mandatory for installing a plugin.
# - source: when ensure => present, source file
# - content: when ensure => present, the literal text of the plugin source file (useful with `template()`)
# - target: when ensure => link, link target.  If target is an
#   absolute path (starts with "/") it is used directly.  If target is
#   a relative path, $munin::node::plugin_share_dir is prepended.
# - config: array of lines for munin plugin config
# - config_label: label for munin plugin config

define munin::plugin (
    $ensure='',
    $source=undef,
    $content=undef,
    $target='',
    $config=undef,
    $config_label=undef,
    $config_mode='0644',
)
{

    include ::munin::node

    $plugin_share_dir=$munin::node::plugin_share_dir
    validate_absolute_path($plugin_share_dir)

    File {
        require => Package[$munin::node::package_name],
        notify  => Service[$munin::node::service_name],
    }

    validate_re($ensure, '^(|link|present|absent)$')
    case $ensure {
        'present', 'absent': {
            $handle_plugin = true
            $plugin_ensure = $ensure
            $plugin_target = undef
        }
        'link': {
            $handle_plugin = true
            $plugin_ensure = 'link'
            case $target {
                '': {
                    $plugin_target = "${munin::node::plugin_share_dir}/${title}"
                }
                /^\//: {
                    $plugin_target = $target
                }
                default: {
                    $plugin_target = "${munin::node::plugin_share_dir}/${target}"
                }
            }
            validate_absolute_path($plugin_target)
        }
        default: {
            $handle_plugin = false
        }
    }

    if $config {
        $config_ensure = $ensure ? {
            'absent'=> absent,
            default => present,
        }
    }
    else {
        $config_ensure = absent
    }


    if $handle_plugin {
        # Install the plugin
        file {"${munin::node::config_root}/plugins/${name}":
            * => $content ? {
                undef => { source => $source },
                default => { content => $content },
            },
            ensure => $plugin_ensure,
            target => $plugin_target,
            mode   => '0755',
        }
    }

    # Config

    file{ "${munin::node::config_root}/plugin-conf.d/${name}.conf":
      ensure  => $config_ensure,
      content => template('munin/plugin_conf.erb'),
      mode   => $config_mode,
    }

}
