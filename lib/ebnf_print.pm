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
require ebnf_visit;

#################################
package SyntaxPrint;
@ISA = qw ( SyntaxWalk );

sub create {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = { indent => 20 };
    bless($self, $class);
    
    return $self;
}

sub printLhs {
    my $this = shift;
    my $name = shift;
    
    my $i = $this->{indent} - length($name);
    printf("%s", $name);
    while ($i > 0) {
	printf(" ");
	$i--;
    }
}


sub visitSyntaxProd {
    my $this = shift;
    my $obj = shift;

    my $lhs  = $obj->{ lhs };
    my $expr = $obj->{ expr };

    $lhs->accept($this);
    printf(" : ");
    $expr->accept($this);
    printf(".\n");
}


sub visitSyntaxLhs {
    my $this = shift;
    my $obj = shift;

    my $name = $obj->{ name };
    $this->printLhs($name);
}


sub visitSyntaxExpr {
    my $this = shift;
    my $obj = shift;

    my $i = 0;
    my $t;
    foreach $t (@{ $obj->{ term } }) {
	if ($i > 0) {
	    printf("\n");
	    $this->printLhs("");
	    printf(" | ");
	}
	$t->accept($this);
	$i++;
    }
    if ($i > 1) {
	printf("\n");
	$this->printLhs("");
	printf(" ");
    }
}


sub visitSyntaxTerm {
    my $this = shift;
    my $obj = shift;

    my $f;
    foreach $f (@{ $obj->{ factor } }) {
	$f->accept($this);
	printf(" ");
    }
}


sub visitSyntaxName {
    my $this = shift;
    my $obj = shift;

    my $name = $obj->{ name };
    my $attr = $obj->{ attr };
    printf("<%s>", $attr) if ($attr);
    printf("%s", $name);
}


sub visitSyntaxLiteral {
    my $this = shift;
    my $obj = shift;

    my $literal = $obj->{ literal };
    printf("%s", $literal);
}


sub visitSyntaxFinal {
    my $this = shift;
    my $obj = shift;

    my $final = $obj->{ final };
    printf("%s", $final);
}


sub visitSyntaxOptional {
    my $this = shift;
    my $obj = shift;

    my $expr = $obj->{ expr };
    printf("[ ");
    $expr->accept($this);
    printf("]");
}


sub visitSyntaxOptionalList {
    my $this = shift;
    my $obj = shift;

    my $expr = $obj->{ expr };
    printf("{ ");
    $expr->accept($this);
    printf("}");
}


sub visitSyntaxGroup {
    my $this = shift;
    my $obj = shift;

    my $expr = $obj->{ expr };
    printf("( ");
    $expr->accept($this);
    printf(")");
}

sub visitSyntaxNamedExpr {
    my $this = shift;
    my $obj = shift;

    my $nm = $obj->{'name'};
    my $expr = $obj->{ expr };
    printf("( ");
    $expr->accept($this);
    printf(")");
    printf(" --> $nm ");
}


1;
