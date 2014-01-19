use strict;
use warnings;
use Test::More;

use App::Crawler::GooglePlay;


subtest "get_ranking" => sub{
    my $crawler = App::Crawler::GooglePlay->new();
    my $result = $crawler->get_ranking(category=>{name=>"topselling_paid"},genre=>{name=>"GAME"},offset=>0,limit=>10);
    is(scalar @$result,10);
    $result = $crawler->get_ranking(category=>{name=>"topselling_paid"},genre=>{name=>"GAME"},offset=>0,limit=>1);
    is(scalar @$result,1);
};


done_testing;
