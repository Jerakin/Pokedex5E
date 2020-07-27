local M = {}

M.regions = {OTHER=0, KANTO=1, JOHTO=2, HOENN=3, SINNOH=4, UNOVA=5, KALOS=6}



-- The maximum index in a given region
M.max_index = {
	[M.regions.KANTO]=151, 
	[M.regions.JOHTO]=251,
	[M.regions.HOENN]=386, 
	[M.regions.SINNOH]=493, 
	[M.regions.UNOVA]=649,
	[M.regions.KALOS]=721,
	[M.regions.OTHER]=9999999
}

-- This is the order that the regions comes in OTHER should always be last
M.order = {
	M.regions.KANTO,
	M.regions.JOHTO,
	M.regions.HOENN,
	M.regions.SINNOH,
	M.regions.UNOVA,
	M.regions.KALOS,
	M.regions.OTHER
}

M.total_regions = #M.order - 1

return M