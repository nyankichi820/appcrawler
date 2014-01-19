use strict;
use warnings;
use Test::More;

use App::Crawler::AppStore;


subtest "get_ranking" => sub{
    my $crawler = App::Crawler::AppStore->new();
    my $result = $crawler->get_ranking(category=>{name=>"topfreeapplications"},genre=>{name=>"6018"},limit=>10);
    is(scalar @$result,10);
    $result = $crawler->get_ranking(category=>{name=>"topfreeapplications"},genre=>{name=>"6018"},limit=>1);
    is(scalar @$result,1);
};


done_testing;
