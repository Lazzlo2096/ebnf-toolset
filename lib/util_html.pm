#!perl -w
#
#   Copyright (c) 2000-2003 Andreas Gieriet
#
#   You may distribute under the terms of the GNU General Public License.
#

package UtilityHTML;
@ISA = ();

sub info {
    my $prog = $0;
    $prog =~ s/^.*\///g;
    my $info = "Created with $prog (<a href=\"mailto:andreas.gieriet\@externsoft.ch?subject=Request:%20EBNF%20Tools\">andreas.gieriet\@externsoft.ch</a>)";
    tag("HR", "\n");
    tag("FONT SIZE=-2", $info);
    tag("/Font", "\n");
}

sub toHtml {
    my $s = shift;
    my $lt = '&lt;';
    my $gt = '&gt;';
    my $qu = '&quot;';
    my $amp = '&amp;';
    $s =~ s/[&]/$amp/gx;
    $s =~ s/</$lt/gx;
    $s =~ s/>/$gt/gx;
    $s =~ s/"/$qu/gx;
    return $s;
}

sub tag {
    printf("\<%s\>", shift);
    my $s;
    foreach $s (@_) {
	printf("%s", $s);
    }
}

sub code {
    tag("B");
    tag("CODE");
    printf("%s", shift);
    tag("/CODE");
    tag("/B");
}

1;
