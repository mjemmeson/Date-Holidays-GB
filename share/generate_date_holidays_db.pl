#!/usr/bin/perl

use strict;
use warnings;

use Cwd qw( realpath );
use File::Spec::Functions qw( catfile splitpath updir );
use iCal::Parser;
use Time::Local();

# http://en.wikipedia.org/wiki/ISO_3166-2
# http://en.wikipedia.org/wiki/ISO_3166-2:GB

my %CODES = (
    'england-and-wales' => 'EAW',
    'scotland'          => 'SCT',
    'northern-ireland'  => 'NIR',
);

my %REGIONS = (
    EAW => 'England & Wales',
    SCT => 'Scotland',
    NIR => 'Northern Ireland',
);

my %FILES;

my %holidays;

write_file( get_dates( read_files() ) );

exit;

sub read_files {
    my %files;
    foreach my $region ( keys %CODES ) {
        open( my $FH, "<:encoding(UTF-8)", "$region.ics" )
            or die "Can't open '$region.ics' : $!";
        my $contents = do { local $/ = <$FH> };
        my $code = $CODES{$region};
        $contents =~ s/(BEGIN:VCALENDAR)/$1\nX-WR-CALNAME:$code/;
        $files{$region} = $contents;
    }
    return %files;
}

use Data::Dumper::Concise;

sub get_dates {

    my $cal = iCal::Parser->new->parse_strings( values @_ );

    #my $cal = iCal::Parser->new->parse( map {"$_.ics"} keys %CODES );

    my %icals = map { $_->{'X-WR-RELCALID'} => $_ } @{ $cal->{cals} };

    my %holidays;

    while ( my ( $y, $caly ) = each %{ $cal->{events} } ) {
        while ( my ( $m, $calm ) = each %{$caly} ) {
            while ( my ( $d, $cald ) = each %{$calm} ) {
                foreach my $e ( values( %{$cald} ) ) {
                    $holidays{"$y-$m-$d"}
                        ->{ $icals{ $e->{idref} }->{'X-WR-CALNAME'} }
                        = $e->{SUMMARY};
                }
            }
        }
    }

    # define an 'all' if all three regions have a holiday on this day
    foreach my $holiday ( values %holidays ) {

        # Take EAW as canonical name
        $holiday->{all} = $holiday->{EAW} if keys %{$holiday} == 3;
    }

    return %holidays;
}

sub write_file {
    my %holidays = @_;

    my $file = catfile( ( splitpath( realpath __FILE__ ) )[ 0, 1 ],
        updir, qw(lib Date Holidays GB.pm) );

    open my $fh, '>:encoding(utf-8)', $file or die "$file: $!";

    my $contents = join('\n',<DATA>);

    ( my $header = << "    __HEADER__") =~ s/^ +//gm;
        package Acme::CPANAuthors::Locations;

        use strict;
        use warnings;
        use utf8;

        our $VERSION = '$VERSION';

        use Acme::CPANAuthors::Register(
    __HEADER__
    print $fh $header;
    for my $cpanid ( sort keys %authors ) {
        printf $fh "    q(%s) => q(%s),\n", $cpanid, $authors{$cpanid};
    }
    print $fh <DATA>;
    close $fh;
}


1;

__DATA__
package Date::Holidays::GB;

use strict;
use warnings;
use utf8;

use base qw( Exporter );
our @EXPORT = qw( gb_holidays is_gb_holiday );

our %holidays;

sub gb_holidays {
    my %args = @_;

    unless ( exists $args{year} && defined $args{year} ) {
        $args{year} = ( localtime(time) )[5];
        $args{year} += 1900;
    }

    unless ( $args{year} =~ /^\d{4}$/ ) {
        die "Year must be numeric and four digits, eg '2004'";
    }

    # TODO
}

sub is_gb_holiday {
    my %args = @_;

    my ( $y, $m, $d ) = @args{qw/ year month day /};
    die "Must specify year, month and day" unless $y && $m && $d;

    # return if empty regions list
    my @codes = @{ $args{regions} || [qw/ EAW SCT NIR /] } or return;

    # return if no region has holiday
    my $holiday = $holidays{"$y-$m-$d"} or return;

    # return canonical name (EAW) if all regions have holiday
    return $holiday->{all} if $holiday->{all};

    # return comma separated string of holidays with region in
    # parentheses
    my @result;
    foreach my $code (@codes) {
        push @result, $holiday->{$code} . " ($REGIONS{$code})";
    }
    return join( ', ', @result ) || undef;
}

1;

