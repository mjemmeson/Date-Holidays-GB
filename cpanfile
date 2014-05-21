requires "Date::Holidays::Super" => "0";
requires "Exporter" => "0";
requires "base" => "0";
requires "constant" => "0";
requires "perl" => "5.008";
requires "strict" => "0";
requires "utf8" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec::Functions" => "0";
  requires "List::Util" => "0";
  requires "Test::Fatal" => "0";
  requires "Test::More" => "0";
  requires "Test::Most" => "0";
  requires "version" => "0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "0";
  recommends "CPAN::Meta::Requirements" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "6.17";
  requires "File::ShareDir::Install" => "0.03";
};

on 'develop' => sub {
  requires "Dist::Milla" => "0";
  requires "File::Spec" => "0";
  requires "File::Temp" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::CPAN::Meta" => "0";
  requires "Test::More" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
};

on 'develop' => sub {
  recommends "Cwd" => "0";
  recommends "DateTime" => "0";
  recommends "File::Spec::Functions" => "0";
  recommends "LWP::Simple" => "0";
  recommends "Template" => "0";
  recommends "Time::Local" => "0";
  recommends "iCal::Parser" => "0";
};
