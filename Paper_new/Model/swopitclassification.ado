capture program drop swopitclassification
program swopitclassification, rclass
	version 14
	syntax
	mata: SWOPITclassification(SWOPITMODEL)
end
	