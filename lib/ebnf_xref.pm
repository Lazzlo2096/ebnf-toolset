#!perl -w
#
#   Copyright (c) 2000-2003 Andreas Gieriet
#
#   You may distribute under the terms of the GNU General Public License.
#

require ebnf_parser;
require ebnf_visit;

#################################
package SyntaxXref;
@ISA = qw ( SyntaxWalk );

sub setProd {
    my $this = shift;
    my $p = shift;
    my $lhs = $p->{ lhs };
    my $nm = $lhs->{ name };
    $this->{ xrefProd } = $nm;
}

sub resetProd {
    my $this = shift;
    $this-> { xrefProd } = "";
}

sub getProd {
    my $this = shift;
    return $this->{ xrefProd };
}

sub setNameXref {
    my $this = shift;
    my $obj = shift;
    $this->{ prodHash }{ $obj->{name} }{ $this->getProd()} = 1;
}

sub setLiteralXref {
    my $this = shift;
    my $obj = shift;
    $this->{ litHash }{ $obj->{literal} }{ $this->getProd()} = 1;
}

sub setTerminalXref {
    my $this = shift;
    my $obj = shift;
    $this->{ termHash }{ $obj->{final} }{ $this->getProd()} = 1;
}

sub setVariantsXref {
    my $this = shift;
    my $obj = shift;
    push(@{$this->{ variantsHash }{ $obj->{name} }{ $this->getProd()}}, $obj->{ expr });
}


sub create {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {};
    bless($self, $class);
    
    $self->{ xrefProd } = "";
    $self->{ prodHash } = {};
    $self->{ termHash } = {};
    $self->{ litHash } = {};
	$self->{ variantsHash } = {};
    $self->{ unusedProd } = [];
    return $self;
}


sub visitSyntaxRoot {
    my $this = shift;
    my $obj = shift;

    # init syntax data structures
    my $lhs;
    my $nm;
    my $p;
    my $prodXref;
    foreach $p (@{ $obj->{ prod } }) {
		$lhs = $p->{ lhs };
		$nm = $lhs->{ name };
		$prodXref = \%{ $this->{ prodHash } };
		if (exists($prodXref->{$nm})) {
			die("Production $nm is multiple defined\n");
		}
		$prodXref->{$nm} = {};
    }
    $this->SUPER::visitSyntaxRoot($obj);
	
    my $i = 0;
    foreach $p (@{ $obj->{ prod } }) {
		if ($i > 0) {
			$lhs = $p->{ lhs };
			$nm = $lhs->{ name };
			$prodXref = \%{ $this->{ prodHash } };
			if (scalar(keys %{ $prodXref->{$nm}}) == 0) {
				push(@{$this->{ unusedProd }}, $p);
				delete($prodXref->{$nm});
			}
		}
		$i++;
    }
}

sub visitSyntaxProd {
    my $this = shift;
    my $obj = shift;
    
    $this->setProd($obj);
    $this->SUPER::visitSyntaxProd($obj);
    $this->resetProd();
}


sub visitSyntaxName {
    my $this = shift;
    my $obj = shift;
    $this->setNameXref($obj);
}


sub visitSyntaxLiteral {
    my $this = shift;
    my $obj = shift;
    $this->setLiteralXref($obj);
}


sub visitSyntaxFinal {
    my $this = shift;
    my $obj = shift;
    $this->setTerminalXref($obj);
}

sub visitSyntaxNamedExpr {
    my $this = shift;
    my $obj = shift;
	$this->setVariantsXref($obj);
    $this->SUPER::visitSyntaxNamedExpr($obj);
}

1;

