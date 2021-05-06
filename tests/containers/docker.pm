# SUSE's openQA tests
#
# Copyright © 2009-2013 Bernhard M. Wiedemann
# Copyright © 2012-2021 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Package: docker
# Summary: Test docker installation and extended usage
# - docker package can be installed
# - firewall is configured correctly
# - docker daemon can be started
# - images can be searched on the Docker Hub
# - images can be pulled from the Docker Hub
# - local images can be listed (with and without tag)
# - containers can be run and created
# - containers state can be saved to an image
# - network is working inside of the containers
# - containers can be stopped
# - containers can be deleted
# - images can be deleted
# - build a docker image
# - attach a volume
# - expose a port
# - test networking outside of host
# Maintainer: qa-c team <qa-c@suse.de>

use base "consoletest";
use testapi;
use utils;
use strict;
use warnings;
use containers::common;
use version_utils qw(is_sle is_leap get_os_release);
use containers::utils;
use containers::container_images;

sub run {
    my ($self) = @_;
    $self->select_serial_terminal;

    my $sleep_time = 90 * get_var('TIMEOUT_SCALE', 1);
    my $dir        = "/root/DockerTest";

    my ($running_version, $sp, $host_distri) = get_os_release;

    install_docker_when_needed($host_distri);
    test_seccomp();
    allow_selected_insecure_registries(runtime => 'docker');

    check_docker_firewall() if ($self->firewall() eq 'firewalld');
    #check_version(">=20.10", get_docker_version(), qr/\d{2}(?:\.\d+)/)
    # Run basic docker tests
    basic_container_tests(runtime => "docker");

    # Build an image from Dockerfile and test it
    test_containered_app(runtime => 'docker', dockerfile => 'Dockerfile.python3');

    # Clean container
    clean_container_host(runtime => "docker");
}

1;
