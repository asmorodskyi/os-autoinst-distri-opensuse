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
# Maintainer: asmorodskyi <asmorodskyi@suse.com>

use base "opensusebasetest";
use strict;
use warnings;
use testapi;
use utils;

sub run() {
  assert_script_run "zypper -n in munge libmunge2";
}

1;

# vim: set sw=4 et:

