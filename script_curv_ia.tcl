# Always use double slash

# paths 

# input 
# segmented files
set seg_file "E:\\Diamond19\\processing\\DK_GI\\seg_all"
# distance map
set distance_folder "E:\\Diamond19\\processing\\DK_GI"

# output
# interface surface go
set interface_file_go "E:\\Diamond19\\processing\\DK_GI\\curv_ia\\interface_go"
# mean curvatures go
set km_go "E:\\Diamond19\\processing\\DK_GI\\curv_ia\\mean_curv_go"
# distance vectors go
set distance_go "E:\\Diamond19\\processing\\DK_GI\\curv_ia\\mean_curv_dist_go"
# interfacial area go
set area_csv_go "E:\\Diamond19\\processing\\DK_GI\\curv_ia\\area_csv_go"
# interface surface go
set interface_file_ow "E:\\Diamond19\\processing\\DK_GI\\curv_ia\\interface_ow"
# mean curvatures ow
set km_ow "E:\\Diamond19\\processing\\DK_GI\\curv_ia\\mean_curv_ow"
# distance vectors ow
set distance_ow "E:\\Diamond19\\processing\\DK_GI\\curv_ia\\mean_curv_dist_ow"
# interfacial area ow
set area_csv_ow "E:\\Diamond19\\processing\\DK_GI\\curv_ia\\area_csv_ow"


set files [glob -directory $seg_file *.am]

# Load the distance map
[ load "$distance_folder\\distance_map.am" ] setLabel "distance_map"

set size [llength $files]

set tomo_first 0
set tomo_last [expr $size-1]
set tomo_inc 1

