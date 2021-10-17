#! /usr/bin/perl

use strict;
use warnings;

use Getopt::Std;
use LWP 5.64;


print STDOUT <<HEAD;
#################################
#                               #
#         perl-buster           #
#                               #
#################################
HEAD

# FUNCTIONS
sub get_help {
    print STDOUT <<HELP;
USAGE:
    perl perl-buster.pl [args]

EXAMPLE: 
    perl perl-buster.pl -u [BASE_URL] -w [WORDLIST]
    perl perl-buster.pl -u [BASE_URL] -w [WORDLIST] -t [TIME_BETWEEN_REQUESTS]
    perl perl-buster.pl -u [BASE_URL] -w [WORDLIST] -o [OUTPUT_FILE_PATH]
    perl perl-buster.pl -u [BASE_URL] -w [WORDLIST] -q

FLAGS: 
    -h,     help me find what this program does
    -u,     base URL
    -w,     path to the wordlist file
    -t,     time between requests, make process quieter
    -o,     relative path to output file
    -q,     quiet mode, no responses printed to console
    -p,     specify the port number to make requests to, default is 80
    -e,     use HTTPS instead of the default HTTP protocol
HELP

exit;
}

sub get_browser {
    return LWP::UserAgent->new || die $!;
}

sub read_wordlist {
    my ($filename) = @_;

    open my $fh, "<", $filename;
    return $fh;
}

sub get_response_code {
    my ($url, $browser) = @_;

    my $response = $browser->head($url);
    return $response->{_rc};
}

sub get_absolute_URL {
    my ($url_arg) = @_;

    if ( $url_arg !~ m/^http:\/\/|^https:\/\// ) {
        $url_arg = "http://".$url_arg;
    }
    return $url_arg;
}

sub write_to_file {
    my ($location, $info) = @_;

    open my $fh, ">>", $location || die $!;
    print $fh $info;
    close($fh);
}

sub set_port {
    my ($port, $url_string) = @_;

    die "A port should be an integer. e.g. -p 80 is default -p 443 is https, -p 8080 may be a test size or API." if $port !~ m/^\d+$/ or $port > 65535;
    return $url_string.":".$port;
}

sub set_https {
    my ($url_string) = @_;

    substr($url_string, 4, 0) = 's';
    return $url_string;
}


# OPTIONS
my %options = ();
getopts("hu:w:t:o:qp:e", \%options);

get_help() if defined $options{h};
my $url         = get_absolute_URL($options{u}) if defined $options{u} || die "Please use the -u flag to pass in a URL. Use -h for help.\n";
my $wordlist    = read_wordlist($options{w}) if defined $options{w} || die "Please use the -w flag and pass in a path to a wordlist. Use -h for help.\n";
my $sleeptime   = defined $options{t} ? $options{t} : 1;
my $output_loc  = $options{o} if defined $options{o};
my $quiet_mode  = $options{q} if defined $options{q};
$url            = set_port($options{p}, $url) if defined $options{p};
$url            = set_https($url) if defined $options{e};


# MAIN
my $browser     = get_browser();
my $startTime   = time;

while ( <$wordlist> ) {

    my $full_url = $url."/".$_;
    my $rc = get_response_code($full_url, $browser);

    if ( $rc =~ /^2/ ) {
        print STDOUT $rc, " -> ", $full_url if not defined $quiet_mode;
        write_to_file($output_loc, $full_url) if defined $output_loc;
    }

    sleep($sleeptime);
}

my $totalTime = time-$startTime;
print STDOUT <<END;
#################################
Time to execute: $totalTime(s)
#################################
END
