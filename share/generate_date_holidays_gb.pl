#!/usr/bin/perl

# script to update Date::Holidays::GB with the latest bank holiday dates from
# http://www.gov.uk/bank-holidays

use strict;
use warnings;

use Cwd qw( realpath );
use DateTime;
use File::Spec::Functions qw( catfile splitpath updir );
use iCal::Parser;
use LWP::Simple qw/ get /;
use Template;
use Time::Local();

my $URL = 'http://www.gov.uk/bank-holidays/';

my %CODES = (
    'england-and-wales' => 'EAW',
    'scotland'          => 'SCT',
    'northern-ireland'  => 'NIR',
);

write_file( get_dates( download_cals() ) );

exit;

sub download_cals {
    my %cals;
    while ( my ( $region, $code ) = each %CODES ) {

        my $contents = get $URL . "$region.ics"
            or die "Can't download $URL$region.ics";

        $contents =~ s/(BEGIN:VCALENDAR)/$1\nX-WR-CALNAME:$code/;

        $cals{$region} = $contents;
    }

    return %cals;
}

sub read_files {
    my %files;    # file contents
    while ( my ( $region, $code ) = each %CODES ) {
        open( my $FH, "<:encoding(UTF-8)", "t/samples/$region.ics" )
            or die "Can't open '$region.ics' : $!";
        my $contents = do { local $/; <$FH> };
        $contents =~ s/(BEGIN:VCALENDAR)/$1\nX-WR-CALNAME:$code/;
        $files{$region} = $contents;
    }
    return %files;
}

use Data::Dumper::Concise;

sub get_dates {

    my $cal = iCal::Parser->new->parse_strings( values @_ );

    my %icals = map { $_->{'X-WR-RELCALID'} => $_ } @{ $cal->{cals} };

    my %holidays;

    while ( my ( $y, $caly ) = each %{ $cal->{events} } ) {
        while ( my ( $m, $calm ) = each %{$caly} ) {
            while ( my ( $d, $cald ) = each %{$calm} ) {

                my $date = sprintf( "%d-%02d-%02d", $y, $m, $d );

                foreach my $e ( values( %{$cald} ) ) {

                    $holidays{$date}
                        ->{ $icals{ $e->{idref} }->{'X-WR-CALNAME'} }
                        = $e->{SUMMARY};
                }
            }
        }
    }

    return %holidays;
}

sub write_file {
    my %holidays = @_;

    my $file = catfile( ( splitpath( realpath __FILE__ ) )[ 0, 1 ],
        updir, qw(lib Date Holidays GB.pm) );

    open my $FH, '>:encoding(utf-8)', $file or die "$file: $!";

    my $contents = do { local $/; <DATA> };

    my $tt2 = Template->new;
    my $output;
    $tt2->process( \$contents, { date_generated => DateTime->now->ymd }, \$output );

    print $FH $output;

    print $FH holiday_data( %holidays );

    close $FH;
}

sub holiday_data {
    my %holidays = @_;

    my $data;
    foreach my $date ( sort keys %holidays ) {
        foreach my $region ( sort keys %{ $holidays{$date} } ) {
            $data .= sprintf( "%s\t%s\t%s\n",
                $date, $region, $holidays{$date}->{$region} );
        }
    }

    return "__DATA__\n$data";
}


1;

__DATA__
package Date::Holidays::GB;

# VERSION

# ABSTRACT: Date::Holidays compatible package for the UK, with public/bank holiday dates, updated from gov.uk

use strict;
use warnings;
use utf8;

use base qw( Date::Holidays::Super Exporter );
our @EXPORT_OK = qw( holidays is_holiday );

# See
# http://en.wikipedia.org/wiki/ISO_3166-2
# http://en.wikipedia.org/wiki/ISO_3166-2:GB

use constant REGION_NAMES => {
    EAW => 'England & Wales',
    SCT => 'Scotland',
    NIR => 'Northern Ireland',
};
use constant REGIONS => [ sort keys %{ +REGION_NAMES } ];

our %holidays;

while (<DATA>) {
    chomp;
    my ( $date, $region, $name ) = split /\t/;

    my ( $y, $m, $d ) = split /-/, $date;
    $holidays{$y}->{ $m . $d }->{$region} = $name;
}

# Define an 'all' if all three regions have a holiday on this day, taking
# EAW name as the canonical name
while ( my ( $year, $dates ) = each %holidays ) {
    foreach my $holiday ( values %{$dates} ) {
        $holiday->{all} = $holiday->{EAW}
            if keys %{$holiday} == @{ +REGIONS };
    }
}

sub holidays {
    my %args
        = $_[0] =~ m/\D/
        ? @_
        : ( year => $_[0], regions => $_[1] );

    unless ( exists $args{year} && defined $args{year} ) {
        $args{year} = ( localtime(time) )[5];
        $args{year} += 1900;
    }

    unless ( $args{year} =~ /^\d{4}$/ ) {
        die "Year must be numeric and four digits, eg '2004'";
    }

    # return if empty regions list (undef gets full list)
    my @region_codes = @{ $args{regions} || REGIONS }
        or return {};

    my %return;

    while ( my ( $date, $holiday ) = each %{ $holidays{ $args{year} } } ) {
        my $string = _holiday( $holiday, \@region_codes )
            or next;
        $return{$date} = $string;
    }

    return \%return;
}

sub is_holiday {
    my %args
        = $_[0] =~ m/\D/
        ? @_
        : ( year => $_[0], month => $_[1], day => $_[2], regions => $_[3] );

    my ( $y, $m, $d ) = @args{qw/ year month day /};
    die "Must specify year, month and day" unless $y && $m && $d;

    # return if empty regions list (undef gets full list)
    my @region_codes = @{ $args{regions} || REGIONS }
        or return;

    # return if no region has holiday
    my $holiday = $holidays{$y}->{ sprintf( "%02d%02d", $m, $d ) }
        or return;

    return _holiday( $holiday, \@region_codes );
}

sub _holiday {
    my ( $holiday, $region_codes ) = @_;

    # return canonical name (EAW) if all regions have holiday
    return $holiday->{all} if $holiday->{all};

    my %region_codes = map { $_ => 1 } @{$region_codes};

    # return comma separated string of holidays with region(s) in
    # parentheses
    my %names;
    foreach my $region ( sort keys %region_codes ) {
        next unless $holiday->{$region};

        push @{ $names{ $holiday->{$region} } }, REGION_NAMES->{$region};
    }

    return unless %names;

    my @strings;
    foreach my $name ( sort keys %names ) {
        push @strings, "$name (" . join( ', ', @{ $names{$name} } ) . ")";
    }

    return join( ', ', @strings );
}

sub date_generated { '[% date_generated %]' }

1;

