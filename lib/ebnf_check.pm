#!perl -w
#
#   Copyright (c) 2000-2003 Andreas Gieriet
#
#   You may distribute under the terms of the GNU General Public License.
#

#################################
package SyntaxCheck;
@ISA = qw ( SyntaxWalk );

sub create {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {};
    bless($self, $class);

    $self->{ lhsNames } = {};

    return $self;
}


sub visitSyntaxRoot {
    my $this = shift;
    my $obj = shift;

    my $lhs;
    my $nm;
    my $p;
    foreach $p (@{ $obj->{ prod } }) {
	$lhs = $p->{ lhs };
	$nm = $lhs->{ name };
	$this->{ lhsNames }{$nm} = 1;
    }
    foreach $p (@{ $obj->{ prod } }) {
	$p->accept($this);
    }
}

sub visitSyntaxName {
    my $this = shift;
    my $obj = shift;

    my $name = $obj->{ name };
    warn("Production not defined: $name\n") unless exists($this->{lhsNames}{$name});
}

1;

