# SUSE's openQA tests
#
# Copyright © 2016 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: prepare environment for HPC module testing
# Maintainer: Anton Smorodskyi <asmorodskyi@suse.com>, soulofdestiny <mgriessmeier@suse.com>

use base "opensusebasetest";
use strict;
use warnings;
use testapi;
use utils;
use lockapi;

sub run() {
    barrier_wait("NODES_STARTED");
    barrier_wait("NETWORK_READY");
    # hpc channels
    my $repo     = get_required_var('HPC_REPO');
    my $reponame = "SLE-Module-HPC";
    select_console('root-console');
    assert_script_run "systemctl stop SuSEfirewall2";
    pkcon_quit();
    assert_script_run "zypper ar -f $repo $reponame";
    if (my $openhpc_repo = get_var("OPENHPC_REPO")) {
        assert_script_run "zypper -n addrepo -f $openhpc_repo OPENHPC_REPO";
    }
    assert_script_run "zypper -n --gpg-auto-import-keys ref";
    assert_script_run 'zypper -n up';
    # reboot when running processes use deleted files after packages update
    type_string "zypper ps|grep 'PPID' || echo OK | tee /dev/$serialdev\n";
    save_screenshot;
}

sub test_flags() {
    return {fatal => 1, milestone => 1};
}

1;
# vim: set sw=4 et:
