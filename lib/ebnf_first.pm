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
require util_html;

$::EMPTY = '<EMPTY>';

#################################
package SyntaxFirst;
@ISA = qw ( SyntaxWalk );

sub mergeFirst {
    my $master = shift;
    my $slave = shift;
    map { $master->{$_} = $slave->{$_} } keys %{$slave};
}

sub update {
    my $this = shift;
    my $obj = shift;
    my $f;
    my $o;
    my $p;
    my $h = \%{$obj->{SyntaxFirstHash}};
    foreach $f (keys %$h) {
	$o = $h->{$f};
	if (ref($o)) {
	    $p = $this->{SyntaxFirstProdHash}{$o->{name}};
	    mergeFirst(\%{$h}, \%{$p->{SyntaxFirstHash}});
	    delete($h->{$f});
	}
    }
}

sub create {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {};
    bless($self, $class);
    
    $self->{ SyntaxFirstProdHash } = {};
    $self->{ SyntaxFirstCurrProd } = {};
    $self->{pass} = 0;

    return $self;
}


sub visitSyntaxRoot {
    my $this = shift;
    my $obj = shift;


    my $p;
    foreach $p (@{ $obj->{ prod } }) {
	$this->{ SyntaxFirstProdHash }{$p->{lhs}{name}} = $p;
    }

    foreach $p (@{ $obj->{ prod } }) {
	$p->accept($this);
    }

    ## resolve recursive references

    my %nameXprodLookUp = %{ $this->{ SyntaxFirstProdHash } };
    my %nameXprodToDo   = %nameXprodLookUp;

    my $changed = 0;
    my $nm;
    my $rp;
    my $rnm;
    my $f;
    my $firstHash;
    my $lit;
    do {
	$changed = 0;
	foreach $nm (keys %nameXprodToDo) {
	    $lit = 1;
	    $p = $nameXprodToDo{$nm};
	    $firstHash = \%{$p->{ SyntaxFirstHash }};
	    foreach $rnm (keys %$firstHash) {
		$f = $firstHash->{$rnm};
		if (ref($f)) {
		    # name -> $f = ref to SyntaxName
		    $f = $nameXprodLookUp{$rnm};
		    $lit = 0;
		    if ($f != $p) {
			# non recursive reference
			mergeFirst($firstHash, \%{$f->{ SyntaxFirstHash }});
		    }
		    delete($firstHash->{$rnm});
		    $changed = 1;
		} else {
		    # literal
		}
	    }
	    if ($lit) {
		delete($nameXprodToDo{$nm});
		$changed = 1;
	    }
	}
    } while $changed;

    # update all syntax objects
    $this->{pass}++;
    foreach $p (@{ $obj->{ prod } }) {
	$p->accept($this);
    }
}

sub visitSyntaxProd {
    my $this = shift;
    my $obj = shift;

    if ($this->{pass}>0) {
	my $expr = $obj->{ expr };
	$expr->accept($this);
	return;
    }

    if ($obj->{ SyntaxFirstHash }) {
	return;
    }

    $this->{ SyntaxFirstCurrProd }{$obj} = $obj;

    my $lhs = $obj->{ lhs };
    my $nm = $lhs->{ name };

    $obj->{ SyntaxFirstHash } = {};
    my $expr = $obj->{ expr };
    $expr->accept($this);
    mergeFirst(\%{$obj->{ SyntaxFirstHash }}, \%{$expr->{ SyntaxFirstHash }});
    delete($this->{ SyntaxFirstCurrProd }{$obj});
}


sub visitSyntaxExpr {
    my $this = shift;
    my $obj = shift;

    my $t;
    if ($this->{pass}>0) {
	$this->update($obj);
	foreach $t (@{ $obj->{ term } }) {
	    $t->accept($this);
	}
	return;
    }
    $obj->{ SyntaxFirstHash } = {};
    $obj->{ SyntaxFirstBegin } = ();
    foreach $t (@{ $obj->{ term } }) {
	$t->accept($this);
	mergeFirst(\%{$obj->{ SyntaxFirstHash }}, \%{$t->{ SyntaxFirstHash }});
	# possible begin of expression
	push(@{$obj->{ SyntaxFirstBegin }}, $t);
    }
}


sub visitSyntaxTerm {
    my $this = shift;
    my $obj = shift;

    my $f;
    if ($this->{pass}>0) {
	$this->update($obj);
	foreach $f (@{ $obj->{ factor } }) {
	    $f->accept($this);
	}
	return;
    }
    $obj->{ SyntaxFirstHash } = {$::EMPTY=>$::EMPTY};
    $obj->{ SyntaxFirstBegin } = ();
    foreach $f (@{ $obj->{ factor } }) {
	last unless (exists($obj->{ SyntaxFirstHash }{$::EMPTY}));
	delete($obj->{ SyntaxFirstHash }{$::EMPTY});
	$f->accept($this);
	mergeFirst(\%{$obj->{ SyntaxFirstHash }}, \%{$f->{ SyntaxFirstHash }});
	# possible begin of term
	push(@{$obj->{ SyntaxFirstBegin }}, $f);
    }
}


