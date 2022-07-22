#!perl -w
#
#   Copyright (c) 2000-2003 Andreas Gieriet
#
#   You may distribute under the terms of the GNU General Public License.
#

require ebnf_parser;
require ebnf_visit;

#################################
package SyntaxPrintLit;
@ISA = qw ( SyntaxWalk );

sub create {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = { };
    bless($self, $class);
    
    return $self;
}

sub visitSyntaxLiteral {
    my $this = shift;
    my $obj = shift;

    my $literal = $obj->{ literal };
    printf("%s\n", $literal);
}


sub visitSyntaxFinal {
    my $this = shift;
    my $obj = shift;

    my $final = $obj->{ final };
    printf("%s\n", $final);
}


1;
