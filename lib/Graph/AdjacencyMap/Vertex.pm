package Graph::AdjacencyMap::Vertex;

# THIS IS INTERNAL IMPLEMENTATION ONLY, NOT TO BE USED DIRECTLY.
# THE INTERFACE IS HARD TO USE AND GOING TO STAY THAT WAY AND
# ALMOST GUARANTEED TO CHANGE OR GO AWAY IN FUTURE RELEASES.

use strict;
use warnings;

# $SIG{__DIE__ } = \&Graph::__carp_confess;
# $SIG{__WARN__} = \&Graph::__carp_confess;

use Graph::AdjacencyMap qw(:flags :fields);
use base 'Graph::AdjacencyMap';

sub stringify {
    require Graph::AdjacencyMap::Heavy;
    goto &Graph::AdjacencyMap::Heavy::stringify;
}

require overload; # for de-overloading

sub __strval {
  my ($k, $f) = @_;
  ref $k && ($f & _REF) &&
    (($f & _STR) ? !overload::Method($k, '""') : overload::Method($k, '""')) ?
	overload::StrVal($k) : $k;
}

sub __set_path {
    my $f = $_[0]->[ _f ];
    Graph::__carp_confess(sprintf "arguments %d expected %d for\n".$_[0]->stringify, @_ - 1)
	if @_ != (2 + ($f & _MULTI));
    [ $_[0]->[ _s ] ||= { } ], [ __strval($_[1], $f) ];
}

sub __set_path_node {
    my ($m, $p, $l) = @_;
    my $f = $m->[ _f ];
    my $id = $_[-1] if ($f & _MULTI);
    return $m->_inc_node( \$p->[-1]->{ $l }, $id ) if exists $p->[-1]->{ $l };
    my $i = $m->_new_node( \$p->[-1]->{ $l }, $id );
    die "undefined index" if !defined $i;
    $m->[ _i ][ $i ] = $_[3];
}

sub set_path {
    my ($m) = @_;
    my $f = $m->[ _f ];
    my ($p, $k) = &__set_path;
    return unless defined $p && defined $k;
    my $l = defined $k->[-1] ? $k->[-1] : "";
    my $set = $m->__set_path_node( $p, $l, @_[1..$#_] );
    return $set;
}

sub __has_path {
    my $f = $_[0]->[ _f ];
    Graph::__carp_confess(sprintf "arguments %d expected %d for\n".$_[0]->stringify, @_ - 1, (1 + ($f & _MULTI)))
	if @_ - 1 != (1 + ($f & _MULTI));
    return unless defined(my $p = $_[0]->[ _s ]);
    return ([$p], [ __strval($_[1], $f) ]);
}

sub has_path {
    my $m = $_[0];
    return unless my ($p, $k) = &__has_path;
    return exists $p->[-1]->{ defined $k->[-1] ? $k->[-1] : "" };
}

sub has_path_by_multi_id {
    my ($m) = @_;
    my $id = pop;
    my ($e, $n) = &{ $_[0]->can('__get_path_node') };
    return undef unless $e;
    return exists $n->[ _nm ]->{ $id };
}

sub _get_path_id {
    my ($m) = @_;
    my $f = $m->[ _f ];
    my ($e, $n) = &{ $_[0]->can('__get_path_node') };
    return undef unless $e;
    return ref $n ? $n->[ _ni ] : $n;
}

sub _get_path_count {
    my ($m) = @_;
    my $f = $m->[ _f ];
    my ($e, $n) = &{ $_[0]->can('__get_path_node') };
    return 0 unless $e && defined $n;
    return
	($f & _COUNT) ? $n->[ _nc ] :
	($f & _MULTI) ? scalar keys %{ $n->[ _nm ] } : 1;
}

sub __attr {
    my ($m) = @_;
    return if @_ < 3;
    Graph::__carp_confess(sprintf "arguments %d expected %d for\n".$m->stringify,
		  @_ - 1, $m->[ _arity ])
        if @_ - 1 != $m->[ _arity ];
    my $f = $m->[ _f ];
    return if !($f & _UNORDUNIQ);
    goto &Graph::AdjacencyMap::__arg if ($f & _UNORDUNIQ) != _UNORD;
    @_ = ($_[0], sort @_[1..$#_]);
}

sub get_paths_by_ids {
    my ($m, $list) = @_;
    my $i = $m->[ _i ];
    map [ map {
	my @v = defined $i ? $i->[ $_ ] : undef;
	@v == 1 ? $v[0] : \@v
    } @$_ ], @$list;
}

sub del_path {
    my ($m) = @_;
    my $f = $m->[ _f ];
    my ($e, $n, $p, $k, $l) = &{ $_[0]->can('__get_path_node') };
    return unless $e;
    my $c = ($f & _COUNT) ? --$n->[ _nc ] : 0;
    if ($c == 0) {
	delete $m->[ _i ][ ref $n ? $n->[ _ni ] : $n ];
	delete $p->[ -1 ]{ $l };
    }
    return 1;
}

sub rename_path {
    my ($m, $from, $to) = @_;
    my ($e, $n, $p, $k, $l) = $m->__get_path_node( $from );
    return unless $e;
    $m->[ _i ][ ref $n ? $n->[ _ni ] : $n ] = $to;
    $p->[ -1 ]{ $to } = delete $p->[ -1 ]{ $l };
    return 1;
}

sub del_path_by_multi_id {
    my ($m) = @_;
    my $f = $m->[ _f ];
    my $id = $_[-1];
    my ($e, $n, $p, $k, $l) = &{ $_[0]->can('__get_path_node') };
    return unless $e;
    delete $n->[ _nm ]->{ $id };
    unless (keys %{ $n->[ _nm ] }) {
	delete $m->[ _i ][ $n->[ _ni ] ];
	delete $p->[-1]{ $l };
    }
    return 1;
}

sub paths {
    my $m = shift;
    return map [ $_ ], grep defined, @{ $m->[ _i ] } if defined $m->[ _i ];
    wantarray ? ( ) : 0;
}

1;
