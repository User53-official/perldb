use experimental 'signatures';
use Cwd 'abs_path';
sub println(@values) { print @values, "\n"; }

sub path {
  my @path = split "/", abs_path($0);
  pop @path;
  return join("/", @path) . "/src";
}

my @dependencies = qw(
  Mojolicious 
  Storable
  Data::Structure::Util
  LWP
  LWP::UserAgent
);

my $path = path;
println $path;

my $install_path = "$ENV{'HOME'}/perl5";

println "Starting installation...\n";

println "Copying files over to perl5 directory";
print `cp "$path/perldb" "$install_path/bin/perldb"`;
print `cp -R "$path/lib/" "$install_path/lib/perl5"`;

println "Allowing execution on perldb..";
print `chmod +x "$install_path/bin/perldb"`;

println "Installing or updating dependencies...";
#print `cpan $_` for (@dependencies);