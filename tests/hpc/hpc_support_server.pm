# SUSE's openQA tests
#
# Copyright (c) 2016 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Start HA support server and check network connectivity
# Maintainer: Denis Zyuzin <dzyuzin@suse.com>

use base "basetest";
use strict;
use testapi;
use lockapi;
use mmapi;

sub check_for_service_status {
    my $cmd = shift;
    for (1 .. 7) {
        my $res = script_run $cmd;
        last if !$res;
        wait_idle(5);
    }
    #TODO find a proper way to die here if it was not successful
    
}


sub run() {    
    assert_screen "tty1-selected", 600;
    type_string "root\n";
    assert_screen "password-prompt";
    type_string "susetesting\n";

    # Check if eth0 has got an ipv4 address
    check_for_service_status("systemctl status wicked | grep 'eth0.*up'");
    
    # TODO find proper supportserver image
    # for now, change forwarders file 
    script_run("sed -i '/^forwarders.*/a     10.160.2.88;' /etc/named.d/forwarders.conf");
    script_run("cat /etc/named.d/forwarders.conf");
    script_run("systemctl restart named");
    check_for_service_status("systemctl status named | grep 'running'");

    type_string "ip a\n";
    type_string "ip route\n";
    type_string "if `ip a | grep -q '172.16.0.1/28'`; then echo ip1_okay > /dev/$serialdev; fi\n";
    wait_serial("ip1_okay") || die "support server doesn't have IP1";
    type_string "if `ip a | grep -q '172.16.0.17/28'`; then echo ip2_okay > /dev/$serialdev; fi\n";
    wait_serial("ip2_okay") || die "support server doesn't have IP2";
    type_string "if `dig \@localhost srv1.alpha.ha-test.qa.suse.de +short | grep -q 172.16.0.1`; then echo dns1_okay > /dev/$serialdev; fi\n";
    wait_serial("dns1_okay") || die "support server cannot resolve DNS1";
    type_string "if `dig \@localhost srv1.bravo.ha-test.qa.suse.de +short | grep -q 172.16.0.17`; then echo dns2_okay > /dev/$serialdev; fi\n";
    wait_serial("dns2_okay") || die "support server cannot resolve DNS2";
    type_string "exit\n";
    barrier_wait("NETWORK_READY");
    wait_for_children;    #don't destroy support server while children are running
}

sub test_flags() {
    return {fatal => 1};
}

1;
# vim: set sw=4 et:
