#!perl -w
#
#   Copyright (c) 2000-2003 Andreas Gieriet
#
#   You may distribute under the terms of the GNU General Public License.
#

#################################

require ebnf_parser;
require ebnf_visit;
require ebnf_xref;
require ebnf_check;
require ebnf_first;
require ebnf_html;

#################################
package SyntaxAnnotation;
@ISA = qw ( SyntaxPrintHTML );

$SyntaxAnnotation::color = "maron";

sub addAmbiguity {
    my $this = shift;

    $this->{ SyntaxAnnotationLastId }++;
    my $ar = SyntaxAmbiguityRecord->create();
    $this->{ SyntaxAnnotationAmbiguity }{$ar} = $ar;

    $ar->{ id } = $this->{ SyntaxAnnotationLastId };
    $ar->{ prod } = $this->{ SyntaxAnnotationCurrProd };
    return $ar;
}

sub isEqualHash {
    my $h1 = shift;
    my $h2 = shift;

    return 0 if ((scalar keys %$h1) != (scalar keys %$h2));
    my $e;
    foreach $e (keys %$h1) {
	return 0 unless (exists($h2->{$e}));
    }
    return 1;
}

sub dumpRef {
    my $this = shift;
    my $obj = shift;
    my $id = $obj->{id};
    UtilityHTML::tag("FONT COLOR=\"$SyntaxAnnotation::color\"");
    UtilityHTML::tag("SUP", "(");
    UtilityHTML::tag("A NAME=\"ref_$id\" HREF=\"#$id\"", "#$id");
    UtilityHTML::tag("/A", ")");
    UtilityHTML::tag("/SUP");
    UtilityHTML::tag("/FONT");
}

sub dumpRecord {
    my $this = shift;
    my $obj = shift;

    my $id = $obj->{id};
    my $p = $obj->{prod};

    my $lh = \%{$obj->{LiteralHash}};
    my $oh = \%{$obj->{ObjectHash}};

    my $note = $obj->{note};

    UtilityHTML::tag("TR", "\n");

    UtilityHTML::tag("TD VALIGN=TOP");
    UtilityHTML::tag("SUP");
    UtilityHTML::tag("A NAME=\"$id\" HREF=\"#ref_$id\"", "#$id");
    UtilityHTML::tag("/A");
    UtilityHTML::tag("/SUP");
    UtilityHTML::tag("/TD", "\n");

    my $nm = $p->{lhs}{name};
    UtilityHTML::tag("TD VALIGN=TOP");
    UtilityHTML::tag("A NAME=\"annot_$nm\" HREF=\"#$nm\"", "$nm");
    UtilityHTML::tag("/A");
    UtilityHTML::tag("/TD", "\n");

    my $l;
    my $i = 0;
    UtilityHTML::tag("TD VALIGN=TOP");
    foreach $l (sort { ($a eq $::EMPTY)? -1 : ($b eq $::EMPTY)? 1 : $a cmp $b }
		keys %{$lh}) {
	$l = $lh->{$l};
	if ($i > 0) {
	    UtilityHTML::tag("BR", "\n");
	}
	if ($l eq $::EMPTY) {
	    UtilityHTML::code('&oslash;');
	} else {
	    UtilityHTML::code(UtilityHTML::toHtml($l));
	}
	$i++;
    }
    UtilityHTML::tag("/TD", "\n");

    my $o;
    $i = 0;
    UtilityHTML::tag("TD VALIGN=TOP");
    if ($note) {
        UtilityHTML::tag("I");
	printf("%s", UtilityHTML::toHtml($note));
        UtilityHTML::tag("/I");
	$i++;
    }
    UtilityHTML::tag("UL", "\n");
    foreach $o (sort keys %{$oh}) {
        UtilityHTML::tag("LI");
	$o = $oh->{$o};
	$o->accept($this);
        UtilityHTML::tag("/LI", "\n");
    }
    UtilityHTML::tag("/UL", "\n");
    UtilityHTML::tag("/TD", "\n");

    UtilityHTML::tag("/TR", "\n");
}

sub dumpToc {
    my $this = shift;
    $this->SUPER::dumpToc();

    UtilityHTML::tag("TR"); UtilityHTML::tag("TD");
    UtilityHTML::tag("A HREF=\"#toc_first\"", "Lookahead-1 Parser First Token"); UtilityHTML::tag("/A");
    UtilityHTML::tag("/TD"); UtilityHTML::tag("/TR");

    UtilityHTML::tag("TR"); UtilityHTML::tag("TD");
    UtilityHTML::tag("A HREF=\"#toc_amb\"", "Lookahead-1 Parser Ambiguities"); UtilityHTML::tag("/A");
    UtilityHTML::tag("/TD"); UtilityHTML::tag("/TR");
}

sub dumpFirst {
    my $this = shift;
    my $root = shift;

    SyntaxFirstPrintHTML->create("Lookahead-1 Parser First Token", 1)->dumpFirst($root);
}

sub dumpAmbiguities {
    my $this = shift;

    UtilityHTML::tag("HR WIDTH=\"100%\"", "\n");
    UtilityHTML::tag("H2");
    UtilityHTML::tag("A NAME=\"toc_amb\"", "Lookahead-1 Parser Ambiguities");
    UtilityHTML::tag("/A");
    UtilityHTML::tag("/H2");

    UtilityHTML::tag("TABLE BORDER=1 CELLPADDING=2 CLASS=\"data\"", "\n");
    UtilityHTML::tag("THEAD", "\n");
    UtilityHTML::tag("TR", "\n ");
    UtilityHTML::tag("TH", "Ref");
    UtilityHTML::tag("/TH", "\n ");
    UtilityHTML::tag("TH", "Production");
    UtilityHTML::tag("/TH", "\n ");
    UtilityHTML::tag("TH", "Ambiguous<BR>Literals/Terminals");
    UtilityHTML::tag("/TH", "\n");
    UtilityHTML::tag("TH", "Can't decide between the following");
    UtilityHTML::tag("/TH", "\n");
    UtilityHTML::tag("/TR", "\n");
    UtilityHTML::tag("/THEAD", "\n");
    UtilityHTML::tag("TBODY", "\n");

    my $ar;
    my $h = \%{$this->{SyntaxAnnotationAmbiguity}};
    foreach $ar (sort { $h->{$a}{id} <=> $h->{$b}{id}; }
		 keys %{ $h } ) {
	$this->dumpRecord($h->{$ar});
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

    $self->{ title } = shift;
    $self->{ SyntaxAnnotationLastId } = 0;
    $self->{ SyntaxAnnotationAmbiguity } = {};
    $self->{ SyntaxAnnotationCurrProd } = undef;
    $self->{ reportEmpty } = 0;
    
    return $self;
}


sub visitSyntaxRoot {
    my $this = shift;
    my $root = shift;

    $root->accept(SyntaxCheck->create());

    my $xref = SyntaxXref->create();
    $this->{ 'xref' } = $xref ;
    $root->accept($xref);

    $root->accept(SyntaxFirst->create());

    my $title = $$this{title};
    ## print html header ##
    UtilityHTML::tag("HTML", "\n");
    UtilityHTML::tag("HEAD", "\n");
    UtilityHTML::tag("TITLE", $title); UtilityHTML::tag("/TITLE", "\n");
	$this->dumpStyle();
    UtilityHTML::tag("/HEAD", "\n");
    UtilityHTML::tag("BODY", "\n");

    UtilityHTML::tag("H1", $title);
    UtilityHTML::tag("/H1");

    UtilityHTML::tag("TABLE");
    UtilityHTML::tag("TBODY");
    $this->dumpToc();
    UtilityHTML::tag("/TBODY");
    UtilityHTML::tag("/TABLE");

    $this->dumpProductions($root);

    $this->dumpVariantsXrefs($root);

    $this->dumpTermXrefs();

    $this->dumpLitXrefs();

    $this->dumpProdXrefs();

    $this->dumpFirst($root);

    $this->dumpAmbiguities();

    UtilityHTML::info();
    UtilityHTML::tag("/BODY", "\n");
    UtilityHTML::tag("/HTML", "\n");
}

sub visitSyntaxProd {
    my $this = shift;
    my $obj = shift;

    my $xref = $this->{ 'xref' };
    my $hash = \%{ $xref->{ prodHash } };

    $this->{ SyntaxAnnotationCurrProd } = $obj;

    my $lhs  = $obj->{ lhs };
    my $expr = $obj->{ expr };

    UtilityHTML::tag("TR", "\n ");
    UtilityHTML::tag("TD VALIGN=TOP");
    $lhs->accept($this);
    my $ar;
    if ($this->{reportEmpty}) {
	if (exists($obj->{SyntaxFirstHash}{$::EMPTY})) {
	    $ar = $this->addAmbiguity();
	    $ar->{ LiteralHash }{$::EMPTY}=$::EMPTY;
	    $ar->{ note } = "May be empty: greedy algorithm may fail";
	    $this->dumpRef($ar);
	}
    }
    ### not used info
    if (!exists($hash->{$lhs->{name}})) {
	printf(" ");
        UtilityHTML::tag("I", "(not used)");
        UtilityHTML::tag("/I");
    }

    UtilityHTML::tag("/TD", "\n ");
    UtilityHTML::tag("TD");
    $this->{ 'topExpr' } = $expr;
    $expr->accept($this);
    $this->{ 'topExpr' } = undef;
    UtilityHTML::tag("/TD", "\n");
    UtilityHTML::tag("/TR");
}

sub visitSyntaxExpr {
    my $this = shift;
    my $obj = shift;

    my $t;
    my $ta = $obj->{ term };
    
    my %amb;
    foreach $t (@$ta) {
	$amb{$t} = {};
    }

    my $lh = \%{$obj->{SyntaxFirstHash}};
    my $l;
    my %affected = ();
    my %ambiguous = ();
    my $hash;
    foreach $l (keys %{$lh}) {
	$l = $lh->{$l};
	if ($l ne $::EMPTY) {
	    $hash = {};
	    $affected{$l} = $hash;
	    foreach $t (@$ta) {
		if (exists($t->{SyntaxFirstHash}{$l})) {
		    $hash->{$t}=$t;
		}
	    }
	}
    }
    my $ar;
    my $rec;
    my $eq = 0;
    foreach $l (keys %$lh) {
	$l = $lh->{$l};
	$hash = \%{$affected{$l}};
	if ((scalar keys %$hash) > 1) {
            $eq = 0;
	    foreach $rec (keys %{$ambiguous}) {
		$rec = $ambiguous->{$rec};
		if (isEqualHash($rec->{ObjectHash}, \%{$hash})) {
		    $rec->{LiteralHash}{$l}=$l;
		    $eq = 1;
		}
	    }
	    if (!$eq) {
		$ar = $this->addAmbiguity();
		$ar->{LiteralHash}{$l}=$l;
		foreach $t (keys %$hash) {
		    $t = $hash->{$t};
		    $ar->{ObjectHash}{$t}=$t;
		    $amb{$t}{$ar}=$ar;
		}
		$ambiguous->{$ar}=$ar;
	    }
	}
    }

    my $i;
    if (scalar(@{ $obj->{ term } }) > 1) {
	if ($this->isTopExpr($obj)) {
	    UtilityHTML::tag("UL", "\n");
	    foreach $t (@{ $obj->{ term } }) {
	        UtilityHTML::tag("LI");
		$t->accept($this);
		foreach $ar (sort { $amb{$t}->{$a}{id} <=> $amb{$t}->{$b}{id} }
			     keys %{$amb{$t}}) {
		    $this->dumpRef($amb{$t}->{$ar});
		}
		UtilityHTML::tag("/LI", "\n");
	    }
	    UtilityHTML::tag("/UL", "\n");
	} else {
	    $i = 0;
	    foreach $t (@{ $obj->{ term } }) {
		if ($i > 0) {
		    printf(" | ");
		}
		$t->accept($this);
		foreach $ar (sort { $amb{$t}->{$a}{id} <=> $amb{$t}->{$b}{id} }
			     keys %{$amb{$t}}) {
		    $this->dumpRef($amb{$t}->{$ar});
		}
		$i++;
	    }
	}
    } else {
	$t = @{ $obj->{ term } }[0];
	$t->accept($this);
	foreach $ar (sort { $amb{$t}->{$a}{id} <=> $amb{$t}->{$b}{id} }
		     keys %{$amb{$t}}) {
	    $this->dumpRef($amb{$t}->{$ar});
	}
    }
}


sub visitSyntaxTerm {
    my $this = shift;
    my $obj = shift;

    my $f;
    my $fa = $obj->{ factor };
    
    my %amb;
    foreach $f (@$fa) {
	$amb{$f} = {};
    }


    # get potential ambiguous sub-sequences
    my @seq;
    my $lh;
    my $list = [];
    foreach $f (@$fa) {
	$lh = \%{$f->{SyntaxFirstHash}};
	push(@$list, $f);
	if (!exists($lh->{$::EMPTY})) {
	    if ((scalar @$list) > 1) {
		push(@seq, $list);
	    }
	    $list = [];
	}
    }
    if ((scalar @$list) > 1) {
	push(@seq, $list);
    }

    my $l;
    my %affected = ();
    my %ambiguous = ();
    my $hash;
    my $flh;
    my $ar;
    foreach $list (@seq) {
	$lh = {};
	foreach $f (@$list) {
	    $flh = \%{$f->{SyntaxFirstHash}};
	    map { $lh->{$_} = $flh->{$_} } keys %{$flh};
	}
	%affected = ();
	%ambiguous = ();
	foreach $l (keys %{$lh}) {
	    $l = $lh->{$l};
	    if ($l ne $::EMPTY) {
		$hash = {};
		$affected{$l} = $hash;
		foreach $f (@$list) {
		    if (exists($f->{SyntaxFirstHash}{$l})) {
			$hash->{$f}=$f;
		    }
		}
	    }
	}
	my $rec;
	my $eq = 0;
	foreach $l (keys %$lh) {
	    $l = $lh->{$l};
	    $hash = \%{$affected{$l}};
	    if ((scalar keys %$hash) > 1) {
		$eq = 0;
		foreach $rec (keys %{$ambiguous}) {
		    $rec = $ambiguous->{$rec};
		    if (isEqualHash($rec->{ObjectHash}, \%{$hash})) {
			$rec->{LiteralHash}{$l}=$l;
			$eq = 1;
		    }
		}
		if (!$eq) {
		    $ar = $this->addAmbiguity();
		    $ar->{LiteralHash}{$l}=$l;
		    foreach $f (keys %$hash) {
			$f = $hash->{$f};
			$ar->{ObjectHash}{$f}=$f;
			$amb{$f}{$ar}=$ar;
		    }
		    $ambiguous->{$ar}=$ar;
		}
	    }
	}
    }

    foreach $f (@$fa) {
	$f->accept($this);
	foreach $ar (sort { $amb{$f}->{$a}{id} <=> $amb{$f}->{$b}{id} }
		     keys %{$amb{$f}}) {
	    $this->dumpRef($amb{$f}->{$ar});
	}
    }
}

1;

#################################

package SyntaxAmbiguityRecord;
@ISA = qw ( );

sub create {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {};
    bless($self, $class);
    
    $self->{ id } = "";
    $self->{ prod } = undef;
    $self->{ LiteralHash } = {};
    $self->{ ObjectHash } = {};
    $self->{ note } = "";

    return $self;
}

1;

