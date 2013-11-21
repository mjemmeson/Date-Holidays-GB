package Date::Holidays::GB;

# VERSION

# ABSTRACT: Date::Holidays compatible package for the UK, with public/bank holiday dates, updated from gov.uk

use strict;
use warnings;
use utf8;

use base qw( Date::Holidays::Super Exporter );
our @EXPORT_OK = qw( holidays gb_holidays is_holiday is_gb_holiday );

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
        $return{$date} = $string;
    }

    return \%return;
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

sub date_generated { '2013-11-21' }

1;

__DATA__
2013-01-01	EAW	New Year’s Day
2013-01-01	NIR	New Year’s Day
2013-01-01	SCT	New Year’s Day
2013-01-02	SCT	2nd January
2013-03-18	NIR	St Patrick’s Day
2013-03-29	EAW	Good Friday
2013-03-29	NIR	Good Friday
2013-03-29	SCT	Good Friday
2013-04-01	EAW	Easter Monday
2013-04-01	NIR	Easter Monday
2013-05-06	EAW	Early May bank holiday
2013-05-06	NIR	Early May bank holiday
2013-05-06	SCT	Early May bank holiday
2013-05-27	EAW	Spring bank holiday
2013-05-27	NIR	Spring bank holiday
2013-05-27	SCT	Spring bank holiday
2013-07-12	NIR	Battle of the Boyne (Orangemen’s Day)
2013-08-05	SCT	Summer bank holiday
2013-08-26	EAW	Summer bank holiday
2013-08-26	NIR	Summer bank holiday
2013-12-02	SCT	St Andrew’s Day
2013-12-25	EAW	Christmas Day
2013-12-25	NIR	Christmas Day
2013-12-25	SCT	Christmas Day
2013-12-26	EAW	Boxing Day
2013-12-26	NIR	Boxing Day
2013-12-26	SCT	Boxing Day
2014-01-01	EAW	New Year’s Day
2014-01-01	NIR	New Year’s Day
2014-01-01	SCT	New Year’s Day
2014-01-02	SCT	2nd January
2014-03-17	NIR	St Patrick’s Day
2014-04-18	EAW	Good Friday
2014-04-18	NIR	Good Friday
2014-04-18	SCT	Good Friday
2014-04-21	EAW	Easter Monday
2014-04-21	NIR	Easter Monday
2014-05-05	EAW	Early May bank holiday
2014-05-05	NIR	Early May bank holiday
2014-05-05	SCT	Early May bank holiday
2014-05-26	EAW	Spring bank holiday
2014-05-26	NIR	Spring bank holiday
2014-05-26	SCT	Spring bank holiday
2014-07-14	NIR	Battle of the Boyne (Orangemen’s Day)
2014-08-04	SCT	Summer bank holiday
2014-08-25	EAW	Summer bank holiday
2014-08-25	NIR	Summer bank holiday
2014-12-01	SCT	St Andrew’s Day
2014-12-25	EAW	Christmas Day
2014-12-25	NIR	Christmas Day
2014-12-25	SCT	Christmas Day
2014-12-26	EAW	Boxing Day
2014-12-26	NIR	Boxing Day
2014-12-26	SCT	Boxing Day
2015-01-01	EAW	New Year’s Day
2015-01-01	NIR	New Year’s Day
2015-01-01	SCT	New Year’s Day
2015-01-02	SCT	2nd January
2015-03-17	NIR	St Patrick’s Day
2015-04-03	EAW	Good Friday
2015-04-03	NIR	Good Friday
2015-04-03	SCT	Good Friday
2015-04-06	EAW	Easter Monday
2015-04-06	NIR	Easter Monday
2015-05-04	EAW	Early May bank holiday
2015-05-04	NIR	Early May bank holiday
2015-05-04	SCT	Early May bank holiday
2015-05-25	EAW	Spring bank holiday
2015-05-25	NIR	Spring bank holiday
2015-05-25	SCT	Spring bank holiday
2015-07-13	NIR	Battle of the Boyne (Orangemen’s Day)
2015-08-03	SCT	Summer bank holiday
2015-08-31	EAW	Summer bank holiday
2015-08-31	NIR	Summer bank holiday
2015-11-30	SCT	St Andrew’s Day
2015-12-25	EAW	Christmas Day
2015-12-25	NIR	Christmas Day
2015-12-25	SCT	Christmas Day
2015-12-28	EAW	Boxing Day
2015-12-28	NIR	Boxing Day
2015-12-28	SCT	Boxing Day
