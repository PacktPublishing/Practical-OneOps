
# This is CPAN.pm's systemwide configuration file. This file provides
# defaults for users, and the values can be changed in a per-user
# configuration file. The user-config file is being looked for as
# /home/oneops/.cpan/CPAN/MyConfig.pm.

$CPAN::Config = {
  'auto_commit' => q[1],
  'build_cache' => q[100],
  'build_dir' => q[/home/oneops/.cpan/build],
  'build_dir_reuse' => q[0],
  'build_requires_install_policy' => q[ask/yes],
  'cache_metadata' => q[1],
  'check_sigs' => q[0],
  'commandnumber_in_prompt' => q[1],
  'connect_to_internet_ok' => q[0],
  'cpan_home' => q[/home/oneops/.cpan],
  'ftp_passive' => q[1],
  'ftp_proxy' => q[],
  'getcwd' => q[cwd],
  'halt_on_failure' => q[0],
  'http_proxy' => q[],
  'inactivity_timeout' => q[0],
  'index_expire' => q[1],
  'inhibit_startup_message' => q[0],
  'keep_source_where' => q[/home/oneops/.cpan/sources],
  'load_module_verbosity' => q[v],
  'make_arg' => q[],
  'make_install_arg' => q[],
  'make_install_make_command' => q[],
  'makepl_arg' => q[INSTALLDIRS=site],
  'mbuild_arg' => q[],
  'mbuild_install_arg' => q[],
  'mbuild_install_build_command' => q[./Build],
  'mbuildpl_arg' => q[--installdirs site],
  'no_proxy' => q[],
  'pager' => q[/usr/bin/less],
  'perl5lib_verbosity' => q[v],
  'prefer_installer' => q[MB],
  'prefs_dir' => q[/home/oneops/.cpan/prefs],
  'prerequisites_policy' => q[follow],
  'scan_cache' => q[atstart],
  'shell' => q[/bin/bash],
  'show_upload_date' => q[0],
  'tar_verbosity' => q[v],
  'term_is_latin' => q[1],
  'term_ornaments' => q[1],
  'trust_test_report_history' => q[0],
  'urllist' => [q[http://mirrors.kernel.org/cpan/], q[http://mirrors1.kernel.org/cpan/], q[http://mirrors2.kernel.org/cpan/], q[http://www.perl.com/CPAN/]],
  'use_sqlite' => q[0],
  'yaml_load_code' => q[0],
};
1;
__END__