package Date::Holidays::GB::NIR;

our $VERSION = '0.006';

=head1 NAME

Date::Holidays::GB::NIR - Date::Holidays class for GB-NIR (Northern Ireland)

=head1 SYNOPSIS

    use Date::Holidays::GB::NIR qw/ holidays is_holiday /;

    # All holidays for Northern Ireland
    my $holidays = holidays( year => 2013 );

    if (is_holiday( year => 2013, month => 12, day => 25, ) {
            print "No work today!";
        }

=cut

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

