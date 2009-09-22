use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'SweetPea::Style::Default',
    AUTHOR              => q{Al Newkirk <al.newkirk@awnstudio.com>},
    VERSION_FROM        => 'lib/SweetPea/Style/Default.pm',
    ABSTRACT_FROM       => 'lib/SweetPea/Style/Default.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Data::FormValidator' => 0,
        'DBIx::Class' => 0,
        'DBIx::Class::Schema::Loader' => 0,
        'Email::Stuff' => 0,
        'Template' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'SweetPea-Style-Default-*' },
);
