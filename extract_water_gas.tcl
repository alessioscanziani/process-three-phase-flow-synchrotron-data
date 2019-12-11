# Always use double slash

# paths 

# input 
# segmented files
set seg_file "E:\\Diamond19\\processing\\DK_GI\\seg"
# mask
set mask "E:\\Diamond19\\processing\\DK_GI"

# output
# water
set water "E:\\Diamond19\\processing\\DK_GI\\water"
# gas
set gas "E:\\Diamond19\\processing\\DK_GI\\gas"

set files [glob -directory $seg_file *.am]

# Load the mask
[ load "$mask\\mask_inside_noboundaries.am" ] setLabel "mask"

# initialise variables
set size [llength $files]
set tomo_first 0
set tomo_last [expr $size-1]
set tomo_inc 1

# for loop
for {set i $tomo_first} {$i <= $tomo_last} {set i [expr $i+$tomo_inc]} {

	set name_full [file tail [lindex $files $i]]
	
	# Separate the file name from extension
	set fnparts [file rootname "$name_full"]
	
	# Get the file name without extension
	set fnparts5 "_water.am"
	set fnparts6 "_gas.am"

	set filename5 "$fnparts$fnparts5"
	set filename6 "$fnparts$fnparts6"
	
	# load segmented data
	[ load "$seg_file\\$name_full" ] setLabel "seg_img"
	
	# extract subvolume
	set hideNewModules 0
	create HxLatticeAccess "Extract Subvolume"
	"Extract Subvolume" setVar "CustomHelp" {HxLatticeAccess}
	"Extract Subvolume" data connect "seg_img"
	"Extract Subvolume" fire
	"Extract Subvolume" boxMin setValue 0 0
	"Extract Subvolume" boxMin setValue 1 0
	"Extract Subvolume" boxMin setValue 2 10
	"Extract Subvolume" boxSize setValue 0 1280
	"Extract Subvolume" boxSize setValue 1 1284
	"Extract Subvolume" boxSize setValue 2 1060
	"Extract Subvolume" applyTransformToResult 1
	"Extract Subvolume" fire
	set hideNewModules 0
	[ "Extract Subvolume" create ] setLabel "seg_data.view"
	"seg_data.view" master connect "Extract Subvolume"
	
	# mask
	set hideNewModules 0
	create mask "Mask"
	"Mask" setVar "CustomHelp" {mask.html}
	"Mask" interpretation setValue 0
	"Mask" outputLocation setIndex 0 0
	"Mask" inputImage connect "seg_data.view"
	"Mask" inputBinaryImage connect "mask"
	"Mask" applyTransformToResult 1
	set hideNewModules 0
	[ {Mask} create ImgOut ] setLabel "seg_data.masked"
	
	# arithmetic, select water
	create HxArithmetic "Arithmetic"
	"Arithmetic" inputA connect "seg_data.masked"
	"Arithmetic" fire
	"Arithmetic" expr0 setState {a==1}
	"Arithmetic" fire
	[ {Arithmetic} create result ] setLabel "water"
	"water" master connect "Arithmetic" "result" 0
	"water" fire
	
	# remove noise
	set hideNewModules 0
	create removalsmallspots "Remove Small Spots"
	"Remove Small Spots" inputImage connect "water"
	"Remove Small Spots" size setValue 0 1000
	"Remove Small Spots" applyTransformToResult 1	
	set hideNewModules 0
	[ {Remove Small Spots} create ImgOut ] setLabel "water.filtered"
	"water.filtered" master connect "Remove Small Spots" "ImgOut" 0

	# arithmetic, select gas
	create HxArithmetic "Arithmetic 2"
	"Arithmetic 2" inputA connect "seg_data.masked"
	"Arithmetic 2" fire
	"Arithmetic 2" expr0 setState {a==2}
	"Arithmetic 2" fire
	[ {Arithmetic 2} create result ] setLabel "gas"
	"gas" master connect "Arithmetic 2" "result" 0
	"gas" fire
	
	# remove noise
	set hideNewModules 0
	create removalsmallspots "Remove Small Spots 2"
	"Remove Small Spots 2" inputImage connect "gas"
	"Remove Small Spots 2" size setValue 0 10000
	"Remove Small Spots 2" applyTransformToResult 1	
	set hideNewModules 0
	[ {Remove Small Spots 2} create ImgOut ] setLabel "gas.filtered"
	"gas.filtered" master connect "Remove Small Spots" "ImgOut" 0
	
	"water.filtered" save "Avizo" "$water\\$filename5"
	"gas.filtered" save "Avizo" "$gas\\$filename6"
	
	remove "seg_img"
	remove "seg_data.view"
	remove "seg_data.masked"
	remove "water"
	remove "water.filtered"
	remove "gas"
	remove "gas.filtered"
	remove $filename5
	remove $filename6
}

quit
