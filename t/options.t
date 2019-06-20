use strict;
use Test::More tests => 40;
use YAML::Safe;
my $obj = YAML::Safe->new;

my %boolopts = (
  "disableblessed" => 0,
  "enablecode" => 0,
  "nonstrict" => 0,
  "loadcode" => 0,
  "dumpcode" => 0,
  "quotenum" => 0,
  "noindentmap" => 0,
  "canonical" => 0,
  "unicode" => 1,
  "openended" => 0);
my %intopts = (
  "indent" => 2,
  "wrapwidth" => 80);
my %stropts = (
               # default and allowed values
  "boolean" => [undef, "JSON::PP", "boolean", "Types::Serialiser" ],
  "encoding" => [ "any", "any", "utf8", "utf16le" or "utf16be" ],
  "linebreak" => [ "any", "any", "cr", "ln" or "crln" ] );

while (my ($b, $def) = each %boolopts) {
  my $getter = "get_". $b;
  is ($obj->$getter, $def == 0 ? '' : 1, "default $b is $def");
  $obj->$b; # turns it on
  is ($obj->$getter, 1, "$b turned on");
  $obj->$b($def == 0 ? 1 : undef); # switch it
  is ($obj->$getter, $def == 0 ? 1 : '', "$b switched");
}

while (my ($b, $def) = each %intopts) {
  my $getter = "get_". $b;
  is ($obj->$getter, $def, "default $b");
  $obj->$b(8);
  is ($obj->$getter, 8, "set $b to 8");
}

while (my ($b, $defa) = each %stropts) {
  my $getter = "get_". $b;
  my $def = shift @$defa;
  my @vals = @$defa;
  is ($obj->$getter, $def, "default $b");
  for (@vals) {
    $obj->$b($_);
    is ($obj->$getter, $_, "set $b to $_");
  }
}
