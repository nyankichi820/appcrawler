package App::Crawler::AppStore;
use strict;
use warnings;
use LWP::UserAgent;
use HTTP::Cookies;
use Crypt::SSLeay;
use Encode;
use Digest::SHA qw(sha1_hex);
use JSON;
use URI;
use URI::QueryParam;
use Web::Scraper;
use XML::XPath;
use Time::Piece;
use Error qw/:try/;
use App::Crawler::Exception;
use base qw(Class::Accessor::Fast Class::Data::Inheritable);
__PACKAGE__->mk_accessors(qw/ua/);
sub GENRES{
    return  [
    {genre_id => 1, label => 'book', name => '6018'},
    {genre_id => 2, label => 'business', name => '6000'},
    {genre_id => 3, label => 'catalog', name => '6022'},
    {genre_id => 4, label => 'education', name => '6017'},
    {genre_id => 5, label => 'entertainment', name => '6016'},
    {genre_id => 6, label => 'finance', name => '6015'},
    {genre_id => 7, label => 'foot & drink', name => '6023'},
    {genre_id => 8, label => 'game', name => '6014'},
    {genre_id => 9, label => 'health & fitness', name => '6013'},
    {genre_id => 10, label => 'lifestyle', name => '6012'},
    {genre_id => 11, label => 'medical', name => '6020'},
    {genre_id => 12, label => 'music', name => '6011'},
    {genre_id => 13, label => 'navigation', name => '6010'},
    {genre_id => 14, label => 'news', name => '6009'},
    {genre_id => 15, label => 'newsstang', name => '6021'},
    {genre_id => 16, label => 'photo & video', name => '6008'},
    {genre_id => 17, label => 'productivity', name => '6007'},
    {genre_id => 18, label => 'reference', name => '6006'},
    {genre_id => 19, label => 'social networking', name => '6005'},
    {genre_id => 20, name  => '7001',label => 'Action'},
    {genre_id => 21, name  => '7002',label => 'Adventure'},
    {genre_id => 22, name  => '7003',label => 'Arcade'},
    {genre_id => 23, name  => '7004',label => 'Board'},
    {genre_id => 24, name  => '7005',label => 'Card'},
    {genre_id => 25, name  => '7006',label => 'Casino'},
    {genre_id => 26, name  => '7007',label => 'Dice'},
    {genre_id => 27, name  => '7008',label => 'Educational'},
    {genre_id => 28, name  => '7009',label => 'Family'},
    {genre_id => 29, name  => '7010',label => 'Kids'},
    {genre_id => 30, name  => '7011',label => 'Music'},
    {genre_id => 31, name  => '7012',label => 'Puzzle'},
    {genre_id => 32, name  => '7013',label => 'Racing'},
    {genre_id => 33, name  => '7014',label => 'Role Playing'},
    {genre_id => 34, name  => '7015',label => 'Simulation'},
    {genre_id => 35, name  => '7016',label => 'Sports'},
    {genre_id => 36, name  => '7017',label => 'Strategy'},
    {genre_id => 37, name  => '7018',label => 'Trivia'},
    {genre_id => 38, name  => '7019',label => 'Word'},
  ];

}

sub GAME_GENRES{
    my @genres = splice @{GENRES()} ,19,18;
    return \@genres;
}

sub CATEGORIES{
    return [
       {category_id => 0 ,name => 'topfreeapplications'},
       {category_id => 1 ,name => 'toppaidapplications'},
       {category_id => 2 ,name => 'topgrossingapplications'},
       {category_id => 3 ,name => 'newapplications'},
    ];
}

sub detail_url{
	my $app_id = shift;
	return "https://play.google.com/store/apps/details";
}

sub review_url{
	my $app_id = shift;
	return "https://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews";
}

sub ranking_url{
	my %args = @_;
    if ( !$args{genre} ){
        return sprintf("https://itunes.apple.com/jp/rss/%s/limit=%s/xml",$args{category}->{name},$args{limit})
    }
    else{
        return sprintf("https://itunes.apple.com/jp/rss/%s/limit=%s/genre=%s/xml",$args{category}->{name},$args{limit},$args{genre}->{name});
    }
}

sub new{
	my $class = shift;
	my $self  = $class->SUPER::new();
	my %args  = @_;
	bless $self,$class;
	$self->ua( LWP::UserAgent->new);
    if($args{proxy}){
        local $ENV{HTTPS_PROXY} = $args{proxy} ;
        $self->ua->ssl_opts ( verify_hostname => '0');
        $self->ua->env_proxy;
    }
	return $self;
}

