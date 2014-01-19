appcrawler
==========

appstore and google play ranking and review crawler


AppStore
==========

    my $crawler = App::Crawler::AppStore->new();
    
    # get ranking
    my $result = $crawler->get_ranking(category=>{name=>"topfreeapplications"},genre=>{name=>"6018"},limit=>10);
    
    # get review
    my $result = $crawler->get_review(app_id=>"xxxxxxx",page=>10);

    # get app info
    my $result = $crawler->get_app(app_id=>"xxxxxxx");

    # search app
    my $result = $crawler->get_search_app(query=>"xxxxxxx");

    # get suggest keyword
    my $result = $crawler->get_suggest_app(query=>"xxxxxxx");

    # content fetch only
    my $html = $crawler->fetch_ranking(category=>{name=>"topfreeapplications"},genre=>{name=>"6018"},limit=>10);

    # parse html
    my $result = $crawler->parse_ranking(content=>$html,category=>{name=>"topfreeapplications"},genre=>{name=>"6018"},limit=>10);

GooglePlay
==========

    my $crawler = App::Crawler::GooglePlay->new();
    
    # get ranking
    my $result = $crawler->get_ranking(category=>{name=>"topfreeapplications"},genre=>{name=>"6018"},limit=>10);
    
    # get review
    my $result = $crawler->get_review(app_id=>"xxxxxxx",page=>10);
