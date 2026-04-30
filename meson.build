project('wp-volume', 'vala', 'c')

gtk_dep     = dependency('gtk+-3.0')
budgie_dep  = dependency('budgie-3.0')
layer_dep   = dependency('gtk-layer-shell-0', required: false)   # na przyszłość

plugin_name = 'wpvolume'
plugin_dir  = join_paths(get_option('libdir'), 'budgie-desktop', 'plugins', plugin_name)

shared_library(
    plugin_name,
    'wp_volume.vala',
    dependencies: [gtk_dep, budgie_dep, layer_dep],
    vala_args: ['--vapidir', meson.current_source_dir()],
    install: true,
    install_dir: plugin_dir
)

install_data(
    'wp-volume.plugin',
    install_dir: plugin_dir
)