sub AUTOLOAD {
    our $AUTOLOAD; 
    my ($self,%args) = @_; 
    my ($type) = ( $AUTOLOAD =~ /::get_([a-z]+)$/ );
    if($type){
        my $content =  $self->fetch_ranking(%args);
        my $result = $self->parse_ranking(%args,content =>  $content);
        return $result;
    }
}


sub fetch_ranking{
	my $self = shift;
	my %args  = @_;
    my $u = URI->new(ranking_url(%args));

    my $scraper = scraper {
        process '//entry',  "ranking[]" => scraper {
            process '//summary',  description => 'TEXT';
            process '//im:name', title => 'TEXT';
        };
    };
	my $req = HTTP::Request->new(GET => $u);
	my $res = $self->ua->request($req);

	if ($res->is_success) {
        return $res->content;
    }
    else{
        throw App::Crawler::Exception::NetworkException("network error");
    }


}

sub parse_ranking{
	my $self = shift;
	my %args  = @_;

    my $content = $args{content};

    return [] unless ($content);

    my $xpath = XML::XPath->new(xml => $content );
    my @rankings;
    my $rank = 1;
    foreach my $node ( $xpath->find('//entry')->get_nodelist ){
        my $app  = {
            name =>encode("utf8", $node->findvalue( './im:name')->value),
            url  => $node->findvalue( './link/@href')->value,
            updated => $node->findvalue( './updated')->value,
            description =>encode("utf8", $node->findvalue( './summary')->value),
            developer =>encode("utf8", $node->findvalue( './im:artist')->value),
            price => $node->findvalue( './im:price/@amount')->value,
            release_date => $node->findvalue( './im:releaseDate')->value,
            $args{genre} ? ( genre => $args{genre}  )  : () ,
            category => $args{category},
            rank     => $rank,
        };
        foreach my $image ( $node->find( './im:image')->get_nodelist){
            $app->{large_image} = $image->string_value if $image->string_value =~ /100x100/;
            $app->{midle_image} = $image->string_value if $image->string_value =~ /75x75/;
            $app->{small_image} = $image->string_value if $image->string_value =~ /53x53/;
        }
        my ($app_id) = ($app->{url} =~ /id([0-9]+)\?/);
        $app->{app_id} = $app_id;
        push @rankings,$app;
        $rank++;
    }
    return \@rankings;
}

sub fetch_app{
	my $self = shift;
	my %args  = @_;
    my $u = URI->new($args{url});
    #$u->query_form_hash({start => $args{offset},num => $args{limit}, numChildren=>0 });

    my $scraper = scraper {
        process '//entry',  "ranking[]" => scraper {
            process '//summary',  description => 'TEXT';
            process '//im:name', title => 'TEXT';
        };
    };
	my $req = HTTP::Request->new(GET => $u);
	my $res = $self->ua->request($req);

	if ($res->is_success) {
        return $res->content;
    }
    else{
        throw App::Crawler::Exception::NetworkException("network error");
    }
}

sub parse_app{
	my $self = shift;
	my %args  = @_;

    my $content = $args{content};
    my $xpath = XML::XPath->new(xml => $content );
    my %app_info;
    my @ratings;
    my @all_ratings;
    
    foreach my $item (  $xpath->find('.//TextView[@topInset="0" and  @truncation="right" and  @leftInset="0" and  @styleSet="basic11" and  @textJust="left" and  @maxLines="1"]')->get_nodelist ){
        use Data::Dumper qw(Dumper);warn Dumper $item->string_value;
        if ( $item->string_value =~ /([0-9]+) ratings$/){
            push @all_ratings,$1;
        }
    }
    $app_info{current_ratings} = $all_ratings[0];
    $app_info{all_ratings} = $all_ratings[2];

    foreach my $item (  $xpath->find('.//TextView[@topInset="2"  and @leftInset="5" and  @styleSet="basic10" and  @alt=""]')->get_nodelist ){
        last if(!$item->string_value);
        if(scalar @ratings < 4){
            my $star_number = 5 - scalar @ratings;
            $app_info{"current_rating_$star_number"} = $item->string_value; 
        }
        else{
            my $star_number = 10 - scalar @ratings;
            $app_info{"all_rating_$star_number"} = $item->string_value; 
        }
        push @ratings,$item->string_value;
        
    }
    return \%app_info;

}




sub fetch_review{
	my $self = shift;
	my %args  = @_;
    my $u = URI->new(review_url(%args));
    $u->query_form_hash({id=>$args{app_id},sortOrdering => 4 ,type=>"Purple Software",pageNumber => $args{page}});

	$self->ua->agent("iTunes/9.2 (Windows; Microsoft Windows 7 Home Premium Edition (Build 7600)) AppleWebKit/533.16");
    $self->ua->default_header('Accept-Language' => "ja",'X-Apple-Store-Front' => '143462-1');
    my $scraper = scraper {
        #process '//TextView[@topInset="0"][@styleSet="basic13"][@squishiness="1"][@leftInset="0"][@truncation="right"][@textJust="left"][@maxLines="1"]',  "review[]" => scraper {
        process '//TextView',  "review[]" => scraper {
            process '//a[@class="no-nav g-hovercard"][@title]', user_name => 'TEXT';
            process '//a[@class="no-nav g-hovercard"][@data-userid]', user_id => '@data-userid';
            process '//span[@class="review-title"]', title => 'TEXT';
            process '//span[@class="review-date"]', date => 'TEXT';
            process '//div[@class="review-body"]', publisher => 'TEXT';
            process '//div[@class="current-rating"]', rating => '@style';
            process '//a[@class="reviews-permalink"]', link => '@href';
        };
    };
	my $req = HTTP::Request->new(GET => $u->as_string);
	#my $req = HTTP::Request->new(GET =>"https://itunes.apple.com/WebObjects/MZStore.woa/wa/viewUsersUserReviews?userProfileId=283467792");
	my $res = $self->ua->request($req);

	if ($res->is_success) {
        return $res->content;
	}
    else{
        throw App::Crawler::Exception::NetworkException("network error");
    }

}


sub parse_review{
	my $self = shift;
	my %args  = @_;

    my $content = $args{content};
    return [] unless $content;

    my $xpath = XML::XPath->new(xml => $content );
    my @reviews;
    foreach my $item (  $xpath->find('.//TextView[@topInset="0"][@styleSet="basic13"][@squishiness="1"][@leftInset="0"][@truncation="right"][@textJust="left"][@maxLines="1"]')->get_nodelist ){
        my $data =  encode("utf8",$item->string_value);
        $data =~ s/\n//g;
        next if ( $data !~ /^ +by/);
        $data =~ s/\ +by +//g;
        $data =~ s/ +$//g;
        $data =~ s/\ +- +/-/g;
        my ($user_name,$app_version,$date) = ($data =~ /(.*)\-Version ([0-9\.]+)\-(.*)$/);
        $date = Time::Piece->strptime($date , "%b %d, %Y")->ymd;
        push @reviews,{
            user_name   => $user_name,
            app_version => $app_version,
            date        => $date,
        }; 
    }
    my @review_ids;
    my @user_ids;
    foreach my $item (  $xpath->find('.//GotoURL[@target="main"]')->get_nodelist ){
        my $url =  $item->getAttribute("url");
        if ( $url =~ /reportUserReviewConcern\?userReviewId=([0-9]+)/){
            my $review_id = $1;
            if ( ! grep {$_ == $review_id} @review_ids){
                $reviews[scalar @review_ids]->{review_id} = $review_id;
                push @review_ids , $review_id;
            }
        }
        if ( $url =~ /viewUsersUserReviews\?userProfileId=([0-9]+)/){
            my $user_id = $1;
            $reviews[scalar @user_ids]->{user_id} = $user_id;
            push @user_ids , $user_id;
        }
    }
    my $count = 0;
    foreach my $item (  $xpath->find('.//TextView[@styleSet="basic13" and @textJust="left" and @maxLines="1"]')->get_nodelist ){
        my $title =  encode("utf8",$item->string_value);
        $title =~ s/\n//g;
        next if ( $title =~ /^ +by .*Version/);
        next if ( $title =~ /^Average rating for /);

        $title =~ s/^ +//g;
        $title =~ s/ +$//g;
        $reviews[$count]->{title} = $title;
        $count++;
    }
    $count = 0;
    foreach my $item (  $xpath->find('.//HBoxView[@topInset="1" and @alt]')->get_nodelist ){
        my $rating =  $item->getAttribute("alt");
        $rating =~ s/ star.*$//g;
        $reviews[$count]->{rating} = $rating;
        $count++;
    }

    $count = 0;
    foreach my $item (  $xpath->find('.//TextView[@styleSet="normal11"]')->get_nodelist ){
        my $body =  encode("utf8",$item->string_value);
        $body =~ s/\n//g;
        next if ( $body =~ /^ +by .*Version/);
        next if ( $body =~ /^Average rating for /);

        $body =~ s/^ +//g;
        $body =~ s/ +$//g;
        $reviews[$count]->{body} = $body;
        $count++;
    }
    

    return \@reviews;

}


1;
