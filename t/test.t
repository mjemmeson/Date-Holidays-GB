# test.t

use Test::Most;

use Date::Holidays::GB;

ok !is_gb_holiday( 2013, 1, 3 ), "2013-01-03 is not a holiday";

ok my $christmas = is_gb_holiday( 2013, 12, 25 ), "2013-12-25 is a holiday";
is $christmas, "Christmas Day", "Christmas Day name ok (all)";

ok !is_gb_holiday( 2013, 11, 30, ['EAW'] ),
    "2013-12-02 is not a holiday in England & Wales";
ok my $st_andrews_day = is_gb_holiday( 2013, 12, 02, ['SCT'] ),
    "2013-12-02 is a holiday in Scotland";
is $st_andrews_day, "St Andrew\x{2019}s Day (Scotland)", "St Andrew's Day name ok";

done_testing();

