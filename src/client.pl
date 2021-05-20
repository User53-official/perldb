
use lib './lib';
use PerlDB;
use Data::Dumper;
use JSON::XS;

my $db = new PerlDB("http://127.0.0.1:9091", "");

$db->store("test", "test$_", encode_json({ "test$_" => "object" })) for (1..10);
print Dumper decode_json($db->remove("test", "test", "ne~"));
