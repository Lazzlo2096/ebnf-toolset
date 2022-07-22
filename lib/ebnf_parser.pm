#!perl -w
#
#   Copyright (c) 2000-2003 Andreas Gieriet
#
#   You may distribute under the terms of the GNU General Public License.
#

# History
# ......01 ag  Original version
# 23.08.01 ag  Named expression added

require 5.001;

#################################
package SyntaxFile;
@ISA = qw ( );

local *File; # file handle
local $fileName = "";
local $lineNr = 0;
local $line = "";
local $token;
local $value;

sub reset {
    $fileName = "";
    $lineNr = 0;
    $line = "";
    $token = "";
    $value = "";
}

sub openFile {
    my $class = shift;
    my $f = shift;
    $fileName = $f;
    
    open(File, "<$f")
		or die("Failed to open '$f' ($!)\n");
}

sub closeFile {
    my $class = shift;
    my $f = $fileName;
    close(File)
		or die("Failed to close '$f' ($!)\n");
}

sub token {
    my $class = shift;
    return $SyntaxFile::token;
}

sub value {
    my $class = shift;
    return $SyntaxFile::value;
}

sub is {
    my $class = shift;
    my @list = @_;
    my $t;
    foreach $t (@list) {
		return 1 if ($t eq $SyntaxFile::token);
    }
    return 0;
}

