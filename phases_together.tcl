# Always use double slash

# paths 

# input
# water
set water "E:\\Diamond19\\processing\\DK_GI\\water"
# gas
set gas "E:\\Diamond19\\processing\\DK_GI\\gas"
# mask
set mask "E:\\Diamond19\\processing\\DK_GI"
# oil
set oil "E:\\Diamond19\\processing\\DK_WF1\\1280x1284x1080"

# output 
# segmented files
set seg_file "E:\\Diamond19\\processing\\DK_GI\\seg_all"

set files_w [glob -directory $water *.am]
set files_g [glob -directory $gas *.am]

# Load the mask and oil
[ load "$mask\\mask_inside_noboundaries.am" ] setLabel "mask"
[ load "$oil\\115379_filt-p7_seg-ws_rss_reg_masked.am" ] setLabel "oil"

# initialise variables
set size [llength $files_w]
set tomo_first 0
set tomo_last [expr $size-1]
set tomo_inc 1

# for loop
for {set i $tomo_first} {$i <= $tomo_last} {set i [expr $i+$tomo_inc]} {

	set name_full_w [file tail [lindex $files_w $i]]
	set name_full_g [file tail [lindex $files_g $i]]
	
	# Separate the file name from extension
	set fnparts_w [file rootname "$name_full_w"]
	set fnparts_g [file rootname "$name_full_g"]
	
	# Get the file name without extension
	set fnparts "_seg_all.am"

	set filename "$fnparts_w$fnparts"
	
	# load water and gas data
	[ load "$water\\$name_full_w" ] setLabel "w_phase"
	[ load "$gas\\$name_full_g" ] setLabel "g_phase"
	
	# process images
	# dilation gas
	set hideNewModules 0
	create dilate "Dilation"
	"Dilation" setVar "CustomHelp" {dilate}
	"Dilation" Type setState {type Cube}
	"Dilation" interpretation setValue 0
	"Dilation" outputLocation setIndex 0 0
	"Dilation" neighborhood setValue 0
	"Dilation" inputImage connect "g_phase"
	"Dilation" size setValue 0 4
	"Dilation" applyTransformToResult 1
	"Dilation" fire
	set hideNewModules 0
	[ {Dilation} create ImgOut ] setLabel "g_phase.dilated"
	"g_phase.dilated" master connect "Dilation" "ImgOut" 0
	
	# dilation water
	set hideNewModules 0
	create dilate "Dilation 2"
	"Dilation 2" setVar "CustomHelp" {dilate}
	"Dilation 2" Type setState {type Cube}
	"Dilation 2" interpretation setValue 0
	"Dilation 2" outputLocation setIndex 0 0
	"Dilation 2" neighborhood setValue 0
	"Dilation 2" inputImage connect "w_phase"
	"Dilation 2" size setValue 0 3
	"Dilation 2" applyTransformToResult 1
	"Dilation 2" fire
	set hideNewModules 0
	[ {Dilation 2} create ImgOut ] setLabel "w_phase.dilated"
	"w_phase.dilated" master connect "Dilation 2" "ImgOut" 0
	
	# arithmetic, put phases together
	create HxArithmetic "Arithmetic"
	"Arithmetic" inputA connect "oil"
	"Arithmetic" inputB connect "w_phase.dilated"
	"Arithmetic" inputC connect "g_phase.dilated"
	"Arithmetic" fire
	"Arithmetic" expr0 setState {a+2*b+4*c}
	"Arithmetic" fire
	[ {Arithmetic} create result ] setLabel "all_phases"
	"all_phases" master connect "Arithmetic" "result" 0
	"all_phases" fire
	
	# arithmetic, put phases together
	create HxArithmetic "Arithmetic 2"
	"Arithmetic 2" inputA connect "all_phases"
	"Arithmetic 2" fire
	"Arithmetic 2" expr0 setState {(a==1)+(a==2)*3+(a==4)*3+(a==3)*2+(a==5)*4+(a==6)*3+(a==7)*4}
	"Arithmetic 2" fire
	[ {Arithmetic 2} create result ] setLabel "all_phases_seg"
	"all_phases_seg" master connect "Arithmetic 2" "result" 0
	"all_phases_seg" fire
	
	# extract subvolume
	set hideNewModules 0
	create HxLatticeAccess "Extract Subvolume"
	"Extract Subvolume" setVar "CustomHelp" {HxLatticeAccess}
	"Extract Subvolume" data connect "all_phases_seg"
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
	[ "Extract Subvolume" create ] setLabel "all_phases_seg.view"
	"all_phases_seg.view" master connect "Extract Subvolume"
	
	# mask
	set hideNewModules 0
	create mask "Mask"
	"Mask" setVar "CustomHelp" {mask.html}
	"Mask" interpretation setValue 0
	"Mask" outputLocation setIndex 0 0
	"Mask" inputImage connect "all_phases_seg.view"
	"Mask" inputBinaryImage connect "mask"
	"Mask" applyTransformToResult 1
	set hideNewModules 0
	[ {Mask} create ImgOut ] setLabel "all_phases_seg.masked"
	
	"all_phases_seg.masked" save "Avizo" "$seg_file\\$filename"
	
	remove "w_phase"
	remove "g_phase"
	remove "g_phase.dilated"
	remove "w_phase.dilated"
	remove "all_phases"
	remove "all_phases_seg"
	remove "all_phases_seg.view"
	remove "all_phases_seg.masked"
	remove $filename
}

quit
