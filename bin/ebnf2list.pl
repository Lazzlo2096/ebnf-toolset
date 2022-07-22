#!perl -w
#
#   Copyright (c) 2000-2003 Andreas Gieriet
#
#   You may distribute under the terms of the GNU General Public License.
#

require 5.001;
require ebnf_parser;
require ebnf_list;

my $file = shift;

die("usage: $0 ebnf-file > text-file\n") unless $file;

my $root = SyntaxRoot->create($file);
$root->accept(SyntaxList->create());

exit 0;


