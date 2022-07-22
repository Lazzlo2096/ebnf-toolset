#!perl -w
#
#   Copyright (c) 2000-2003 Andreas Gieriet
#
#   You may distribute under the terms of the GNU General Public License.
#

require 5.001;
require ebnf_parser;
require ebnf_html;

my $file = shift;
my $title = shift;
$title = "EBNF Syntax" unless defined($title);

die("usage: $0 ebnf-file > html-file\n") unless $file;

SyntaxRoot->create($file)->accept(SyntaxPrintHTML->create($title));

exit 0;


