# SUSE's openQA tests
#
# Copyright © 2009-2013 Bernhard M. Wiedemann
# Copyright © 2012-2016 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: yast2_nfs_client module
#   Ensures that it works with the current version of nfs-client (it got broken
#   with the conversion from init.d to systemd services)
# Maintainer: Oliver Kurz <okurz@suse.de>

use base "y2_module_consoletest";

use strict;
use warnings;
use testapi;
use lockapi;
use utils qw(clear_console zypper_call systemctl);
use mm_network;
use nfs_common;

sub run {
    #
    # Preparation
    #
    select_console 'root-console';
    if (get_var('NFSCLIENT')) {
        # Configure static IP for client/server test
        configure_default_gateway;
        configure_static_ip('10.0.2.102/24');
        configure_static_dns(get_host_resolv_conf());

        zypper_call('in yast2-nfs-client nfs-client', timeout => 480, exitcode => [0, 106, 107]);

        mutex_wait('nfs_ready');
        assert_script_run 'ping -c3 10.0.2.101';
        assert_script_run "showmount -e 10.0.2.101";
    }
    else {
        # Make sure packages are installed
        zypper_call('in yast2-nfs-client nfs-client nfs-kernel-server', timeout => 480, exitcode => [0, 106, 107]);
        # Prepare the test file structure
        assert_script_run 'mkdir -p /tmp/nfs/server';
        assert_script_run 'echo "success" > /tmp/nfs/server/file.txt';
        # Serve the share
        assert_script_run 'echo "/tmp/nfs/server *(ro)" >> /etc/exports';
        systemctl 'start nfs-server';
        assert_script_run "showmount -e localhost";
    }
    # add comments into fstab and save current fstab bsc#429326
    assert_script_run 'sed -i \'5i# test comment\' /etc/fstab';
    assert_script_run 'cat /etc/fstab > fstab_before';

    #
    # YaST nfs-client execution
    #

    my $module_name = y2_module_consoletest::yast2_console_exec(yast2_module => 'nfs-client');

    assert_screen 'yast2-nfs-client-shares';
    send_key 'alt-a';
    assert_screen 'yast2-nfs-client-add';
    type_string get_var('NFSCLIENT') ? '10.0.2.101' : 'localhost';
    # Explore the available shares and select the only available one
    send_key 'alt-e';
    check_screen('yast2-nfs-client-exported', 15);
    if (not match_has_tag('yast2-nfs-client-exported')) {
        send_key 'down';
        assert_screen 'yast2-nfs-client-exported';
    }
    send_key 'alt-o';
    # Set the local mount point
    send_key 'alt-m';
    type_string '/tmp/nfs/client';
    sleep 1;
    save_screenshot;
    # Save the new connection and close YaST
    wait_screen_change { send_key 'alt-o' };
    sleep 1;
    save_screenshot;
    # Exit YaST
    wait_screen_change { send_key 'alt-o' };

    wait_serial("$module_name-0") or die "'yast2 $module_name' didn't finish";
    clear_console;

    #
    # Check the result
    #

    mount_export();

    # Check NFS version
    assert_script_run "nfsstat -m | grep vers=3";

    client_common_tests();

    # Test NFSv3 POSIX permissions
    assert_script_run "ls -la /tmp/nfs/client/secret.txt | grep '\\-rwxr\\-\\-\\-\\-\\-'";
    assert_script_run "! sudo -u $testapi::username cat /tmp/nfs/client/secret.txt";

    # Test NFSv3 ro export
    assert_script_run "mkdir /tmp/nfs/ro";
    assert_script_run "mount 10.0.2.101:/srv/ro /tmp/nfs/ro";
    assert_script_run "ls /tmp/nfs/ro";
    assert_script_run "grep success /tmp/nfs/ro/file.txt";
    assert_script_run "! echo modified > /tmp/nfs/ro/file.txt";
    assert_script_run "! grep modified /tmp/nfs/ro/file.txt";

    # Safely umount NFS share
    assert_script_run 'umount /tmp/nfs/ro';
    assert_script_run 'umount /tmp/nfs/client';

}

1;

