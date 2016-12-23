# SUSE's openQA tests
#
# Copyright (c) 2016 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Initialize barriers used in HA cluster tests
# Maintainer: Denis Zyuzin <dzyuzin@suse.com>

use base "hacluster";
use strict;
use testapi;
use lockapi;
use mmapi;

sub run() {

    barrier_create("SLURMCTLD_STARTED", 2);
    barrier_create("SLURMD_STARTED",    2);
    barrier_create("NODES_STARTED",     3);
    barrier_create("NETWORK_READY",     3);
    wait_for_children_to_start;
    barrier_wait("NODES_STARTED");
}

sub test_flags {
    return {fatal => 1};
}

1;
