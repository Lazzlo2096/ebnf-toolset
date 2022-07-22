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
require ebnf_xref;
require ebnf_check;
require util_html;

#################################
package SyntaxPrintHTML;
@ISA = qw ( SyntaxWalk );

sub create {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = { indent => 20,
				 title => shift,
				 'xref' => undef,
				 'topExpr' => undef };
    bless($self, $class);
	
    return $self;
}

sub isTopExpr {
    my $this = shift;
    my $obj  = shift;
    my $topExpr = $this->{ 'topExpr' };
    return 1 if ($topExpr && ($topExpr == $obj));
    return 0;
}

sub dumpUsedIn {
    my $this = shift;
    my @list = @_;
    my $n;
    my $i = 0;
    foreach $n (sort @list) {
		if ($i > 0) {
			printf(" /\n");
		}
		UtilityHTML::tag("A HREF=\"#$n\"", $n);
		UtilityHTML::tag("/A");
		$i++;
    }
    printf("\n");
}

sub dumpVariantExpression {
    my $this = shift;
	my $expr = shift;
	my $variant = shift;

	my $first = 1;
	foreach $e (@$expr) {
		if ($first) {
			$first = 0;
		} else {
			UtilityHTML::tag("/BR", "\n");
		}
		printf("... ");
		$e->accept($this);
		printf(" ...");
	}
	printf("\n");
}

sub dumpToc {
    my $this = shift;
	my $root = shift;
    UtilityHTML::tag("TR"); UtilityHTML::tag("TD");
    UtilityHTML::tag("A HREF=\"#toc_prod\"", "Syntax Productions"); UtilityHTML::tag("/A");
    UtilityHTML::tag("/TD"); UtilityHTML::tag("/TR");
	UtilityHTML::tag("TR"); UtilityHTML::tag("TD");
	UtilityHTML::tag("A HREF=\"#toc_variants\"", "Variants"); UtilityHTML::tag("/A");
	UtilityHTML::tag("/TD"); UtilityHTML::tag("/TR");
    UtilityHTML::tag("TR"); UtilityHTML::tag("TD");
    UtilityHTML::tag("A HREF=\"#toc_term\"", "Terminals"); UtilityHTML::tag("/A");
    UtilityHTML::tag("/TD"); UtilityHTML::tag("/TR");
    UtilityHTML::tag("TR"); UtilityHTML::tag("TD");
    UtilityHTML::tag("A HREF=\"#toc_lit\"", "Literals"); UtilityHTML::tag("/A");
    UtilityHTML::tag("/TD"); UtilityHTML::tag("/TR");
    UtilityHTML::tag("TR"); UtilityHTML::tag("TD");
    UtilityHTML::tag("A HREF=\"#toc_xref\"", "Production Cross Reference"); UtilityHTML::tag("/A");
    UtilityHTML::tag("/TD"); UtilityHTML::tag("/TR");
}

sub dumpStyle {
    my $this = shift;

	UtilityHTML::tag("STYLE TYPE=\"text/css\"", "\n");
	print <<STYLE;
body {
  font-family:Helvetica,Helv;
}
table.data {
	border-width: 2px;
	border-spacing: 2px;
	border-style: outset;
	border-color: black;
	border-collapse: collapse;
	background-color: white;
}
table.data th {
	border-width: 1px;
	padding: 2px;
	border-style: inset;
	border-color: black;
	background-color: lightgray;
}
table.data td {
	border-width: 1px;
	padding: 2px;
	border-style: inset;
	border-color: black;
	background-color: white;
}
STYLE
	UtilityHTML::tag("/STYLE");
}

