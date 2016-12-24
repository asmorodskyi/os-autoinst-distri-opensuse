# SUSE's openQA tests
#
# Copyright © 2016 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Installation of munge package from HPC module and sanity check
# of this package
# Maintainer: Anton Smorodskyi <asmorodskyi@suse.com>, soulofdestiny <mgriessmeier@suse.com>

use base "opensusebasetest";
use strict;
use warnings;
use testapi;
use lockapi;

sub run() {
    # set proper hostname
    assert_script_run "hostnamectl set-hostname munge-master";

    assert_script_run "zypper -n in munge libmunge2";
    barrier_wait "MUNGE_INSTALLED";
    assert_script_run 'scp -o StrictHostKeyChecking=no /etc/munge/munge.key root@172.16.0.23:/etc/munge/munge.key';
    barrier_wait "MUNGE_KEY_COPY";
    assert_script_run "systemctl enable munge.service";
    assert_script_run "systemctl start munge.service";
    barrier_wait "MUNGE_SERVICE_START";
    assert_script_run "munge -n";
    assert_script_run "munge -n | unmunge";
    assert_script_run "munge -n | ssh HostB unmunge";
    assert_script_run "remunge";
}

1;

# vim: set sw=4 et:

