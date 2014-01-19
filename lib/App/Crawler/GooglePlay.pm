package App::Crawler::GooglePlay;
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
use Error qw/:try/;
use App::Crawler::Exception;
use base qw(Class::Accessor::Fast Class::Data::Inheritable);

__PACKAGE__->mk_accessors(qw/ua/);
sub GENRES{
    return [
    {genre_id => 1, name  => 'APP_WIDGETS',name => 'Widget'},
    {genre_id => 2, name  => 'ENTERTAINMENT',name => 'ENTERTAINMENT'},
    {genre_id => 3, name  => 'PERSONALIZATION',name => 'PERSONALIZATION'},
    {genre_id => 4, name  => 'COMICS',name => 'COMICS'},
    {genre_id => 5, name  => 'SHOPPING',name => 'SHOPPING'},
    {genre_id => 6, name  => 'SPORTS',name => 'SPORTS'},
    {genre_id => 7, name  => 'SOCIAL',name => 'SOCIAL'},
    {genre_id => 8, name  => 'TOOLS',name => 'TOOLS'},
    {genre_id => 9, name  => 'NEWS_AND_MAGAZINES',name => 'NEWS_AND_MAGAZINES'},
    {genre_id => 10, name  => 'BUSINESS',name => 'BUSINESS'},
    {genre_id => 11, name  => 'FINANCE',name => 'FINANCE'},
    {genre_id => 12, name  => 'MEDIA_AND_VIDEO',name => 'MEDIA_AND_VIDEO'},
    {genre_id => 13, name  => 'LIFESTYLE',name => 'LIFESTYLE'},
    {genre_id => 14, name  => 'LIBRARIES_AND_DEMO',name => 'LIBRARIES_AND_DEMO'},
    {genre_id => 15, name  => 'APP_WALLPAPER',name => 'APP_WALLPAPER'},
    {genre_id => 16, name  => 'TRANSPORTATION',name => 'TRANSPORTATION'},
    {genre_id => 17, name  => 'PRODUCTIVITY',name => 'PRODUCTIVITY'},
    {genre_id => 18, name  => 'HEALTH_AND_FITNESS',name => 'HEALTH_AND_FITNESS'},
    {genre_id => 19, name  => 'PHOTOGRAPHY',name => 'PHOTOGRAPHY'},
    {genre_id => 20, name  => 'MEDICAL',name => 'MEDICAL'},
    {genre_id => 21, name  => 'WEATHER',name => 'WEATHER'},
    {genre_id => 22, name  => 'EDUCATION',name => 'EDUCATION'},
    {genre_id => 23, name  => 'TRAVEL_AND_LOCAL',name => 'TRAVEL_AND_LOCAL'},
    {genre_id => 24, name  => 'BOOKS_AND_REFERENCE',name => 'BOOKS_AND_REFERENCE'},
    {genre_id => 25, name  => 'COMMUNICATION',name => 'COMMUNICATION'},
    {genre_id => 26, name  => 'MUSIC_AND_AUDIO',name => 'MUSIC_AND_AUDIO'},
    {genre_id => 27, name  => 'GAME',name => 'GAME'},
    {genre_id => 28, name  => 'ARCADE',name => 'ARCADE'},
    {genre_id => 29, name  => 'GAME_WIDGETS',name => 'GAME_WIDGETS'},
    {genre_id => 30, name  => 'CASUAL',name => 'CASUAL'},
    {genre_id => 31, name  => 'CARDS',name => 'CARDS'},
    {genre_id => 32, name  => 'SPORTS_GAMES',name => 'SPORTS_GAMES'},
    {genre_id => 33, name  => 'BRAIN',name => 'BRAIN'},
    {genre_id => 34, name  => 'GAME_WALLPAPER',name => 'GAME_WALLPAPER'},
    {genre_id => 35, name  => 'RACING',name => 'RACING'},
  ];
}

sub GAME_GENRES{
    my @genres = splice @{GENRES()} ,26,8;
    return \@genres;
}

sub CATEGORIES{
    return [
     {category_id =>  0,name => 'topselling_free'},
     { category_id => 1,name => 'topselling_paid'},
     { category_id => 2,name => 'topgrossing'},
     { category_id => 3,name => 'topselling_new_paid'},
     { category_id => 4,name => 'topselling_new_free'},
    ];
}

sub detail_url{
	my $app_id = shift;
	return "https://play.google.com/store/apps/details";
}

sub review_url{
	my $app_id = shift;
	return "https://play.google.com/store/getreviews";
}


sub ranking_url{
	my %args = @_;
    if ( !$args{genre} ){
        return sprintf("https://play.google.com/store/apps/collection/%s",$args{category}->{name})
    }
    else{
        return sprintf("https://play.google.com/store/apps/category/%s/collection/%s",$args{genre}->{name},$args{category}->{name});
    }
}