sub dumpProductions {
    my $this = shift;
    my $obj = shift;
	
    UtilityHTML::tag("HR WIDTH=\"100%\"", "\n");
    UtilityHTML::tag("H2");
    UtilityHTML::tag("A NAME=\"toc_prod\"", "Syntax Productions");
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
	
    UtilityHTML::tag("TABLE BORDER=1 CELLPADDING=2 CLASS=\"data\"", "\n");
    UtilityHTML::tag("THEAD", "\n");
    UtilityHTML::tag("TR", "\n ");
    foreach $ch ('a'..'z') {
		$nm = $alpha{$ch};
		if (defined($nm)) {
			UtilityHTML::tag("TH");
			UtilityHTML::tag("A HREF=\"#$nm\"", uc($ch));
			UtilityHTML::tag("/A");
			UtilityHTML::tag("/TH", "\n ");
		} else {
			UtilityHTML::tag("TD");
			printf("%s", uc($ch));
			UtilityHTML::tag("/TD", "\n ");
		}
    }
    UtilityHTML::tag("/TR", "\n");
    UtilityHTML::tag("/THEAD", "\n");
    UtilityHTML::tag("/TABLE", "\n");
	
    UtilityHTML::tag("P");
	
    my $startsym = $obj->{prod}[0]->{lhs}->{name};
    UtilityHTML::tag("TABLE BORDER=1 CELLPADDING=2 CLASS=\"data\"", "\n");
    UtilityHTML::tag("TBODY", "\n");
    UtilityHTML::tag("TR");
    UtilityHTML::tag("TH");
    UtilityHTML::tag("A NAME=\"xref_$startsym\" HREF=\"#$startsym\"", "Start Symbol ($startsym)");
    UtilityHTML::tag("/TH");
    UtilityHTML::tag("/TR", "\n");
    UtilityHTML::tag("/TBODY", "\n");
    UtilityHTML::tag("/TABLE", "\n");

    UtilityHTML::tag("P");
	
    UtilityHTML::tag("TABLE BORDER=1 CELLPADDING=2 CLASS=\"data\"", "\n");
    UtilityHTML::tag("THEAD", "\n");
    UtilityHTML::tag("TR", "\n ");
    UtilityHTML::tag("TH", "Name");
    UtilityHTML::tag("/TH", "\n ");
    UtilityHTML::tag("TH", "Production");
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

sub dumpProdXrefs {
    my $this = shift;
    my $xref = $this->{ 'xref' };
	
    my $hash = \%{ $xref->{ prodHash } };
	
    UtilityHTML::tag("HR WIDTH=\"100%\"", "\n");
    UtilityHTML::tag("H2");
    UtilityHTML::tag("A NAME=\"toc_xref\"", "Production Cross Reference");
    UtilityHTML::tag("/A");
    UtilityHTML::tag("/H2");
	
    UtilityHTML::tag("TABLE BORDER=1 CELLPADDING=2 CLASS=\"data\"", "\n");
    UtilityHTML::tag("THEAD", "\n");
    UtilityHTML::tag("TR", "\n ");
    UtilityHTML::tag("TH", "Production");
    UtilityHTML::tag("/TH", "\n ");
    UtilityHTML::tag("TH", "Used in");
    UtilityHTML::tag("/TH", "\n");
    UtilityHTML::tag("/TR", "\n");
    UtilityHTML::tag("/THEAD", "\n");
    UtilityHTML::tag("TBODY", "\n");
	
    my $t;
    foreach $t (sort keys %$hash) {
		UtilityHTML::tag("TR");
		UtilityHTML::tag("TD VALIGN=TOP", "\n");
		UtilityHTML::tag("A NAME=\"xref_$t\" HREF=\"#$t\"", $t);
		UtilityHTML::tag("/A");
		UtilityHTML::tag("/TD");
		UtilityHTML::tag("TD");
		$this->dumpUsedIn(keys %{ $hash->{$t} });
		UtilityHTML::tag("/TD");
		UtilityHTML::tag("/TR", "\n");
    }
	
    my $list = \@{ $xref->{ unusedProd }};
    foreach $t (sort @$list) {
		$t = $t->{lhs}{name};
		UtilityHTML::tag("TR");
		UtilityHTML::tag("TD VALIGN=TOP", "\n");
		UtilityHTML::tag("A NAME=\"xref_$t\" HREF=\"#$t\"", $t);
		UtilityHTML::tag("/A");
		UtilityHTML::tag("/TD");
		UtilityHTML::tag("TD");
		UtilityHTML::tag("I", "Not used in any production");
		UtilityHTML::tag("/I");
		UtilityHTML::tag("/TD");
		UtilityHTML::tag("/TR", "\n");
    }
	
    ## print html trailer ##
    UtilityHTML::tag("/TBODY", "\n");
    UtilityHTML::tag("/TABLE", "\n");
}

sub dumpTermXrefs {
    my $this = shift;
    my $xref = $this->{ 'xref' };
	
    my $hash = \%{ $xref->{ termHash } };
	
    UtilityHTML::tag("HR WIDTH=\"100%\"", "\n");
    UtilityHTML::tag("H2");
    UtilityHTML::tag("A NAME=\"toc_term\"", "Terminals");
    UtilityHTML::tag("/A");
    UtilityHTML::tag("/H2");
	
    UtilityHTML::tag("TABLE BORDER=1 CELLPADDING=2 CLASS=\"data\"", "\n");
    UtilityHTML::tag("THEAD", "\n");
    UtilityHTML::tag("TR", "\n ");
    UtilityHTML::tag("TH", "Terminal");
    UtilityHTML::tag("/TH", "\n ");
    UtilityHTML::tag("TH", "Used in");
    UtilityHTML::tag("/TH", "\n");
    UtilityHTML::tag("/TR", "\n");
    UtilityHTML::tag("/THEAD", "\n");
    UtilityHTML::tag("TBODY", "\n");
	
    my $t;
    foreach $t (sort keys %$hash) {
		UtilityHTML::tag("TR");
		UtilityHTML::tag("TD VALIGN=TOP", "\n");
		UtilityHTML::tag("CODE", $t);
		UtilityHTML::tag("/CODE", "\n");
		UtilityHTML::tag("/TD");
		UtilityHTML::tag("TD");
		$this->dumpUsedIn(keys %{ $hash->{$t} });
		UtilityHTML::tag("/TD");
		UtilityHTML::tag("/TR", "\n");
    }
	
    ## print html trailer ##
    UtilityHTML::tag("/TBODY", "\n");
    UtilityHTML::tag("/TABLE", "\n");
}

sub dumpLitXrefs {
    my $this = shift;
    my $xref = $this->{ 'xref' };
	
    my $hash = \%{ $xref->{ litHash } };
	
    UtilityHTML::tag("HR WIDTH=\"100%\"", "\n");
    UtilityHTML::tag("H2");
    UtilityHTML::tag("A NAME=\"toc_lit\"", "Literals");
    UtilityHTML::tag("/A");
    UtilityHTML::tag("/H2");
	
    UtilityHTML::tag("TABLE BORDER=1 CELLPADDING=2 CLASS=\"data\"", "\n");
    UtilityHTML::tag("THEAD", "\n");
    UtilityHTML::tag("TR", "\n ");
    UtilityHTML::tag("TH", "Literal");
    UtilityHTML::tag("/TH", "\n ");
    UtilityHTML::tag("TH", "Used in");
    UtilityHTML::tag("/TH", "\n");
    UtilityHTML::tag("/TR", "\n");
    UtilityHTML::tag("/THEAD", "\n");
    UtilityHTML::tag("TBODY", "\n");
	
    my $t;
    my $p;
    my $l;
    my $lt = '&lt;';
    my $gt = '&gt;';
    my %lc = ();
    my %la = ();
    foreach $t (keys %$hash) {
		$l = $t;
		$l =~ s/^.(.*).$/$1/g;
		if ($l =~ m/^[a-zA-Z0-9]/) {
			$la{$l} = $t;
		} else {
			$lc{$l} = $t;
		}
    }
    foreach $l (sort keys %lc) {
		UtilityHTML::tag("TR");
		UtilityHTML::tag("TD VALIGN=TOP", "\n");
		$t = $lc{$l};
		UtilityHTML::tag("CODE", UtilityHTML::toHtml($l));
		UtilityHTML::tag("/CODE", "\n");
		UtilityHTML::tag("/TD");
		UtilityHTML::tag("TD");
		$this->dumpUsedIn(keys %{ $hash->{$t} });
		UtilityHTML::tag("/TD");
		UtilityHTML::tag("/TR", "\n");
    }
    foreach $l (sort { lc($a) cmp lc($b) } keys %la) {
		UtilityHTML::tag("TR");
		UtilityHTML::tag("TD VALIGN=TOP", "\n");
		$t = $la{$l};
		UtilityHTML::tag("CODE", UtilityHTML::toHtml($l));
		UtilityHTML::tag("/CODE", "\n");
		UtilityHTML::tag("/TD");
		UtilityHTML::tag("TD");
		$this->dumpUsedIn(keys %{ $hash->{$t} });
		UtilityHTML::tag("/TD");
		UtilityHTML::tag("/TR", "\n");
    }
	
    ## print html trailer ##
    UtilityHTML::tag("/TBODY", "\n");
    UtilityHTML::tag("/TABLE", "\n");
}

sub dumpVariantsXrefs {
    my $this = shift;
	my $root = shift;
    my $xref = $this->{ 'xref' };

	$hash = \%{ $xref->{ variantsHash } };
	
    UtilityHTML::tag("HR WIDTH=\"100%\"", "\n");
    UtilityHTML::tag("H2");
    UtilityHTML::tag("A NAME=\"toc_variants\"", "Variants");
    UtilityHTML::tag("/A");
    UtilityHTML::tag("/H2");
	
	if (scalar(keys %$hash) == 0) {
		printf("none\n");
		return;
	}


    UtilityHTML::tag("TABLE BORDER=1 CELLPADDING=2 CLASS=\"data\"", "\n");
    UtilityHTML::tag("THEAD", "\n");
    UtilityHTML::tag("TR", "\n ");
    UtilityHTML::tag("TH", "Variant");
    UtilityHTML::tag("/TH", "\n ");
    UtilityHTML::tag("TH", "Used in");
    UtilityHTML::tag("/TH", "\n");
    UtilityHTML::tag("TH", "Variant Expressions");
    UtilityHTML::tag("/TH", "\n");
    UtilityHTML::tag("/TR", "\n");
    UtilityHTML::tag("/THEAD", "\n");
    UtilityHTML::tag("TBODY", "\n");

    my $t;
    foreach $t (sort keys %$hash) {
		my $txt = exists($root->{namedexpression}{$t}) ? $root->{namedexpression}{$t} : $t;
		my $vprod = $hash->{$t};
		my @vprod = keys %$vprod;
		my $rowspan = scalar(@vprod);
		UtilityHTML::tag("TR");
		UtilityHTML::tag("TH NOWRAP=1 VALIGN=TOP ROWSPAN=$rowspan", "\n");
		UtilityHTML::tag("A NAME=\"variant_$t\"", $txt);
		UtilityHTML::tag("/A");
		UtilityHTML::tag("/TH");
		my $first = 1;
		foreach $prod (sort @vprod) {
			if ($first) {
				$first = 0;
			} else {
				UtilityHTML::tag("/TR");
				UtilityHTML::tag("TR");
			}
			UtilityHTML::tag("TD");
			$this->dumpUsedIn($prod);
			UtilityHTML::tag("/TD");
			UtilityHTML::tag("TD");
			my $expr = $vprod->{ $prod };
			$this->dumpVariantExpression($expr, $t);
			UtilityHTML::tag("/TD");
		}
		UtilityHTML::tag("/TR", "\n");
    }
	
    ## print html trailer ##
    UtilityHTML::tag("/TBODY", "\n");
    UtilityHTML::tag("/TABLE", "\n");
}

sub visitSyntaxRoot {
    my $this = shift;
    my $root = shift;
    
    $root->accept(SyntaxCheck->create());
	
    my $xref = SyntaxXref->create();
    $this->{ 'xref' } = $xref ;
    $root->accept($xref);
	
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
    $this->dumpToc($root);
    UtilityHTML::tag("/TBODY");
    UtilityHTML::tag("/TABLE");
	
    $this->dumpProductions($root);
	
    $this->dumpVariantsXrefs($root);
	
    $this->dumpTermXrefs();
	
    $this->dumpLitXrefs();
	
    $this->dumpProdXrefs();
	
    UtilityHTML::info();
    UtilityHTML::tag("/BODY", "\n");
    UtilityHTML::tag("/HTML", "\n");
}

sub visitSyntaxProd {
    my $this = shift;
    my $obj = shift;
	
    my $xref = $this->{ 'xref' };
    my $hash = \%{ $xref->{ prodHash } };
	
    my $lhs  = $obj->{ lhs };
    my $expr = $obj->{ expr };
	
    UtilityHTML::tag("TR", "\n ");
    UtilityHTML::tag("TD VALIGN=TOP");
    $lhs->accept($this);
	
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


sub visitSyntaxLhs {
    my $this = shift;
    my $obj = shift;
	
    my $name = $obj->{ name };
    UtilityHTML::tag("A HREF=\"#xref_$name\" NAME=\"$name\"", $name);
    UtilityHTML::tag("/A");
}


sub visitSyntaxExpr {
    my $this = shift;
    my $obj = shift;
	
    my $t;
    if (scalar(@{ $obj->{ term } }) > 1) {
		if ($this->isTopExpr($obj)) {
			UtilityHTML::tag("UL", "\n");
			foreach $t (@{ $obj->{ term } }) {
				UtilityHTML::tag("LI");
				$t->accept($this);
				UtilityHTML::tag("/LI", "\n");
			}
			UtilityHTML::tag("/UL", "\n");
		} else {
			my $i = 0;
			foreach $t (@{ $obj->{ term } }) {
				if ($i > 0) {
					printf(" | ");
				}
				$t->accept($this);
				$i++;
			}
		}
    } else {
		$t = @{ $obj->{ term } }[0];
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


sub visitSyntaxName {
    my $this = shift;
    my $obj = shift;
	
    my $name = $obj->{ name };
    my $attr = $obj->{ attr };
    printf(" ");
    if ($attr ne "") {
		UtilityHTML::tag("I", "$attr"."_");
		UtilityHTML::tag("/I");
    }
    UtilityHTML::tag("A HREF=\"#$name\"", $name);
    UtilityHTML::tag("/A");
}


sub visitSyntaxLiteral {
    my $this = shift;
    my $obj = shift;
	
    my $literal = $obj->{ literal };
    printf(" ");
    UtilityHTML::code(UtilityHTML::toHtml($literal));
}


sub visitSyntaxFinal {
    my $this = shift;
    my $obj = shift;
	
    my $final = $obj->{ final };
    printf(" ");
    UtilityHTML::code($final);
}


sub visitSyntaxOptional {
    my $this = shift;
    my $obj = shift;
	
    my $expr = $obj->{ expr };
    printf(" [");
    $expr->accept($this);
    printf(" ]");
}


sub visitSyntaxOptionalList {
    my $this = shift;
    my $obj = shift;
	
    my $expr = $obj->{ expr };
    printf(" {");
    $expr->accept($this);
    printf(" }");
}


sub visitSyntaxGroup {
    my $this = shift;
    my $obj = shift;
	
    my $expr = $obj->{ expr };
    printf(" (");
    $expr->accept($this);
    printf(" )");
}

sub visitSyntaxNamedExpr {
    my $this = shift;
    my $obj = shift;
	
    my $id = "variant_" . $obj->{name};
    my $txt = $obj->{text};
    my $expr = $obj->{ expr };
	if (ref($expr) eq "SyntaxTerm")
	{
		printf(" (");
		$expr->accept($this);
		printf(" )");
	}
	else
	{
		$expr->accept($this);
	}

    UtilityHTML::tag("SUP", "(");
    UtilityHTML::tag("A HREF=\"#$id\"", "$txt");
    UtilityHTML::tag("/A", ")");
    UtilityHTML::tag("/SUP");
}


1;

