package Date::Holidays::GB::NIR;

# VERSION

# ABSTRACT: Date::Holidays class for GB-EAW (England & Wales)

use strict;
use warnings;

use Date::Holidays::GB;

sub holidays {
    my %args
        = $_[0] =~ m/\D/
        ? @_
        : ( year => $_[0] );

    return Date::Holidays::GB::holidays( %args, regions => [ 'NIR' ] );
}

sub is_holiday {
    my %args
        = $_[0] =~ m/\D/
        ? @_
        : ( year => $_[0], month => $_[1], day => $_[2] );

    return Date::Holidays::GB::is_holiday( %args, regions => [ 'NIR' ] );
}

1;