for {set i $tomo_first} {$i <= $tomo_last} {set i [expr $i+$tomo_inc]} {

	set name_full [file tail [lindex $files $i]]
	
	# Separate the file name from extension
	set fnparts [file rootname "$name_full"]
	
	# Get the file name without extension
	
	set fnparts1 "_interface_go.am"
	set fnparts2 "_interfacial_area_go.csv"
	set fnparts3 "_mean_curvature_go.am"
	set fnparts4 "_dist_mcurvature_go.am"
	set fnparts5 "_interface_ow.am"
	set fnparts6 "_interfacial_area_ow.csv"
	set fnparts7 "_mean_curvature_ow.am"
	set fnparts8 "_dist_mcurvature_ow.am"
	
	set filename1 "$fnparts$fnparts1"
	set filename2 "$fnparts$fnparts2"
	set filename3 "$fnparts$fnparts3"
	set filename4 "$fnparts$fnparts4"
	set filename5 "$fnparts$fnparts5"
	set filename6 "$fnparts$fnparts6"
	set filename7 "$fnparts$fnparts7"
	set filename8 "$fnparts$fnparts8"
	
	[ load "$seg_file\\$name_full" ] setLabel "seg_img"
	
	create HxGMC "Generate Surface"
	"Generate Surface" data connect "seg_img"
	"Generate Surface" fire
	"Generate Surface" borderOnOff setValue 0
	"Generate Surface" smoothing setIndex 0 3
	"Generate Surface" smoothingExtent setMinMax 1 9
	
	# Choose smooth extent, example: 5
	"Generate Surface" smoothingExtent setValue 5
	
	# Choose smooth material, example: Material 2
	"Generate Surface" smoothMaterial setIndex 0 3
	[ "Generate Surface" create ] setLabel "seg_surf"
	remove HxGMC "Generate Surface"

	# Curvature between oil (1) and gas (4)
	create HxDisplaySurface "Surface View"
	"Surface View" data connect "seg_surf"
	"Surface View" fire
	
	# Find interface between material 1 (index 2) and 4 (index 5)
	"Surface View" materials setIndex 0 2
	"Surface View" materials setIndex 1 5
	"Surface View" fire
	"Surface View" buffer setValue 2
	"Surface View" fire
	"Surface View" buffer setValue 0
	"Surface View" fire

	create HxViewBaseExtract "Extract Surface"
	"Extract Surface" module1 connect "Surface View"
	[ "Extract Surface" create ] setLabel "interface"
	remove HxDisplaySurface "Surface View"
	
	remove HxViewBaseExtract "Extract Surface"
	
	# Get curvature
	create HxGetCurvature "Curvature"
	"Curvature" data connect "interface"
	"Curvature" fire
	"Curvature" method setValue 0
	"Curvature" param setMinMax 0 1 20
	"Curvature" param setValue 0 5
	"Curvature" output setIndex 0 2
	"Curvature" applyTransformToResult 1
	"Curvature" fire
	"Curvature" setPickable 1
	
	# Compute mean curvature
	[ "Curvature" create 2
	] setLabel "MeanCurvature"
	"MeanCurvature" master connect "Curvature" "meanCurvature" 2
	"MeanCurvature" surface connect "interface"
	"MeanCurvature" fire
	remove HxGetCurvature "Curvature"
	
	# Compute distance of each point
	# First create an abs variable for curvature absolute values
	create HxArithmetic "Arithmetic"
	"Arithmetic" inputA connect "MeanCurvature"
	"Arithmetic" fire
	"Arithmetic" expr0 setState {abs(a)}
	"Arithmetic" fire
	
	[ {Arithmetic} create result ] setLabel "abs"
	"abs" master connect "Arithmetic" "result" 0
	"abs" surface connect "interface"
	"abs" fire
	"abs" fire
	remove HxArithmetic "Arithmetic"

	# Then create a bool variable for curvature position
	create HxArithmetic "Arithmetic"
	"Arithmetic" inputA connect "abs"
	"Arithmetic" fire
	"Arithmetic" expr0 setState {a>=0}
	"Arithmetic" fire
	
	[ {Arithmetic} create result ] setLabel "bool"
	"bool" master connect "Arithmetic" "result" 0
	"bool" surface connect "interface"
	"bool" fire
	"bool" fire
	remove HxArithmetic "Arithmetic"
	
	# Then multiply bool times the distance map
	create HxArithmetic "Arithmetic"
	"Arithmetic" inputA connect "bool"
	"Arithmetic" inputB connect "distance_map"
	"Arithmetic" fire
	"Arithmetic" expr0 setState {a*b}
	"Arithmetic" fire
	
	[ {Arithmetic} create result ] setLabel "distance_km"
	"distance_km" master connect "Arithmetic" "result" 0
	"distance_km" surface connect "interface"
	"distance_km" fire
	"distance_km" fire
	remove HxArithmetic "Arithmetic"
	
	# Get interfacial area. Be careful, the example data has voxel size of 1
	set area ["interface" getArea]
	set area_val "$area"
	
	# Save area and curvature between oil and gas
	set fileId [open "$area_csv_go\\$filename2" "w"]
	puts -nonewline $fileId $area_val
	close $fileId
	unset area_val
	
	"interface" save "Avizo" "$interface_file_go\\$filename1"
	"MeanCurvature" save "Avizo ascii" "$km_go\\$filename3"
	"distance_km" save "Avizo ascii" "$distance_go\\$filename4"
	
	# Curvature between brine (2) and oil (1)
	create HxDisplaySurface "Surface View"
	"Surface View" data connect "seg_surf"
	"Surface View" fire
	
	# Find interface between material 2 (index 3) and 1 (index 2)
	"Surface View" materials setIndex 0 3
	"Surface View" materials setIndex 1 2
	"Surface View" fire
	"Surface View" buffer setValue 2
	"Surface View" fire
	"Surface View" buffer setValue 0
	"Surface View" fire

	create HxViewBaseExtract "Extract Surface"
	"Extract Surface" module1 connect "Surface View"
	[ "Extract Surface" create ] setLabel "interface"
	remove HxDisplaySurface "Surface View"
	
	remove HxViewBaseExtract "Extract Surface"
	
	# Get curvature
	create HxGetCurvature "Curvature"
	"Curvature" data connect "interface"
	"Curvature" fire
	"Curvature" method setValue 0
	"Curvature" param setMinMax 0 1 20
	"Curvature" param setValue 0 5
	"Curvature" output setIndex 0 2
	"Curvature" applyTransformToResult 1
	"Curvature" fire
	"Curvature" setPickable 1
	
	# Compute mean curvature
	[ "Curvature" create 2
	] setLabel "MeanCurvature"
	"MeanCurvature" master connect "Curvature" "meanCurvature" 2
	"MeanCurvature" surface connect "interface"
	"MeanCurvature" fire
	remove HxGetCurvature "Curvature"
	
	# Compute distance of each point
	# First create an abs variable for curvature absolute values
	create HxArithmetic "Arithmetic"
	"Arithmetic" inputA connect "MeanCurvature"
	"Arithmetic" fire
	"Arithmetic" expr0 setState {abs(a)}
	"Arithmetic" fire
	
	[ {Arithmetic} create result ] setLabel "abs"
	"abs" master connect "Arithmetic" "result" 0
	"abs" surface connect "interface"
	"abs" fire
	"abs" fire
	remove HxArithmetic "Arithmetic"

	# Then create a bool variable for curvature position
	create HxArithmetic "Arithmetic"
	"Arithmetic" inputA connect "abs"
	"Arithmetic" fire
	"Arithmetic" expr0 setState {a>=0}
	"Arithmetic" fire
	
	[ {Arithmetic} create result ] setLabel "bool"
	"bool" master connect "Arithmetic" "result" 0
	"bool" surface connect "interface"
	"bool" fire
	"bool" fire
	remove HxArithmetic "Arithmetic"
	
	# Then multiply bool times the distance map
	create HxArithmetic "Arithmetic"
	"Arithmetic" inputA connect "bool"
	"Arithmetic" inputB connect "distance_map"
	"Arithmetic" fire
	"Arithmetic" expr0 setState {a*b}
	"Arithmetic" fire
	
	[ {Arithmetic} create result ] setLabel "distance_km"
	"distance_km" master connect "Arithmetic" "result" 0
	"distance_km" surface connect "interface"
	"distance_km" fire
	"distance_km" fire
	remove HxArithmetic "Arithmetic"

	# Get interfacial area. Be careful, the example data has voxel size of 1
	set area ["interface" getArea]
	set area_val "$area"
	
	
	set fileId [open "$area_csv_ow\\$filename6" "w"]
	puts -nonewline $fileId $area_val
	close $fileId
	unset area_val
	
	"interface" save "Avizo" "$interface_file_ow\\$filename5"
	"MeanCurvature" save "Avizo ascii" "$km_ow\\$filename7"
	"distance_km" save "Avizo ascii" "$distance_ow\\$filename8"
	
	remove "seg_img"
	remove "seg_surf"
	remove $filename1

}

quit
