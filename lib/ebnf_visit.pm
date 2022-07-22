#!perl -w
#
#   Copyright (c) 2000-2003 Andreas Gieriet
#
#   You may distribute under the terms of the GNU General Public License.
#

# History
# ......01 ag  Original version
# 23.08.01 ag  Named expression added

require ebnf_parser;

#################################
package SyntaxVisitor;
@ISA = qw ( );

sub create {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {};
    bless($self, $class);
    
    return $self;
}


sub visitSyntaxRoot {
    my $this = shift;
    my $obj = shift;
}

sub visitSyntaxProd {
    my $this = shift;
    my $obj = shift;
}


sub visitSyntaxLhs {
    my $this = shift;
    my $obj = shift;
}


sub visitSyntaxExpr {
    my $this = shift;
    my $obj = shift;
}


sub visitSyntaxTerm {
    my $this = shift;
    my $obj = shift;
}


sub visitSyntaxFactor {
    my $this = shift;
    my $obj = shift;
}


sub visitSyntaxName {
    my $this = shift;
    my $obj = shift;
}


sub visitSyntaxLiteral {
    my $this = shift;
    my $obj = shift;
}


sub visitSyntaxFinal {
    my $this = shift;
    my $obj = shift;
}


sub visitSyntaxOptional {
    my $this = shift;
    my $obj = shift;
}


sub visitSyntaxOptionalList {
    my $this = shift;
    my $obj = shift;
}


sub visitSyntaxGroup {
    my $this = shift;
    my $obj = shift;
}

sub visitSyntaxNamedExpr {
    my $this = shift;
    my $obj = shift;
}

#################################
package SyntaxWalk;
@ISA = qw ( SyntaxVisitor );

sub create {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {};
    bless($self, $class);
    
    return $self;
}


sub visitSyntaxRoot {
    my $this = shift;
    my $obj = shift;

    my $p;
    foreach $p (@{ $obj->{ prod } }) {
	$p->accept($this);
    }
}

sub visitSyntaxProd {
    my $this = shift;
    my $obj = shift;

    my $lhs  = $obj->{ lhs };
    my $expr = $obj->{ expr };
    $lhs->accept($this);
    $expr->accept($this);
}


sub visitSyntaxLhs {
    my $this = shift;
    my $obj = shift;

    my $name = $obj->{ name };
}


sub visitSyntaxExpr {
    my $this = shift;
    my $obj = shift;

    my $t;
    foreach $t (@{ $obj->{ term } }) {
	$t->accept($this);
    }
}


sub visitSyntaxTerm {
    my $this = shift;
    my $obj = shift;

    my $f;
    foreach $f (@{ $obj->{ factor } }) {
	$f->accept($this);
    }
}


sub visitSyntaxFactor {
    my $this = shift;
    my $obj = shift;

    # abstract
}


sub visitSyntaxName {
    my $this = shift;
    my $obj = shift;

    my $name = $obj->{ name };
}


sub visitSyntaxLiteral {
    my $this = shift;
    my $obj = shift;

    my $literal = $obj->{ literal };
}


sub visitSyntaxFinal {
    my $this = shift;
    my $obj = shift;

    my $final = $obj->{ final };
}


sub visitSyntaxOptional {
    my $this = shift;
    my $obj = shift;

    my $expr = $obj->{ expr };
    $expr->accept($this);
}


sub visitSyntaxOptionalList {
    my $this = shift;
    my $obj = shift;

    my $expr = $obj->{ expr };
    $expr->accept($this);
}


sub visitSyntaxGroup {
    my $this = shift;
    my $obj = shift;

    my $expr = $obj->{ expr };
    $expr->accept($this);
}

sub visitSyntaxNamedExpr {
    my $this = shift;
    my $obj = shift;

    my $expr = $obj->{ expr };
    $expr->accept($this);
}

1;
