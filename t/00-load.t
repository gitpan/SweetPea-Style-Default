#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'SweetPea::Style::Default' );
}

diag( "Testing SweetPea::Style::Default $SweetPea::Style::Default::VERSION, Perl $], $^X" );
