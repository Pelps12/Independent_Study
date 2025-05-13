  try {
        # Step 1: Define the base directory variable
        puts "Enter the absolute base directory path (e.g., C:/Users/oluwa/Desktop/Coding/Vivado): "
        set base_dir [string trim [gets stdin ]]

        puts "Enter the project name"
        set project_name [string trim [gets stdin ]]

        puts "Enter top module name"
        set top_module [string trim [gets stdin ]]

        put "Enter FPGA part: Currently Arty S7-50"
        set fpga_part xc7s50csga324-1

        # Project directory path
        set project_dir ${base_dir}/project  

        # Directory for the output bitstream file
        set bitstream_dir ${base_dir}/bitstreams  

        # Directory for the constraints files
        set constraints_dir ${base_dir}/constraints

        set data_dir ${base_dir}/data

        # Directory for the design source files (SystemVerilog, Verilog, etc.)
        set design_dir ${base_dir}/designs 

        # Step 3: Check if the project already exists
        
            
        if {[file exists $project_dir]} {
            # Open the existing project
            puts "Opening existing project: $project_name"
            try {
                if {[string equal [current_project] $project_name] == 0} {
                     open_project ${project_dir}/${project_name}.xpr
                }
            } on error {errormsg} {
                open_project ${project_dir}/${project_name}.xpr
            }
        } else {
            # Create a new Vivado project
            puts "Creating a new project: $project_name"
            create_project $project_name $project_dir -part $fpga_part
        }

            
        
        


        # Step 4: Add all design source files from the design directory
        # This assumes the design files are in SystemVerilog, Verilog, or VHDL format
        set design_files [glob -nocomplain "$design_dir/*.{sv,v,vhdl}"]
        set data_files [glob -nocomplain "$data_dir/*.{mem,hex}"]
        add_files $design_files

        if {[llength $data_files] == 0} {
            #Not good programming :(
            puts "No data files"
        } else {
            add_files $data_files
        }


        # Optional: Set the file type if needed (e.g., for Verilog/SystemVerilog files)
        foreach file $design_files {
            set_property FILE_TYPE SystemVerilog [get_files $file]
        }

        # Step 5: Add all constraints files from the constraints directory
        # Assuming constraints files have the `.xdc` extension
        set constraints_files [glob -nocomplain "$constraints_dir/*.xdc"]
        add_files -fileset constrs_1 $constraints_files

        # Step 6: Synthesize the design
        set_param general.maxThreads 8
        synth_design -top $top_module -part $fpga_part -constrset constrs_1

        # Step 7: Implement the design
        # Perform optimization, placement, and routing
        opt_design
        place_design
        route_design
        set bitstream_file ${bitstream_dir}/output.bit
        # Step 8: Generate the bitstream file
        write_bitstream -force $bitstream_file 

        # Step 9: Open the Hardware Manager
        open_hw_manager

        # Step 10: Connect to the hardware server
        connect_hw_server

        # Step 11: Detect the hardware devices connected via JTAG (or other interfaces)
        current_hw_target

        # Step 12: Open the hardware target (the FPGA device)
        open_hw_target

        # Step 13: Get the list of hardware devices connected (in case multiple devices are connected)
        set devices [get_hw_devices]

        # Step 14: Check if devices are detected, and program the FPGA if devices are found
        if {[llength $devices] == 0} {
            puts "No matching hardware devices found."
        } else {
            # Program the first device in the list (assuming it's the correct device)
            set_property PROGRAM.FILE $bitstream_file [current_hw_device]
            program_hw_devices [current_hw_device]
            puts "Device programmed successfully."

            set memory_file ${bitstream_dir}/output.mcs

            #Step 14.5: Flash the FPGA memory
            write_cfgmem -force -format mcs -size 16 -interface SPIx4 -loadbit "up 0x00000000 $bitstream_file" -file $memory_file
            create_hw_cfgmem -hw_device [get_hw_devices xc7s50_0] -mem_dev [lindex [get_cfgmem_parts {s25fl128sxxxxxx0-spi-x1_x2_x4}] 0]
            set_property PROGRAM.ADDRESS_RANGE  {use_file} [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7s50_0] 0]]
            set_property PROGRAM.FILES [list $memory_file ] [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7s50_0] 0]]
            set_property PROGRAM.PRM_FILE {} [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7s50_0] 0]]
            set_property PROGRAM.UNUSED_PIN_TERMINATION {pull-none} [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7s50_0] 0]]
            set_property PROGRAM.BLANK_CHECK  0 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7s50_0] 0]]
            set_property PROGRAM.ERASE  1 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7s50_0] 0]]
            set_property PROGRAM.CFG_PROGRAM  1 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7s50_0] 0]]
            set_property PROGRAM.VERIFY  1 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7s50_0] 0]]
            set_property PROGRAM.CHECKSUM  0 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7s50_0] 0]]

            create_hw_bitstream -hw_device [lindex [get_hw_devices xc7s50_0] 0] [get_property PROGRAM.HW_CFGMEM_BITFILE [ lindex [get_hw_devices xc7s50_0] 0]]; program_hw_devices [lindex [get_hw_devices xc7s50_0] 0]; 

            refresh_hw_device [lindex [get_hw_devices xc7s50_0] 0];

            program_hw_cfgmem -hw_cfgmem [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7s50_0] 0]]
      }


        # Step 15: Close the hardware target and server connections
        close_hw_target
        disconnect_hw_server
        close_hw_manager
   } on error {errmsg erropts} {
        # Step 15: Close the hardware target and server connections
        puts $errmsg
        close_hw_target
        disconnect_hw_server
        close_hw_manager
   }
