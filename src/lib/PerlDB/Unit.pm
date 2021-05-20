package PerlDB::Unit;

use Exporter qw(import);
use experimental 'signatures';
use Data::Structure::Util qw( unbless );

sub new {
  my ($class, $self) = @_;
  $self = {} unless defined $self;
  bless $self, $class;
  return $self;
}

## Store
sub persist($self, $key, $value) {
  $self->{$key} = $value;
  return { 
    success => "Added new record with key '$key' and value '$value' ", 
    nbResults => 1 
  };
}

## General use
sub check {
  my ($self, $key) = @_;
  return exists($self->{$key})? 1 : 0;
}

## Search
sub all {
  my ($self, $output, $sorted) = @_;
  unbless $self;
  my $result;
  if ($output eq "PAIRS") {
    my @records = map { [ $_, $self->{$_} ] } ($sorted? sort keys %{$self} : keys %{$self});
    my $count = values %records;
    $result = {
      records => \@records, 
      nbResults => $count
    };
  } elsif ($output eq "KEYS") {
    my @keys = $sorted? sort keys %{$self} : keys %{$self};
    $result = {
      records => \@keys,
      nbResults => scalar(@keys)
    };
  } elsif ($output eq "VALUES") {
    my @values = $sorted? map { $self->{$_} } sort keys %{$self} : values %{$self};
    $result = {
      records => \@values,
      nbResults => scalar(@values)
    };
  } else {
    $result = { error => "Incorrect output mode '$output'. Cannot retrieve data." };
  }
  bless $self, Unit;
  return $result;
}

sub searchRegex {
  my ($self, $predicate, $output, $sorted) = @_;
  my @keys;
  $result_maker = 
  my $accumulator = sub { push @keys, $_[0]; } if $sorted;
  my $result = $sorted? gen_sorter($output) : sub {
    return \@keys;
  };
  unless ($sorted) {
    if ($output eq "PAIRS") {
      $accumulator = sub ($key, $record) {
        push @keys, [ $key, $record ];
      };
    } elsif ($output eq "VALUES") {
      $accumulator = sub ($key, $record) {
        push @keys, $record;
      };
    } elsif ($output eq "KEYS") {
      $accumulator = sub ($key, $record) {
        push @keys, $key;
      };
    } else {
      return { 
        error => "Error retrieving items, unrecognised output mode '$output_mode'." 
      };
    }
  }
  my $count = 0;
  while (my ($key, $record) = each(%{$self})) {
    if ($predicate->($key)) {
      $accumulator->($key, $record);
      $count++;
    }
  }

  return {
    records => $result->($self, @keys),
    nbResults => $count
  };
}

sub searchEquals($self, $key, $output) {
  my $nbRecords = $self->check($key);
  my $records = {};
  if ($nbRecords) {
    if ($output eq "PAIRS") {
      $records = [ [ $key => $self->{$key} ] ];
    } elsif ($output eq "VALUES") {
      $records = [ $self->{$key} ];
    } elsif ($output eq "KEYS") {
      $records = [ $key ];
    }
  }
  my $records = $nbRecords? { $key => $self->{$key} } : {};
  return {
    records => $records, 
    nbResults => $nbRecords
  };
}

sub search($self, $operator, $searchValue, $output, $sorted) {
  if ($operator eq "eq~") {
    return $self->searchRegex(sub ($key) { 
      return $key =~ m"$searchValue" 
    }, $output, $sorted);
  } elsif ($operator eq "ne~") {
    return $self->searchRegex(sub ($key) { 
      return $key !~ m"$searchValue" 
    }, $output, $sorted);
  } elsif ($operator eq "eq") {
    return $self->searchEquals($searchValue);
  } elsif ($operator eq "ne") {
    return $self->searchRegex(sub ($key) {
      return $key !~ m"^$searchValue$"
    }, $output, $sorted);
  }
  return { error => "Invalid operator $operator." };
}

## Remove
sub removeRegex {
  my ($self, $operator, $predicate) = @_;
  my @output;
  while (my ($key, $record) = each(%{$self})) {
    if ($predicate->($key)) {
      push @output, { $key => $record };
      delete($self->{$key});
    }
  }
  return { 
    records => \@output,
    nbResults => scalar(@output) 
  }; 
}

sub remove($self, $operator, $expectedKey) {
  if ($operator eq "eq") {
    delete($self->{$expectedKey});
    return {
      success => "Deleted '$expectedKey'.",
      nbResults => $self->check($expectedKey)
    };
  } elsif ($operator eq "eq~") {
    return $self->removeRegex($operator, sub ($key) {
      return $key =~ m"$expectedKey"
    });
  } elsif ($operator eq "ne~") {
    return $self->removeRegex($operator, sub ($key) {
      return $key !~ m"$expectedKey"
    });
  } elsif ($operator eq "ne") {
    return $self->removeRegex($operator, sub ($key) {
      return $key !~ m"^$key$"
    });
  }
  return { error => "Invalid operator $operator. Here are the available operators [ 'eq', 'ne', 'eq~', 'ne~' ] ", };
}

## 'Static' functions

use Storable;

my $path = "$ENV{'HOME'}/.perldb/units";
unless (-e "$ENV{'HOME'}/.perldb") {
  mkdir "$ENV{'HOME'}/.perldb";
  mkdir "$path";
}

sub load {
  my $name = $_[0];
  my $unit = retrieve("$path/$name");
  return new Unit($unit);
}

sub save {
  my ($unit_name, $unit) = @_;
  store $unit, "$path/$unit_name";
  return $unit;
}

sub create {
  my ($name) = @_;
  if (-e "$path/$name") {
    return {
      error => "Unit already exists."
    };
  }
  store {}, "$path/$name";
  return { sucess => "Created unit $name."};
}

sub gen_sorter($output_mode) {
  if ($output_mode eq "PAIRS") {
    return sub ($hash, @keys) {
      @keys = map { [ $_, $hash->{$_} ] } (sort @keys);
      return \@keys;
    };
  } elsif ($output_mode eq "KEYS") {
    return sub ($hash, @keys) {
      @keys = sort @keys;
      return \@keys;
    };
  } elsif ($output_mode eq "VALUES") {
    return sub ($hash, @keys) {
      @keys = map { $hash->{$_} } (sort @keys);
      return \@keys;
    };
  }
  return { error => "Error sorting items, unrecognised output mode '$output_mode'."};
}

1;