sub visitSyntaxName {
    my $this = shift;
    my $obj = shift;

    if ($this->{pass}>0) {
	$this->update($obj);
	return;
    }
    my $name = $obj->{ name };
    $obj->{ SyntaxFirstHash } = {};
    my $p = $this->{ SyntaxFirstProdHash }{$name};
    if (!exists($this->{ SyntaxFirstCurrProd }{$p})) {
	$p->accept($this);
	mergeFirst(\%{$obj->{ SyntaxFirstHash }}, \%{$p->{ SyntaxFirstHash }});
    } else {
	$obj->{ SyntaxFirstHash }{$name} = $obj;
    }
}


sub visitSyntaxLiteral {
    my $this = shift;
    my $obj = shift;

    if ($this->{pass}>0) {
	$this->update($obj);
	return;
    }
    my $literal = $obj->{ literal };
    $obj->{ SyntaxFirstHash } = { $literal => $literal };
}


sub visitSyntaxFinal {
    my $this = shift;
    my $obj = shift;

    if ($this->{pass}>0) {
	$this->update($obj);
	return;
    }
    my $final = $obj->{ final };
    $obj->{ SyntaxFirstHash } = { $final => $final };
}


sub visitSyntaxOptional {
    my $this = shift;
    my $obj = shift;

    my $expr = $obj->{ expr };
    if ($this->{pass}>0) {
	$this->update($obj);
	$expr->accept($this);
	return;
    }
    $expr->accept($this);
    $obj->{ SyntaxFirstHash } = {$::EMPTY=>$::EMPTY};
    mergeFirst(\%{$obj->{ SyntaxFirstHash }}, \%{$expr->{ SyntaxFirstHash }});
}


sub visitSyntaxOptionalList {
    my $this = shift;
    my $obj = shift;

    my $expr = $obj->{ expr };
    if ($this->{pass}>0) {
	$this->update($obj);
	$expr->accept($this);
	return;
    }
    $expr->accept($this);
    $obj->{ SyntaxFirstHash } = {$::EMPTY=>$::EMPTY};
    mergeFirst(\%{$obj->{ SyntaxFirstHash }}, \%{$expr->{ SyntaxFirstHash }});
}


sub visitSyntaxGroup {
    my $this = shift;
    my $obj = shift;

    my $expr = $obj->{ expr };
    if ($this->{pass}>0) {
	$this->update($obj);
	$expr->accept($this);
	return;
    }
    $expr->accept($this);
    $obj->{ SyntaxFirstHash } = {};
    mergeFirst(\%{$obj->{ SyntaxFirstHash }}, \%{$expr->{ SyntaxFirstHash }});
}

sub visitSyntaxNamedExpr {
    my $this = shift;
    my $obj = shift;

    my $expr = $obj->{ expr };
    if ($this->{pass}>0) {
	$this->update($obj);
	$expr->accept($this);
	return;
    }
    $expr->accept($this);
    $obj->{ SyntaxFirstHash } = {};
    mergeFirst(\%{$obj->{ SyntaxFirstHash }}, \%{$expr->{ SyntaxFirstHash }});
}

1;

#################################

require ebnf_parser;
require ebnf_visit;
require ebnf_html;
require util_html;

#################################
package SyntaxFirstPrintHTML;
@ISA = qw ( SyntaxPrintHTML );