sub next {
    my $class = shift;
    my $f = $fileName;
    $SyntaxFile::token = "eof";
    $SyntaxFile::value = "";
	
    $SyntaxFile::line =~ s/^\s*//g if ($SyntaxFile::line);
    $SyntaxFile::line =~ s/^\#[^\!].*$//g;   # line comments except meta commands (#!command...)
    $SyntaxFile::line =~ s/^\#$//g;   # line comments
    while (!$SyntaxFile::line) {
		$SyntaxFile::line = <File>;
		$SyntaxFile::lineNr++;
		if (!defined($SyntaxFile::line)) {
			$SyntaxFile::token = "eof";
			$SyntaxFile::value = "";
			return;
		}
		$SyntaxFile::line =~ s/[\s]+$/ /;
		$SyntaxFile::line =~ s/^\s*//g;
		$SyntaxFile::line =~ s/^\#[^\!].*$//g;   # line comments except meta commands (#!command...)
		$SyntaxFile::line =~ s/^\#$//g;   # line comments
    }
	
    my ($ch) = $SyntaxFile::line =~ m/^(.)/;
    if ($ch =~ m/^\#/) {
		$SyntaxFile::token = "command";
		$SyntaxFile::line =~ s/^.(..*?)\s*$//;
		$SyntaxFile::value = $1;
    } elsif ($ch =~ m/^\"/) {
		$SyntaxFile::token = "literal";
		$SyntaxFile::line =~ s/^(\"[^\"]*\")//;
		$SyntaxFile::value = $1;
    } elsif ($ch =~ m/^\'/) {
		$SyntaxFile::token = "literal";
		$SyntaxFile::line =~ s/^(\'[^\']*\')//;
		$SyntaxFile::value = $1;
    } elsif ($ch =~ m/^[\(]/) {
		$SyntaxFile::token = $ch;
		$SyntaxFile::value = $ch;
		$SyntaxFile::line =~ s/^.//;
		if ($SyntaxFile::line =~ m/^\+\s*(\w*)/) {
			$SyntaxFile::token = '(+';
			$SyntaxFile::value = $1;
			$SyntaxFile::line =~ s/^\+\s*\w+//;
		}
    } elsif ($ch =~ m/^[\<\>\)\[\]\{\}\:\.\|]/) {
		$SyntaxFile::token = $ch;
		$SyntaxFile::value = $ch;
		$SyntaxFile::line =~ s/^.//;
    } elsif ($ch =~ m/^[a-z]/) {
		$SyntaxFile::token = "name";
		$SyntaxFile::line =~ s/^([a-zA-Z0-9_]+)//;
		$SyntaxFile::value = $1;
    } elsif ($ch =~ m/^[A-Z]/) {
		$SyntaxFile::token = "final";
		$SyntaxFile::line =~ s/^([a-zA-Z0-9_]+)//;
		$SyntaxFile::value = $1;
    }
    if ($SyntaxFile::value eq "") {
		die("$f:$SyntaxFile::lineNr: Syntax error at '$SyntaxFile::line'\n");
    }
    return;
}

sub assertToken {
    my $class = shift;
    my @exp = @_;
    my $found = 0;
    foreach $e (@exp) {
		return if ($SyntaxFile::token eq $e)
    }
    my $exp = join("', '", @exp);
    my $loc = "$SyntaxFile::fileName:$SyntaxFile::lineNr:";
    if ($SyntaxFile::token eq $SyntaxFile::value) {
		die("$loc Error: expecting '$exp' instead of '$SyntaxFile::token'\n");
    } else {
		die("$loc Error: expecting '$exp' instead of '$SyntaxFile::token' ($SyntaxFile::value)\n");
    }
}

#################################
package SyntaxObject;
@ISA = qw ( );

sub accept {
    die("SyntaxObject::visit() is abstract\n");
}

#################################
package SyntaxRoot;
@ISA = qw ( SyntaxObject );

sub create {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {};
    my $root = bless($self, $class);
    
    SyntaxFile::reset();
	
    my $fileName = shift;
    SyntaxFile->openFile($fileName);
    SyntaxFile->next();
    my $p;
    while (SyntaxFile->token() ne "eof") {
		if (SyntaxFile->is('command')) {
			$self->executeCommand();
			SyntaxFile->next();
		} else {
			$p = SyntaxProd->create($root);
			push(@{ $self->{ prod } }, $p);
		}
    }
    return $self;
}

sub accept {
    my $this = shift;
    my $v = shift;
    $v->visitSyntaxRoot($this);
}

sub executeCommand {
    my $this = shift;
	my $cmd = SyntaxFile->value();
	if ($cmd =~ s/^\!namedexpression\s+(\w+)\s+\"([^\"]+)\"\s*$//) {
		my ($id, $text) = ($1, $2);
		$this->{ namedexpression }{ $id } = $text;
	} else {
		my $loc = "$SyntaxFile::fileName:$SyntaxFile::lineNr:";
		die("$loc: Unknown meta command at '$SyntaxFile::line'\n");
	}
}

#################################
package SyntaxProd;
@ISA = qw ( SyntaxObject );

sub create {
    my $this = shift;
	my $root = shift;
    my $class = ref($this) || $this;
    my $self = {};
    bless($self, $class);
	
    my $lhs = SyntaxLhs->create($root);
    SyntaxFile->assertToken(':');
    SyntaxFile->next();
    my $expr = SyntaxExpr->create($root);
    $self->{ lhs } = $lhs;
    $self->{ expr } = $expr;
    SyntaxFile->assertToken('.');
    SyntaxFile->next();
    
    return $self;
}

sub accept {
    my $this = shift;
    my $v = shift;
    $v->visitSyntaxProd($this);
}

#################################
package SyntaxLhs;
@ISA = qw ( SyntaxObject );

sub create {
    my $this = shift;
	my $root = shift;
    my $class = ref($this) || $this;
    my $self = {};
    bless($self, $class);
    
    SyntaxFile->assertToken('name');
    $self->{name} = SyntaxFile->value();
    SyntaxFile->next();
    return $self;
}

sub accept {
    my $this = shift;
    my $v = shift;
    $v->visitSyntaxLhs($this);
}

#################################
package SyntaxExpr;
@ISA = qw ( SyntaxObject );

sub create {
    my $this = shift;
	my $root = shift;
    my $class = ref($this) || $this;
    my $self = {};
    bless($self, $class);
    
    my $term = SyntaxTerm->create($root);
    if (SyntaxFile->token() eq '|') {
		push(@{ $self->{ term } }, $term);
		while (SyntaxFile->token() eq '|') {
			SyntaxFile->next();
			$term = SyntaxTerm->create($root);
			push(@{ $self->{ term } }, $term);
		}
		return $self;
    }
    return $term;
}

sub accept {
    my $this = shift;
    my $v = shift;
    $v->visitSyntaxExpr($this);
}

#################################
package SyntaxTerm;
@ISA = qw ( SyntaxObject );

sub create {
    my $this = shift;
	my $root = shift;
    my $class = ref($this) || $this;
    my $self = {};
    bless($self, $class);
    
    my $factor = SyntaxFactor->create($root);
    if (SyntaxFile->is('name','literal','final','[','{','(','(+','<')) {
		push(@{ $self->{ factor } }, $factor);
		while (SyntaxFile->is('name','literal','final','[','{','(','(+','<')) {
			$factor = SyntaxFactor->create($root);
			push(@{ $self->{ factor } }, $factor);
		}
		return $self;
    }
    return $factor;
}

sub accept {
    my $this = shift;
    my $v = shift;
    $v->visitSyntaxTerm($this);
}

#################################
package SyntaxFactor;
@ISA = qw ( SyntaxObject );

sub create {
    my $this = shift;
	my $root = shift;
    my $class = ref($this) || $this;
    my $self;
    
    my $t = SyntaxFile->token();
    if ($t eq 'name') {
		$self = SyntaxName->create($root);
    } elsif ($t eq '<') {
		$self = SyntaxName->create($root);
    } elsif ($t eq 'literal') {
		$self = SyntaxLiteral->create($root);
    } elsif ($t eq 'final') {
		$self = SyntaxFinal->create($root);
    } elsif ($t eq '[') {
		$self = SyntaxOptional->create($root);
    } elsif ($t eq '{') {
		$self = SyntaxOptionalList->create($root);
    } elsif ($t eq '(') {
		$self = SyntaxGroup->create($root);
    } elsif ($t eq '(+') {
		$self = SyntaxNamedExpr->create($root);	
    } else {
		SyntaxFile->assertToken('name','literal','final','[','{','(','(+');
    }
    return $self;
}

sub accept {
    my $this = shift;
    my $v = shift;
    $v->visitSyntaxFactor($this);
}

#################################
package SyntaxName;
@ISA = qw ( SyntaxFactor );

sub create {
    my $this = shift;
	my $root = shift;
    my $class = ref($this) || $this;
    my $self = {};
    bless($self, $class);
    
    my $attr = "";
    my $t = SyntaxFile->token();
    if ($t eq '<') {
		SyntaxFile->next();
		SyntaxFile->assertToken('name');
		$attr = SyntaxFile->value();
		SyntaxFile->next();
		SyntaxFile->assertToken('>');
		SyntaxFile->next();
		SyntaxFile->assertToken('name');
    }
	
    $self->{name} = SyntaxFile->value();
    $self->{attr} = $attr;
    SyntaxFile->next();
    
    return $self;
}

sub accept {
    my $this = shift;
    my $v = shift;
    $v->visitSyntaxName($this);
}

#################################
package SyntaxLiteral;
@ISA = qw ( SyntaxFactor );

sub create {
    my $this = shift;
	my $root = shift;
    my $class = ref($this) || $this;
    my $self = {};
    bless($self, $class);
    
    $self->{literal} = SyntaxFile->value();
    SyntaxFile->next();
    
    return $self;
}

sub accept {
    my $this = shift;
    my $v = shift;
    $v->visitSyntaxLiteral($this);
}

#################################
package SyntaxFinal;
@ISA = qw ( SyntaxFactor );

sub create {
    my $this = shift;
	my $root = shift;
    my $class = ref($this) || $this;
    my $self = {};
    bless($self, $class);
    
    $self->{final} = SyntaxFile->value();
    SyntaxFile->next();
    
    return $self;
}

sub accept {
    my $this = shift;
    my $v = shift;
    $v->visitSyntaxFinal($this);
}

#################################
package SyntaxOptional;
@ISA = qw ( SyntaxFactor );

sub create {
    my $this = shift;
	my $root = shift;
    my $class = ref($this) || $this;
    my $self = {};
    bless($self, $class);
    
    SyntaxFile->next();
    my $expr = SyntaxExpr->create($root);
    SyntaxFile->assertToken(']');
    $self->{expr} = $expr;
    SyntaxFile->next();
    
    return $self;
}

sub accept {
    my $this = shift;
    my $v = shift;
    $v->visitSyntaxOptional($this);
}

#################################
package SyntaxOptionalList;
@ISA = qw ( SyntaxFactor );

sub create {
    my $this = shift;
	my $root = shift;
    my $class = ref($this) || $this;
    my $self = {};
    bless($self, $class);
    
    SyntaxFile->next();
    my $expr = SyntaxExpr->create($root);
    SyntaxFile->assertToken('}');
    $self->{expr} = $expr;
    SyntaxFile->next();
    
    return $self;
}

sub accept {
    my $this = shift;
    my $v = shift;
    $v->visitSyntaxOptionalList($this);
}

#################################
package SyntaxGroup;
@ISA = qw ( SyntaxFactor );

sub create {
    my $this = shift;
	my $root = shift;
    my $class = ref($this) || $this;
    my $self = {};
    bless($self, $class);
    
    SyntaxFile->next();
    my $expr = SyntaxExpr->create($root);
    SyntaxFile->assertToken(')');
    $self->{expr} = $expr;
    SyntaxFile->next();
    
    return $self;
}

sub accept {
    my $this = shift;
    my $v = shift;
    $v->visitSyntaxGroup($this);
}

#################################
package SyntaxNamedExpr;
@ISA = qw ( SyntaxFactor );

sub create {
    my $this = shift;
	my $root = shift;
    my $class = ref($this) || $this;
    my $self = {};
    bless($self, $class);
    
	my $name = SyntaxFile->value();;
    $self->{name} = $name;
	$self->{text} = exists($root->{namedexpression}{$name}) ? $root->{namedexpression}{$name} : $name;

    SyntaxFile->next();
    my $expr = SyntaxExpr->create($root);
    SyntaxFile->assertToken(')');
    $self->{expr} = $expr;
    SyntaxFile->next();
    return $self;
}

sub accept {
    my $this = shift;
    my $v = shift;
    $v->visitSyntaxNamedExpr($this);
}


1;