sub new{
	my $class = shift;
	my $self  = $class->SUPER::new();
	my %args  = @_;
	bless $self,$class;
	$self->ua( LWP::UserAgent->new);
	$self->ua->agent("Mozilla/5.0 (Windows; U; Windows NT 5.1; ja; rv:1.9.0.10) Gecko/2009042316 Firefox/3.0.10 GTB5");
    if($args{proxy}){
        local $ENV{HTTPS_PROXY} = $args{proxy} ;
        $self->ua->ssl_opts ( verify_hostname => '0');
        $self->ua->env_proxy;
    }
    $self->ua->default_header('Accept-Language' => "ja");
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


sub proxy{
    my ($self,$proxy) = @_;
    local $ENV{HTTPS_PROXY} = $proxy ;
    $self->ua->ssl_opts ( verify_hostname => '0');
    $self->ua->env_proxy;
}

sub fetch_ranking{
	my $self = shift;
	my %args  = @_;
    my $u = URI->new(ranking_url(%args));
    $u->query_form_hash({start => $args{offset},num => $args{limit}, numChildren=>0 });

    my $req = HTTP::Request->new(GET => $u->as_string);
	my $res = $self->ua->request($req);
    if ($res->is_success) {
        return $res->content;
	}
    else{
        if($res->code == 404){
            return "";
        }
        elsif($res->code == 302){
            throw App::Crawler::Exception::AccessLimitationException("access limitation");
        }
        else{
            throw App::Crawler::Exception::NetworkException("network error ".$res->content);
        }   
    }

}

sub parse_ranking{
    my ($self,%args ) = @_;
    my $scraper = scraper {
        process '//div[@class="card no-rationale square-cover apps small"]',  "ranking[]" => scraper {
            process '//div[@class="description"]',  description => 'TEXT';
            process '//img', thumbnail => '@src';
            process '//a[@class="title"]', url => '@href';
            process '//a[@class="title"]', name => '@title';
            process '//a[@class="subtitle"]', developer => '@title';
            process '//span[@class="price buy"]/span', price => 'TEXT';
            process '//div[@class="current-rating"]', rating => '@style';
        };
    };
    my $content = $args{content};
    return unless $content;
    my $data = $scraper->scrape($content);

    if( ! $data->{ranking} ){
        throw App::Crawler::Exception::ContentParseException("cant parse");
    }

    my $rank = 1 + $args{offset};
    foreach my $item ( @{$data->{ranking}}){
        $item->{genre} = $args{genre} if ( $args{genre});
        $item->{category} = $args{category};
        $item->{rank} = $rank;
        $item->{app_id} = $item->{url};
        $item->{app_id} =~ s/.*\?id=//g;
        my ($rating) = ($item->{rating} =~ /width: ([0-9\.]+)/);
        $item->{rating} = $rating / 20;
        $rank++;
    }
    return $data->{ranking};
}

sub fetch_review{
	my $self = shift;
	my %args  = @_;
    my $u = URI->new("","https");
    $u->query_form_hash({id=>$args{app_id},reviewSortOrder => 0 ,reviewType=>1,pageNum => $args{page}});

	my $req = HTTP::Request->new(POST => review_url(%args));
    $req->content_type('application/x-www-form-urlencoded');
    $req->content($u->query);
	my $res = $self->ua->request($req);
	if ($res->is_success) {
        if($res->code == 302){
            throw App::Crawler::Exception::AccessLimitationExepction("access limitation");
        }   
        return $res->content;
	}
    else{
        if($res->code == 404){
            return "";
        }
        elsif($res->code == 302){
            throw App::Crawler::Exception::AccessLimitationException("access limitation");
        }
        else{
            throw App::Crawler::Exception::NetworkException("network error");
        }   

    }
}

sub parse_review{
	my ($self,%args) = @_;

    my $scraper = scraper {
        process '//div[@class="single-review"]',  "review[]" => scraper {
            process '//a[@class="no-nav g-hovercard"][@title]', user_name => 'TEXT';
            process '//a[@class="no-nav g-hovercard"][@data-userid]', user_id => '@data-userid';
            process '//span[@class="review-title"]', title => 'TEXT';
            process '//span[@class="review-date"]', date => 'TEXT';
            process '//div[@class="review-body"]', body => 'TEXT';
            process '//div[@class="current-rating"]', rating => '@style';
            process '//a[@class="reviews-permalink"]', url => '@href';
        };
    };
    my $content = $args{content};

    return if ! $content;

    $content =~ s/\)\]\}\'//g;
    $content = encode("utf8",decode("utf8",$content));
    my $decoded;
    try{
        $decoded = decode_json($content);
    };
    if($@){
        warn $@;
        return;
    }
    $content = encode("utf8",$decoded->[0]->[2]);
    my $data = $scraper->scrape($content);
    foreach my $item ( @{$data->{review}}){
       my ($rating) = ($item->{rating} =~ /width: ([0-9]+)/);
       my ($year,$month,$day) = ($item->{date} =~ /([0-9]*)年([0-9]*)月([0-9]*)日/);
       $item->{date} = "$year-$month-$day";
       $item->{rating} = $rating / 20;
       $item->{review_id} = $item->{url};
       $item->{review_id} =~ s/.*reviewId=//g;
       $item->{body} =~ s/ 全文を表示$//g;
    }
    return $data->{review};

}

1;

=head1 NAME

App::Crawler::GooglePlay - google play ranking crawler

=head1 SYNOPSIS

    my $crawler = App::Crawler::GooglePlay->new();
    
    # get ranking
    my $result = $crawler->get_ranking(category=>{name=>"topfreeapplications"},genre=>{name=>"6018"},limit=>10);
    
    # get review
    my $result = $crawler->get_review(app_id=>"xxxxxxx",page=>10);



=cut

=head1 NOTE

    google play has access limitation. It will be ban if you access violently.
    If you want more access, please accessed by switching in each time set multiple proxies.

=cut
