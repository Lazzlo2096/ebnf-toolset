##############################################################
#
# Copyright (C) 2001-2003 by Andreas Gieriet, eXternsSoft GmbH
#
# Author: Andreas Gieriet
# Date: 2001/08/20
# Keywords: ebnf html annotation
#
# History:
# 2001/08/20 AG  0.1 re-installation (access for everybody)
# 2003/01/18 AG  0.2 make public
#
#
##############################################################

if ($?EBNFROOT == 0) then
	setenv EBNFROOT "/opt/ebnf"

	if ($?PERL5LIB == 0) then
		setenv PERL5LIB "${EBNFROOT}/lib"
	else
		setenv PERL5LIB "${PERL5LIB}:${EBNFROOT}/lib"
	endif

	set path = ($path $EBNFROOT/bin)

	setenv MANPATH "${MANPATH}:${EBNFROOT}/man"

endif

