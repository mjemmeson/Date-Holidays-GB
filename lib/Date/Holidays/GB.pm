use strict;
use warnings;

package Date::Holidays::GB;

# VERSION

use iCal::Parser;
use Time::Local();

use base qw( Exporter );
our @EXPORT = qw( gb_holidays is_gb_holiday );

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
foreach my $region ( keys %CODES ) {
    open( my $FH, "<:encoding(UTF-8)", "$region.ics" )
        or die "Can't open '$region.ics' : $!";
    my $contents = do { local $/ = <$FH> };
    my $code = $CODES{$region};
    $contents =~ s/(BEGIN:VCALENDAR)/$1\nX-WR-CALNAME:$code/;
    $FILES{$region} = $contents;
}

use Data::Dumper::Concise;

my $cal = iCal::Parser->new->parse_strings( values %FILES );

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

sub gb_holidays {
    my %args = @_;

    unless (exists $args{year} && defined $args{year}) {
        $args{year} = (localtime(time))[5];
        $args{year} += 1900;
    }

    unless ($args{year} =~ /^\d{4}$/) {
        die "Year must be numeric and four digits, eg '2004'";
    }

 

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

