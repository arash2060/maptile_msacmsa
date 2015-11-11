* import_msacmsa_shapefile.do: imports  shapefile into Stata format, cleaning the output files

*** Version history:

* 11-11-2015, Arash Farahani



/*******************************

** INFORMATION ABOUT MSACMSA Files **
The shape files were taken frim NHGIS.
nhgis0003_shapefile_tl2000_us_state_2000.zip
nhgis0001_shapefile_tl2000_us_msa_cmsa_2000.zip

MSA_CMSA and State files were first merged using ARCGIS to create a shapefile of MSA's that includes state borders.
The coordinate system of the resulting file was projected to WGS1984 coordinate system.
** INPUT FILES ** 
- US_msacmsa_2000.shp
- US_state_2000.shp
	Provided by NHGSI.
- ARCGIS output: US_msa_state_2000_merge.shp
- reshape_us.do

** OUTPUT FILES **
- msacmsa_database_clean.dta
- msacmsa_coords_clean.dta

*******************************/

global root "C:\Users\mashhad2\Dropbox\Research\Research A\Infrastructure\Analysis\Data\maptile"
global raw "$root\raw_data"
global out "$root\map_shapefiles"
global code "$root\map_shapefiles_creation_code"


*** Step 1: Unzip & convert shape file to dta
cd "$raw"
unzipfile "$raw\US_msa_state_2000_merge", replace

shp2dta using "$raw/US_msa_state_2000_Merge", database("$out\msacmsa_database") ///
	coordinates("$out\msacmsa_coords") genid(id) replace


*** Step 2: Clean database
use "$out\msacmsa_database", clear
rename (MSACMSA NHGISST) (msa state)
destring msa state, replace
save "$out\msacmsa_database_clean", replace

*** Step 3: Clean coordinates
use "$out/msacmsa_coords", clear
gen id=_ID
merge m:1 id using "$out\msacmsa_database_clean", assert(1 3) keep(3) nogen

** Generate state variable for AK and HI
gen statefips=2 if inrange(msa,380,380) | inrange(state,20,20)
replace statefips=15 if inlist(msa,3320,3320) | inrange(state,150,150)

** Reshape U.S.
do "$code/reshape_us.do"

** Save coords dataset
keep _ID _X _Y
sort _ID, stable
save "$out/msacmsa_coords_clean", replace

*** Step 4: Clean up extra files
erase "$out/msacmsa_database.dta"
erase "$out/msacmsa_coords.dta"
