# Always use double slash

# paths 

# input 
# segmented files
set seg_file "E:\\Diamond19\\processing\\DK_GI\\seg_all"

# output
# interface surface sw
set interface_file_sw "E:\\Diamond19\\processing\\DK_GI\\curv_ia\\interface_sw"
# interface surface os
set interface_file_os "E:\\Diamond19\\processing\\DK_GI\\curv_ia\\interface_os"
# interface surface gs
set interface_file_gs "E:\\Diamond19\\processing\\DK_GI\\curv_ia\\interface_gs"
# interfacial area sw
set area_csv_sw "E:\\Diamond19\\processing\\DK_GI\\curv_ia\\area_csv_sw"
# interfacial area os
set area_csv_os "E:\\Diamond19\\processing\\DK_GI\\curv_ia\\area_csv_os"
# interfacial area gs
set area_csv_gs "E:\\Diamond19\\processing\\DK_GI\\curv_ia\\area_csv_gs"

set files [glob -directory $seg_file *.am]

set size [llength $files]

set tomo_first 0
set tomo_last [expr $size-1]
set tomo_inc 1

for {set i $tomo_first} {$i <= $tomo_last} {set i [expr $i+$tomo_inc]} {

	set name_full [file tail [lindex $files $i]]
	
	# Separate the file name from extension
	set fnparts [file rootname "$name_full"]
	
	# Get the file name without extension

	set fnparts5 "_interfacial_area_sw.csv"
	set fnparts6 "_interface_sw.am"
	set fnparts7 "_interfacial_area_os.csv"
	set fnparts8 "_interface_os.am"
	set fnparts1 "_interfacial_area_gs.csv"
	set fnparts2 "_interface_gs.am"
	
	set filename5 "$fnparts$fnparts5"
	set filename6 "$fnparts$fnparts6"
	set filename7 "$fnparts$fnparts7"
	set filename8 "$fnparts$fnparts8"
	set filename1 "$fnparts$fnparts1"
	set filename2 "$fnparts$fnparts2"
	
	# load the file
	[ load "$seg_file\\$name_full" ] setLabel "seg_img"
	
	#generate the surface
	create HxGMC "Generate Surface"
	"Generate Surface" data connect "seg_img"
	"Generate Surface" fire
	"Generate Surface" borderOnOff setValue 0
	"Generate Surface" smoothing setIndex 0 3
	"Generate Surface" smoothingExtent setMinMax 1 9
	
	# Choose smooth extent, example: 5
	"Generate Surface" smoothingExtent setValue 5
	
	# Apply the generation of surface
	[ "Generate Surface" create ] setLabel "seg_surf"
	remove HxGMC "Generate Surface"

	# Surface view to select the phases
	create HxDisplaySurface "Surface View"
	"Surface View" data connect "seg_surf"
	"Surface View" fire
	
	# Find interface between material 2 - water - (index 3) and 3 - solid - (index 4)
	"Surface View" materials setIndex 0 3
	"Surface View" materials setIndex 1 4
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
	
	# Get interfacial area. Be careful, the example data has voxel size of 1
	set area ["interface" getArea]
	set area_val "$area"
	
	set fileId [open "$area_csv_sw\\$filename5" "w"]
	puts -nonewline $fileId $area_val
	close $fileId
	unset area_val
	
	"interface" save "Avizo" "$interface_file_sw\\$filename6"
	
	# Surface view to select the phases
	create HxDisplaySurface "Surface View"
	"Surface View" data connect "seg_surf"
	"Surface View" fire
	
	# Find interface between material 1 - oil - (index 2) and 3 - solid - (index 4)
	"Surface View" materials setIndex 0 2
	"Surface View" materials setIndex 1 4
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
	
	# Get interfacial area. Be careful, the example data has voxel size of 1
	set area ["interface" getArea]
	set area_val "$area"
		
	set fileId [open "$area_csv_os\\$filename7" "w"]
	puts -nonewline $fileId $area_val
	close $fileId
	unset area_val
	
	"interface" save "Avizo" "$interface_file_os\\$filename8"
	
	# Surface view to select the phases
	create HxDisplaySurface "Surface View"
	"Surface View" data connect "seg_surf"
	"Surface View" fire
	
	# Find interface between material 4 - gas - (index 5) and 3 - solid - (index 4)
	"Surface View" materials setIndex 0 5
	"Surface View" materials setIndex 1 4
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
	
	# Get interfacial area. Be careful, the example data has voxel size of 1
	set area ["interface" getArea]
	set area_val "$area"
		
	set fileId [open "$area_csv_gs\\$filename1" "w"]
	puts -nonewline $fileId $area_val
	close $fileId
	unset area_val
	
	"interface" save "Avizo" "$interface_file_gs\\$filename2"
	
	remove "seg_img"
	remove "seg_surf"
	remove $filename5
	remove $filename6
	remove $filename7
	remove $filename8
	remove $filename1
	remove $filename2

}

quit