sub printProdFirst {
    my $p = shift;
    my $h;
    my $o;
    my $nm = $p->{lhs}{ name };

    printf("%s:\n", $nm);
    $h = \%{$p->{ SyntaxFirstHash }};
    foreach $nm (sort keys %{$h}) {
	$o = $h->{$nm};
	if (ref($o)) {
	    printf("  -> first(%s)\n", $o->{name});
	} else {
	    printf("  -> %s\n", $o);
	}
    }
}

    
sub dumpFirst {
    my $this = shift;
    my $obj = shift;

    UtilityHTML::tag("HR WIDTH=\"100%\"", "\n");
    UtilityHTML::tag("H2");
    UtilityHTML::tag("A NAME=\"toc_first\"", "Lookahead-1 Parser First Token");
    UtilityHTML::tag("/A");
    UtilityHTML::tag("/H2");

    my %alpha;
    my $ch;
    my $s;
    my $lhs;
    my $nm;
    my $p;
    foreach $p (@{ $obj->{ prod } }) {
	$lhs = $p->{ lhs };
	$nm = $lhs->{ name };
	$ch = chr(ord($nm));
	$s = $alpha{$ch};
	#printf("nm='$nm', ch='$ch', s='$s'\n"); 
	if (defined($s) && ($s ne "")) {
	    if ($nm lt $s) {
		$alpha{$ch} = $nm;
	    }
	} else {
	    $alpha{$ch} = $nm;
	}
    }

    UtilityHTML::tag("TABLE BORDER=1 CELLPADDING=2", "\n");
    UtilityHTML::tag("THEAD", "\n");
    UtilityHTML::tag("TR", "\n ");
    foreach $ch ('a'..'z') {
	UtilityHTML::tag("TH");
	$nm = $alpha{$ch};
	if (defined($nm)) {
	    UtilityHTML::tag("A HREF=\"#first_$nm\"", uc($ch));
	    UtilityHTML::tag("/A");
	} else {
	    printf("%s", uc($ch));
	}
	UtilityHTML::tag("/TH", "\n ");
    }
    UtilityHTML::tag("/TR", "\n");
    UtilityHTML::tag("/THEAD", "\n");
    UtilityHTML::tag("/TABLE", "\n");

    UtilityHTML::tag("P");

    my $startsym = $obj->{prod}[0]->{lhs}->{name};
    printf("Start symbol = ");
    UtilityHTML::tag("A HREF=\"#first_$startsym\"", $startsym);
    UtilityHTML::tag("/A");

    UtilityHTML::tag("P");

    UtilityHTML::tag("TABLE BORDER=1 CELLPADDING=2", "\n");
    UtilityHTML::tag("THEAD", "\n");
    UtilityHTML::tag("TR", "\n ");
    UtilityHTML::tag("TH", "Name");
    UtilityHTML::tag("/TH", "\n ");
    UtilityHTML::tag("TH", "First Tokens");
    UtilityHTML::tag("/TH", "\n");
    UtilityHTML::tag("/TR", "\n");
    UtilityHTML::tag("/THEAD", "\n");
    UtilityHTML::tag("TBODY", "\n");

    foreach $p (sort { $a->{lhs}->{name} cmp $b->{lhs}->{name} }
		       @{ $obj->{ prod } }) {
	$p->accept($this);
    }

    ## print html trailer ##
    UtilityHTML::tag("/TBODY", "\n");
    UtilityHTML::tag("/TABLE", "\n");
}


sub create {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {};
    bless($self, $class);
    $self->{title} = shift;
    $self->{mode} = shift;
    $self->{mode} = 0 unless (defined($self->{mode}));

    return $self;
}

sub visitSyntaxRoot {
    my $this = shift;
    my $root = shift;
    
    $root->accept(SyntaxCheck->create());

    my $title = $$this{title};
    printf("$title\n");
    ## print html header ##
    UtilityHTML::tag("HTML", "\n");
    UtilityHTML::tag("HEAD", "\n");
    UtilityHTML::tag("TITLE", $title); UtilityHTML::tag("/TITLE", "\n");
    UtilityHTML::tag("/HEAD", "\n");
    UtilityHTML::tag("BODY", "\n");

    UtilityHTML::tag("H1", $title);
    UtilityHTML::tag("/H1");

    $this->dumpFirst($root, 0);

    UtilityHTML::info();
    UtilityHTML::tag("/BODY", "\n");
    UtilityHTML::tag("/HTML", "\n");
}

sub visitSyntaxProd {
    my $this = shift;
    my $obj = shift;

    my $lhs  = $obj->{ lhs };
    my $firstHash = \%{ $obj->{ SyntaxFirstHash }};
    my $l;
    my $i = 0;

    UtilityHTML::tag("TR", "\n ");
    UtilityHTML::tag("TD VALIGN=TOP");
    $lhs->accept($this);
    UtilityHTML::tag("/TD", "\n ");
    UtilityHTML::tag("TD");
    foreach $l (sort { ($a eq $::EMPTY) ? -1 : ($b eq $::EMPTY) ? 1 : $a cmp $b }
		keys %$firstHash) {
	if ($i > 0) {
	    UtilityHTML::tag("BR", "\n");
	}
	if ($l eq $::EMPTY) {
	    UtilityHTML::code('&oslash;');;
	} else {
	    UtilityHTML::code(UtilityHTML::toHtml($l));
	}
	$i++;
    }
    UtilityHTML::tag("/TD", "\n");
    UtilityHTML::tag("/TR");
}

sub visitSyntaxLhs {
    my $this = shift;
    my $obj = shift;

    my $name = $obj->{ name };
    my $href = "";
    if ($this->{mode} == 1) {
	$href = " HREF=\"#$name\"";
    }
    UtilityHTML::tag("A NAME=\"first_$name\"$href", $name);
    UtilityHTML::tag("/A");
}

1;

