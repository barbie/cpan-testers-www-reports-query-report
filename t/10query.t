#!/usr/bin/perl -w
use strict;

use lib qw(./lib);
use Test::More tests => 21;

use CPAN::Testers::Report;
use CPAN::Testers::WWW::Reports::Query::Report;
use JSON::XS;
use Data::Dumper;

# various argument sets for examples

my @args = (
    { 
        spec    => { as_hash => 1, as_json => 1 },
        args    => { report  => 40000000, as_json => 0, as_hash => 0 },
        results => { guid => '5fa5ec4e-9f27-11e3-9b58-10cf2a990ce1' },
        fact    => 1
    },
    { 
        spec    => { host => 'http://cpantesters.org' },
        args    => { report  => '1cbc9d0c-b60a-11e3-9e09-941504fe8cc2' },
        results => { guid => '1cbc9d0c-b60a-11e3-9e09-941504fe8cc2' },
        fact    => 1
    },
    { 
        spec    => {},
        args    => { report  => 40000000, as_hash => 1 },
        results => { guid => '5fa5ec4e-9f27-11e3-9b58-10cf2a990ce1' },
        hash    => 1
    },
    { 
        spec    => { as_hash => 1 },
        args    => { report  => 'b599a190-b601-11e3-add5-ed1d4a243164' },
        results => { guid => 'b599a190-b601-11e3-add5-ed1d4a243164' },
        hash    => 1
    },
    { 
        spec    => {},
        args    => { report  => 40853050, as_json => 1 },
        results => { guid => '1cbc9d0c-b60a-11e3-9e09-941504fe8cc2' },
        json    => 1
    },
    { 
        spec    => { as_json => 1 },
        args    => { report  => 40853050 },
        results => { guid => '1cbc9d0c-b60a-11e3-9e09-941504fe8cc2' },
        json    => 1
    },
    { 
        spec    => { as_hash => 1 },
        args    => { report  => '5f7b56be-9f27-11e3-9385-a7e693cf7503', as_json => 1, as_hash => 0 },
        results => { guid => '5f7b56be-9f27-11e3-9385-a7e693cf7503' },
        json    => 1
    },
);

SKIP: {
    skip "Network unavailable", 21 if(pingtest());

    for my $args (@args) {
        my $spec = $args->{spec};

        my $query = CPAN::Testers::WWW::Reports::Query::Report->new( %$spec );
        isa_ok($query,'CPAN::Testers::WWW::Reports::Query::Report');

        my $data = $query->report( %{$args->{args}} );
        if($data && $args->{json}) {
            $data = decode_json($data);
            #diag("JSON data=".Dumper($data));
            is($data->{metadata}{core}{$_},$args->{results}{$_},".. got '$_' in JSON [$args->{args}{report}]") for(keys %{$args->{results}});
        } elsif($data && $args->{hash}) {
            #diag("hash data=".Dumper($data->{metadata}));
            is($data->{metadata}{core}{$_},$args->{results}{$_},".. got '$_' in hash [$args->{args}{report}]") for(keys %{$args->{results}});
        } elsif($data && $args->{fact}) {
            my $fact = $data->as_struct;
            #diag("fact data=".Dumper($fact));
            is($fact->{metadata}{core}{$_},$args->{results}{$_},".. got '$_' in fact [$args->{args}{report}]") for(keys %{$args->{results}});
        } else {
            diag("error args=".Dumper($args));
            diag("error data=".Dumper($data));
            ok(0,'missing results for test');
        }

        is($query->error,'','.. no errors');
    }
}

# crude, but it'll hopefully do ;)
sub pingtest {
    my $domain = 'www.cpantesters.org';
    my $cmd =   $^O =~ /solaris/i                           ? "ping -s $domain 56 1" :
                $^O =~ /dos|os2|mswin32|netware|cygwin/i    ? "ping -n 1 $domain "
                                                            : "ping -c 1 $domain >/dev/null 2>&1";

    system($cmd);
    my $retcode = $? >> 8;
    # ping returns 1 if unable to connect
    return $retcode;
}
