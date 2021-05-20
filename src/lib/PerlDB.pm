package PerlDB;

use experimental 'signatures';
use LWP::UserAgent;

sub new($class, $to, $user_agent, @params) {
  $to =~ s/\/$//;
  my $this = {
    url => $to,
    user_agent => LWP::UserAgent->new
  };
  $this->{user_agent}->agent($user_agent);
  bless $this, $class;
  return $this;
}

sub _request {
  my ($ua, $url, $method, $content) = @_;
  my $req = HTTP::Request->new($method => $url);
  $req->content_type('application/json');
  $req->content($content) if defined $content;
  my $res = $ua->request($req);
  return $res->content;
}

sub search($this, $unit_name, $value, $operator, @optionals) {
  my $url = $this->{url};
  my $output = scalar(@optionals) < 1? "PAIRS" : $optionals[0];
  my $sorted = scalar(@optionals) < 2? 0 : $optionals[1];
  return _request($this->{user_agent}, "$url/search/$unit_name/$value/$operator?output=$output&sorted=$sorted", GET);
}

sub remove($this, $unit_name, $value, $operator) {
  my $url = $this->{url};
  return _request($this->{user_agent}, "$url/remove/$unit_name/$value/$operator", DELETE);
}

sub all($this, $unit_name, @optionals) {
  my $url = $this->{url};
  my $output = scalar(@optionals) < 1? "PAIRS" : $optionals[0];
  my $sorted = scalar(@optionals) < 2? 0 : $optionals[1];
  return _request($this->{user_agent}, "$url/all/$unit_name?output=$output&sorted=$sorted", GET);
}

sub store($this, $unit_name, $key, $value) {
  my $url = $this->{url};
  return _request($this->{user_agent}, "$url/store/$unit_name/$key", PUT, $value);
}

sub create($this, $unit_name) {
  my $url = $this->{url};
  return _request($this->{user_agent}, "$url/create/unit/$unit_name", POST);
}

1;