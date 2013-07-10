# test.t

use utf8;
use Test::Most;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

use Date::Holidays::GB qw/ is_holiday holidays /;

# TODO load holiday data from sample files, so tests won't need updating

note "is_holiday";

ok !is_holiday( 2013, 1, 3 ), "2013-01-03 is not a holiday";

ok my $christmas = is_holiday( 2013, 12, 25 ), "2013-12-25 is a holiday";
is $christmas, "Christmas Day", "Christmas Day name ok (all)";

ok !is_holiday( 2013, 12, 25, [] ), "2013-12-25 is not a holiday if empty region list";

ok !is_holiday( 2013, 11, 30, ['EAW'] ),
    "2013-12-02 is not a holiday in England & Wales";
ok my $st_andrews_day = is_holiday( 2013, 12, 02, ['SCT'] ),
    "2013-12-02 is a holiday in Scotland";
is $st_andrews_day, "St Andrew\x{2019}s Day (Scotland)", "St Andrew's Day name ok";

note "holidays";

is_deeply holidays(2000), {}, "No holiday data for year 2000";

ok my $holidays = holidays(2013), "got holidays for 2013";

use Data::Dumper::Concise;
print Dumper($holidays);

is_deeply $holidays, {}, "2013 holidays ok";


done_testing();

