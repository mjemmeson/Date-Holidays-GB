#!/usr/bin/perl

# script to update Date::Holidays::GB with the latest bank holiday dates from
# http://www.gov.uk/bank-holidays

use strict;
use warnings;

use Cwd qw( realpath );
use DateTime;
use File::Spec::Functions qw( catfile splitpath updir );
use JSON;
use LWP::Simple qw/ get /;
use Template;
use Time::Local();

my $URL = 'http://www.gov.uk/bank-holidays.json';

my %CODE = (
    'england-and-wales' => 'EAW',
    'scotland'          => 'SCT',
    'northern-ireland'  => 'NIR',
);

write_file( get_dates( download_json() ) );

exit;

sub download_json {

    my $contents = get $URL or die "Can't download $URL";

    return decode_json($contents);
}

sub get_dates {

    my $data = shift;

    my %holiday;

    foreach my $region ( keys %{$data} ) {

        foreach my $event ( @{ $data->{$region}->{events} } ) {

            $holiday{ $event->{date} }->{ $CODE{$region} } = $event->{title};

        }
    }

    return %holiday;
}

sub write_file {
    my %holiday = @_;

    my $file = catfile( ( splitpath( realpath __FILE__ ) )[ 0, 1 ],
        updir, qw(lib Date Holidays GB.pm) );

    open my $FH, '>:encoding(utf-8)', $file or die "$file: $!";

    my $contents = do { local $/; <DATA> };

    my $tt2 = Template->new;
    my $output;
    $tt2->process( \$contents, { date_generated => DateTime->now->ymd }, \$output );

    print $FH $output;

    print $FH holiday_data( %holiday );

    close $FH;
}

sub holiday_data {
    my %holiday = @_;

    my $data;
    foreach my $date ( sort keys %holiday ) {
        foreach my $code ( sort keys %{ $holiday{$date} } ) {
            $data .= sprintf( "%s\t%s\t%s\n",
                $date, $code, $holiday{$date}->{$code} );
        }
    }

    return "__DATA__\n$data";
}


1;

__DATA__
package Date::Holidays::GB;

# VERSION

# ABSTRACT: Determine British holidays - UK public and bank holiday dates

use strict;
use warnings;
use utf8;

use base qw( Date::Holidays::Super Exporter );
our @EXPORT_OK = qw(
  holidays
  gb_holidays
  holidays_ymd
  is_holiday
  is_gb_holiday
);

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
set_holidays(\*DATA);

sub set_holidays {
    my $fh = shift;
    while (<$fh>) {
        chomp;
        my ( $date, $region, $name ) = split /\t/;
        next unless $date && $region && $name;

        my ( $y, $m, $d ) = split /-/, $date;
        $holidays{$y}->{$date}->{$region} = $name;
    }

    # Define an 'all' if all three regions have a holiday on this day, taking
    # EAW name as the canonical name
    while ( my ( $year, $dates ) = each %holidays ) {
        foreach my $holiday ( values %{$dates} ) {
            $holiday->{all} = $holiday->{EAW}
                if keys %{$holiday} == @{ +REGIONS };
        }
    }
}

sub gb_holidays { return holidays(@_) }

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

        if ( $args{ymd} ) {
            $return{$date} = $string;
        } else {
            my ( undef, $m, undef, $d ) = unpack( 'A5A2A1A2', $date );
            $return{ $m . $d } = $string;
        }
    }

    return \%return;
}

sub holidays_ymd {
    my %args
        = $_[0] =~ m/\D/
        ? @_
        : ( year => $_[0], regions => $_[1] );

    return holidays( %args, ymd => 1 );
}

sub is_gb_holiday { return is_holiday(@_) }

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
    my $holiday = $holidays{$y}->{ sprintf( "%04d-%02d-%02d", $y, $m, $d ) }
        or return;

    return _holiday( $holiday, \@region_codes );
}

sub next_holiday {
    my @regions = (shift) || @{+REGIONS};

    my ( $d, $m, $year ) = ( localtime() )[ 3 .. 5 ];
    my $today = sprintf( "%04d-%02d-%02d", $year + 1900, $m + 1, $d );

    my %next_holidays;

    foreach my $date ( sort keys %{ $holidays{$year} } ) {

        next unless $date gt $today;

        my $holiday = $holidays{$year}->{$date};

        foreach my $region ( 'all', @regions ) {
            my $name = $holiday->{$region} or next;

            $next_holidays{$region} ||= $name;
        }

        last if $next_holidays{all} or keys %next_holidays == @{ +REGIONS };
    }

    return \%next_holidays;
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

