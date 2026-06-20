# Script to create a test rig for speed testing combinational modules
# Author: Nitin Chandrachoodan <nitin@ee.iitm.ac.in>
# Copyright (c) 2025 IIT Madras
#
# You can use this script to create a test rig for at-speed testing
# of combinational modules. The test rig consists of a wrapper
# module that instantiates the DUT and connects it to a set of
# test pins, which are driven by the Pynq PS (processing system).
# You need to add the RTL code for the DUT to the Vivado project



# Set the project name
set _xil_proj_name_ "speed_test"
set build_dir "../build/vivado"

proc create_proj { } {

  # global build_dir _xil_proj_name_ ip_vlnv
  global build_dir _xil_proj_name_
  create_project -force \
    ${_xil_proj_name_} \
    $build_dir/${_xil_proj_name_} \
    -part xc7z020clg400-1

  # # Create project
  # create_project ${_xil_proj_name_} ./${_xil_proj_name_} -part xc7z020clg400-1

  # Set the directory path for the new project
  set proj_dir [get_property directory [current_project]]

  # Set project properties
  set obj [current_project]
  set_property -name "default_lib" -value "xil_defaultlib" -objects $obj
  set_property -name "enable_vhdl_2008" -value "1" -objects $obj
  set_property -name "ip_cache_permissions" -value "read write" -objects $obj
  set_property -name "ip_output_repo" -value "$proj_dir/${_xil_proj_name_}.cache/ip" -objects $obj
  set_property -name "mem.enable_memory_map_generation" -value "1" -objects $obj
  set_property -name "part" -value "xc7z020clg400-1" -objects $obj
  set_property -name "revised_directory_structure" -value "1" -objects $obj
  set_property -name "sim.central_dir" -value "$proj_dir/${_xil_proj_name_}.ip_user_files" -objects $obj
  set_property -name "sim.ip.auto_export_scripts" -value "1" -objects $obj
  set_property -name "simulator_language" -value "Mixed" -objects $obj
  set_property -name "xpm_libraries" -value "XPM_CDC XPM_FIFO XPM_MEMORY" -objects $obj

  # Create 'sources_1' fileset (if not found)
  if {[string equal [get_filesets -quiet sources_1] ""]} {
    create_fileset -srcset sources_1
  }



  # Set 'sources_1' fileset properties
  set obj [get_filesets sources_1]
  set_property -name "top" -value "pynq_wrapper" -objects $obj
  set_property -name "top_auto_set" -value "0" -objects $obj

  # Create 'constrs_1' fileset (if not found)
  if {[string equal [get_filesets -quiet constrs_1] ""]} {
    create_fileset -constrset constrs_1
  }

  ################################################################################
  # This is where the DUT is added - change name if needed?
  ################################################################################
  # Adding sources referenced in BDs, if not already added
  if { [get_files mult.v] == "" } {
    import_files -quiet -fileset sources_1 mult.v
  }


  # Proc to create BD pynq
  proc cr_bd_pynq { parentCell } {
    set design_name pynq

    create_bd_design $design_name

    variable script_folder

    if { $parentCell eq "" } {
      set parentCell [get_bd_cells /]
    }

    # Get object for parentCell
    set parentObj [get_bd_cells $parentCell]

    # Save current instance; Restore later
    set oldCurInst [current_bd_instance .]

    # Set parent object as current
    current_bd_instance $parentObj


    # Create interface ports
    set DDR [ create_bd_intf_port -mode Master \
      -vlnv xilinx.com:interface:ddrx_rtl:1.0 DDR ]

    set FIXED_IO [ create_bd_intf_port -mode Master \
      -vlnv xilinx.com:display_processing_system7:fixedio_rtl:1.0 FIXED_IO ]

    # Create ports
# Create instance: axi_fifo_mm_s_0, and set properties
set axi_fifo_mm_s_0 [ \
  create_bd_cell -type ip \
  -vlnv xilinx.com:ip:axi_fifo_mm_s:4.3 axi_fifo_mm_s_0 ]

set_property -dict [ list \
  CONFIG.C_USE_TX_CTRL {0} \
  ] $axi_fifo_mm_s_0
   



    # Create instance: axis_data_fifo_1, and set properties
    set axis_data_fifo_1 [ \
      create_bd_cell -type ip \
      -vlnv xilinx.com:ip:axis_data_fifo:2.0 axis_data_fifo_1 ]
    set_property -dict [ list \
      CONFIG.HAS_TLAST {1} \
      CONFIG.IS_ACLK_ASYNC {1} \
      CONFIG.TDATA_NUM_BYTES {4} \
      ] $axis_data_fifo_1

    # Create instance: axis_dwidth_converter_0, and set properties
    set axis_dwidth_converter_0 [ \
      create_bd_cell -type ip \
      -vlnv xilinx.com:ip:axis_dwidth_converter:1.1 axis_dwidth_converter_0 ]
    set_property -dict [ list \
      CONFIG.M_TDATA_NUM_BYTES {8} \
      CONFIG.S_TDATA_NUM_BYTES {4} \
      ] $axis_dwidth_converter_0

    # Create instance: ila_0, and set properties
    set ila_0 [ create_bd_cell \
      -type ip -vlnv xilinx.com:ip:ila:6.2 ila_0 ]
    set_property -dict [ list \
      CONFIG.C_ENABLE_ILA_AXI_MON {false} \
      CONFIG.C_MONITOR_TYPE {Native} \
      CONFIG.C_NUM_OF_PROBES {3} \
      CONFIG.C_PROBE0_WIDTH {64} \
      ] $ila_0

    # Create instance: mult_0, and set properties
    set block_name mult
    set block_cell_name mult_0
    if { [catch {set mult_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
      return 1
    } elseif { $mult_0 eq "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
      return 1
    }

    # Create instance: processing_system7_0, and set properties
    set processing_system7_0 [ \
      create_bd_cell -type ip \
      -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0 ]
    set_property -dict [ list \
      CONFIG.PCW_ACT_APU_PERIPHERAL_FREQMHZ {666.666687} \
      CONFIG.PCW_ACT_CAN_PERIPHERAL_FREQMHZ {10.000000} \
      CONFIG.PCW_ACT_DCI_PERIPHERAL_FREQMHZ {10.158730} \
      CONFIG.PCW_ACT_ENET0_PERIPHERAL_FREQMHZ {10.000000} \
      CONFIG.PCW_ACT_ENET1_PERIPHERAL_FREQMHZ {10.000000} \
      CONFIG.PCW_ACT_FPGA0_PERIPHERAL_FREQMHZ {50.000000} \
      CONFIG.PCW_ACT_FPGA1_PERIPHERAL_FREQMHZ {50.000000} \
      CONFIG.PCW_ACT_FPGA2_PERIPHERAL_FREQMHZ {10.000000} \
      CONFIG.PCW_ACT_FPGA3_PERIPHERAL_FREQMHZ {10.000000} \
      CONFIG.PCW_ACT_PCAP_PERIPHERAL_FREQMHZ {200.000000} \
      CONFIG.PCW_ACT_QSPI_PERIPHERAL_FREQMHZ {10.000000} \
      CONFIG.PCW_ACT_SDIO_PERIPHERAL_FREQMHZ {10.000000} \
      CONFIG.PCW_ACT_SMC_PERIPHERAL_FREQMHZ {10.000000} \
      CONFIG.PCW_ACT_SPI_PERIPHERAL_FREQMHZ {10.000000} \
      CONFIG.PCW_ACT_TPIU_PERIPHERAL_FREQMHZ {200.000000} \
      CONFIG.PCW_ACT_TTC0_CLK0_PERIPHERAL_FREQMHZ {111.111115} \
      CONFIG.PCW_ACT_TTC0_CLK1_PERIPHERAL_FREQMHZ {111.111115} \
      CONFIG.PCW_ACT_TTC0_CLK2_PERIPHERAL_FREQMHZ {111.111115} \
      CONFIG.PCW_ACT_TTC1_CLK0_PERIPHERAL_FREQMHZ {111.111115} \
      CONFIG.PCW_ACT_TTC1_CLK1_PERIPHERAL_FREQMHZ {111.111115} \
      CONFIG.PCW_ACT_TTC1_CLK2_PERIPHERAL_FREQMHZ {111.111115} \
      CONFIG.PCW_ACT_UART_PERIPHERAL_FREQMHZ {10.000000} \
      CONFIG.PCW_ACT_WDT_PERIPHERAL_FREQMHZ {111.111115} \
      CONFIG.PCW_ARMPLL_CTRL_FBDIV {40} \
      CONFIG.PCW_CAN_PERIPHERAL_DIVISOR0 {1} \
      CONFIG.PCW_CAN_PERIPHERAL_DIVISOR1 {1} \
      CONFIG.PCW_CLK0_FREQ {50000000} \
      CONFIG.PCW_CLK1_FREQ {50000000} \
      CONFIG.PCW_CLK2_FREQ {10000000} \
      CONFIG.PCW_CLK3_FREQ {10000000} \
      CONFIG.PCW_CPU_CPU_PLL_FREQMHZ {1333.333} \
      CONFIG.PCW_CPU_PERIPHERAL_DIVISOR0 {2} \
      CONFIG.PCW_DCI_PERIPHERAL_DIVISOR0 {15} \
      CONFIG.PCW_DCI_PERIPHERAL_DIVISOR1 {7} \
      CONFIG.PCW_DDRPLL_CTRL_FBDIV {32} \
      CONFIG.PCW_DDR_DDR_PLL_FREQMHZ {1066.667} \
      CONFIG.PCW_DDR_PERIPHERAL_DIVISOR0 {2} \
      CONFIG.PCW_DDR_RAM_HIGHADDR {0x1FFFFFFF} \
      CONFIG.PCW_ENET0_PERIPHERAL_DIVISOR0 {1} \
      CONFIG.PCW_ENET0_PERIPHERAL_DIVISOR1 {1} \
      CONFIG.PCW_ENET1_PERIPHERAL_DIVISOR0 {1} \
      CONFIG.PCW_ENET1_PERIPHERAL_DIVISOR1 {1} \
      CONFIG.PCW_EN_CLK1_PORT {1} \
      CONFIG.PCW_FCLK0_PERIPHERAL_DIVISOR0 {8} \
      CONFIG.PCW_FCLK0_PERIPHERAL_DIVISOR1 {4} \
      CONFIG.PCW_FCLK1_PERIPHERAL_DIVISOR0 {8} \
      CONFIG.PCW_FCLK1_PERIPHERAL_DIVISOR1 {4} \
      CONFIG.PCW_FCLK2_PERIPHERAL_DIVISOR0 {1} \
      CONFIG.PCW_FCLK2_PERIPHERAL_DIVISOR1 {1} \
      CONFIG.PCW_FCLK3_PERIPHERAL_DIVISOR0 {1} \
      CONFIG.PCW_FCLK3_PERIPHERAL_DIVISOR1 {1} \
      CONFIG.PCW_FCLK_CLK1_BUF {TRUE} \
      CONFIG.PCW_FPGA_FCLK0_ENABLE {1} \
      CONFIG.PCW_FPGA_FCLK1_ENABLE {1} \
      CONFIG.PCW_FPGA_FCLK2_ENABLE {0} \
      CONFIG.PCW_FPGA_FCLK3_ENABLE {0} \
      CONFIG.PCW_I2C_PERIPHERAL_FREQMHZ {25} \
      CONFIG.PCW_IOPLL_CTRL_FBDIV {48} \
      CONFIG.PCW_IO_IO_PLL_FREQMHZ {1600.000} \
      CONFIG.PCW_PCAP_PERIPHERAL_DIVISOR0 {8} \
      CONFIG.PCW_QSPI_PERIPHERAL_DIVISOR0 {1} \
      CONFIG.PCW_SDIO_PERIPHERAL_DIVISOR0 {1} \
      CONFIG.PCW_SMC_PERIPHERAL_DIVISOR0 {1} \
      CONFIG.PCW_SPI_PERIPHERAL_DIVISOR0 {1} \
      CONFIG.PCW_TPIU_PERIPHERAL_DIVISOR0 {1} \
      CONFIG.PCW_UART_PERIPHERAL_DIVISOR0 {1} \
      CONFIG.PCW_UIPARAM_ACT_DDR_FREQ_MHZ {533.333374} \
      CONFIG.PCW_USE_S_AXI_HP0 {1} \
      CONFIG.PCW_USE_S_AXI_HP1 {0} \
      CONFIG.PCW_USE_S_AXI_HP2 {0} \
      ] $processing_system7_0

    # Create instance: ps7_0_axi_periph, and set properties
    set ps7_0_axi_periph [ \
      create_bd_cell -type ip \
      -vlnv xilinx.com:ip:axi_interconnect:2.1 ps7_0_axi_periph ]
    set_property -dict [ list \
      CONFIG.NUM_MI {1} \
      ] $ps7_0_axi_periph

    # Create instance: rst_ps7_0_50M, and set properties
    set rst_ps7_0_50M [ \
      create_bd_cell -type ip \
      -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_ps7_0_50M ]

    # Create instance: rst_ps7_0_50M1, and set properties
    set rst_ps7_0_50M1 [ \
      create_bd_cell -type ip \
      -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_ps7_0_50M1 ]

    # Create instance: system_ila_0, and set properties
    set system_ila_0 [ \
      create_bd_cell -type ip \
      -vlnv xilinx.com:ip:system_ila:1.1 system_ila_0 ]
    set_property -dict [ list \
      CONFIG.C_BRAM_CNT {17.5} \
      CONFIG.C_NUM_MONITOR_SLOTS {5} \
      CONFIG.C_SLOT {0} \
      CONFIG.C_SLOT_0_INTF_TYPE {xilinx.com:interface:axis_rtl:1.0} \
      CONFIG.C_SLOT_1_INTF_TYPE {xilinx.com:interface:axis_rtl:1.0} \
      CONFIG.C_SLOT_4_INTF_TYPE {xilinx.com:interface:axis_rtl:1.0} \
      CONFIG.C_SLOT_5_INTF_TYPE {xilinx.com:interface:axis_rtl:1.0} \
      ] $system_ila_0

    # Create instance: xlslice_0, and set properties
    set xlslice_0 [ \
      create_bd_cell -type ip \
      -vlnv xilinx.com:ip:xlslice:1.0 xlslice_0 ]
    set_property -dict [ list \
      CONFIG.DIN_FROM {31} \
      CONFIG.DIN_WIDTH {64} \
      CONFIG.DOUT_WIDTH {32} \
      ] $xlslice_0

    # Create instance: xlslice_1, and set properties
    set xlslice_1 [ \
      create_bd_cell -type ip \
      -vlnv xilinx.com:ip:xlslice:1.0 xlslice_1 ]
    set_property -dict [ list \
      CONFIG.DIN_FROM {63} \
      CONFIG.DIN_TO {32} \
      CONFIG.DIN_WIDTH {64} \
      CONFIG.DOUT_WIDTH {32} \
      ] $xlslice_1

    # Create interface connections
    connect_bd_intf_net -intf_net axi_fifo_mm_s_0_AXI_STR_TXD \
      [get_bd_intf_pins axi_fifo_mm_s_0/AXI_STR_TXD] \
      [get_bd_intf_pins axis_dwidth_converter_0/S_AXIS]
    connect_bd_intf_net -intf_net \
      [get_bd_intf_nets axi_fifo_mm_s_0_AXI_STR_TXD] \
      [get_bd_intf_pins axi_fifo_mm_s_0/AXI_STR_TXD] \
      [get_bd_intf_pins system_ila_0/SLOT_0_AXIS]
    connect_bd_intf_net -intf_net axis_data_fifo_1_M_AXIS \
      [get_bd_intf_pins axi_fifo_mm_s_0/AXI_STR_RXD] \
      [get_bd_intf_pins axis_data_fifo_1/M_AXIS]
    connect_bd_intf_net -intf_net \
      [get_bd_intf_nets axis_data_fifo_1_M_AXIS] \
      [get_bd_intf_pins axi_fifo_mm_s_0/AXI_STR_RXD] \
      [get_bd_intf_pins system_ila_0/SLOT_1_AXIS]
    connect_bd_intf_net -intf_net axis_dwidth_converter_0_M_AXIS \
      [get_bd_intf_pins axis_data_fifo_0/S_AXIS] \
      [get_bd_intf_pins axis_dwidth_converter_0/M_AXIS]
    connect_bd_intf_net -intf_net \
      [get_bd_intf_nets axis_dwidth_converter_0_M_AXIS] \
      [get_bd_intf_pins axis_dwidth_converter_0/M_AXIS] \
      [get_bd_intf_pins system_ila_0/SLOT_4_AXIS]
    connect_bd_intf_net -intf_net processing_system7_0_DDR \
      [get_bd_intf_ports DDR] \
      [get_bd_intf_pins processing_system7_0/DDR]
    connect_bd_intf_net -intf_net processing_system7_0_FIXED_IO \
      [get_bd_intf_ports FIXED_IO] \
      [get_bd_intf_pins processing_system7_0/FIXED_IO]
    connect_bd_intf_net -intf_net processing_system7_0_M_AXI_GP0 \
      [get_bd_intf_pins processing_system7_0/M_AXI_GP0] \
      [get_bd_intf_pins ps7_0_axi_periph/S00_AXI]
    connect_bd_intf_net -intf_net \
      [get_bd_intf_nets processing_system7_0_M_AXI_GP0] \
      [get_bd_intf_pins processing_system7_0/M_AXI_GP0] \
      [get_bd_intf_pins system_ila_0/SLOT_2_AXI]
    connect_bd_intf_net -intf_net ps7_0_axi_periph_M00_AXI \
      [get_bd_intf_pins axi_fifo_mm_s_0/S_AXI] \
      [get_bd_intf_pins ps7_0_axi_periph/M00_AXI]
    connect_bd_intf_net -intf_net \
      [get_bd_intf_nets ps7_0_axi_periph_M00_AXI] \
      [get_bd_intf_pins ps7_0_axi_periph/M00_AXI] \
      [get_bd_intf_pins system_ila_0/SLOT_3_AXI]

    # Create port connections
    connect_bd_net -net axis_data_fifo_0_m_axis_tdata \
      [get_bd_pins axis_data_fifo_0/m_axis_tdata] \
      [get_bd_pins ila_0/probe0] \
      [get_bd_pins xlslice_0/Din] \
      [get_bd_pins xlslice_1/Din]
    connect_bd_net -net axis_data_fifo_0_m_axis_tlast \
      [get_bd_pins axis_data_fifo_0/m_axis_tlast] \
      [get_bd_pins axis_data_fifo_1/s_axis_tlast]
    connect_bd_net -net axis_data_fifo_0_m_axis_tvalid \
      [get_bd_pins axis_data_fifo_0/m_axis_tvalid] \
      [get_bd_pins axis_data_fifo_1/s_axis_tvalid] \
      [get_bd_pins ila_0/probe2]
    connect_bd_net -net axis_data_fifo_1_s_axis_tready \
      [get_bd_pins axis_data_fifo_0/m_axis_tready] \
      [get_bd_pins axis_data_fifo_1/s_axis_tready] \
      [get_bd_pins ila_0/probe1]
    connect_bd_net -net mult_0_c \
      [get_bd_pins axis_data_fifo_1/s_axis_tdata] \
      [get_bd_pins mult_0/c]
    connect_bd_net -net processing_system7_0_FCLK_CLK0 \
      [get_bd_pins axi_fifo_mm_s_0/s_axi_aclk] \
      [get_bd_pins axis_data_fifo_0/s_axis_aclk] \
      [get_bd_pins axis_data_fifo_1/m_axis_aclk] \
      [get_bd_pins axis_dwidth_converter_0/aclk] \
      [get_bd_pins processing_system7_0/FCLK_CLK0] \
      [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK] \
      [get_bd_pins processing_system7_0/S_AXI_HP0_ACLK] \
      [get_bd_pins ps7_0_axi_periph/ACLK] \
      [get_bd_pins ps7_0_axi_periph/M00_ACLK] \
      [get_bd_pins ps7_0_axi_periph/S00_ACLK] \
      [get_bd_pins rst_ps7_0_50M/slowest_sync_clk] \
      [get_bd_pins system_ila_0/clk]
    connect_bd_net -net processing_system7_0_FCLK_CLK1 \
      [get_bd_pins axis_data_fifo_0/m_axis_aclk] \
      [get_bd_pins axis_data_fifo_1/s_axis_aclk] \
      [get_bd_pins ila_0/clk] \
      [get_bd_pins processing_system7_0/FCLK_CLK1] \
      [get_bd_pins rst_ps7_0_50M1/slowest_sync_clk]
    connect_bd_net -net processing_system7_0_FCLK_RESET0_N \
      [get_bd_pins processing_system7_0/FCLK_RESET0_N] \
      [get_bd_pins rst_ps7_0_50M/ext_reset_in] \
      [get_bd_pins rst_ps7_0_50M1/ext_reset_in]
    connect_bd_net -net rst_ps7_0_50M1_peripheral_aresetn \
      [get_bd_pins axis_data_fifo_1/s_axis_aresetn] \
      [get_bd_pins rst_ps7_0_50M1/peripheral_aresetn]
    connect_bd_net -net rst_ps7_0_50M_peripheral_aresetn \
      [get_bd_pins axi_fifo_mm_s_0/s_axi_aresetn] \
      [get_bd_pins axis_data_fifo_0/s_axis_aresetn] \
      [get_bd_pins axis_dwidth_converter_0/aresetn] \
      [get_bd_pins ps7_0_axi_periph/ARESETN] \
      [get_bd_pins ps7_0_axi_periph/M00_ARESETN] \
      [get_bd_pins ps7_0_axi_periph/S00_ARESETN] \
      [get_bd_pins rst_ps7_0_50M/peripheral_aresetn] \
      [get_bd_pins system_ila_0/resetn]
    connect_bd_net -net xlslice_0_Dout \
      [get_bd_pins mult_0/a] \
      [get_bd_pins xlslice_0/Dout]
    connect_bd_net -net xlslice_1_Dout \
      [get_bd_pins mult_0/b] \
      [get_bd_pins xlslice_1/Dout]

    # Create address segments
    assign_bd_address -offset 0x40010000 \
      -range 0x00001000 -target_address_space \
      [get_bd_addr_spaces processing_system7_0/Data] \
      [get_bd_addr_segs axi_fifo_mm_s_0/S_AXI/Mem0] \
      -force

    # Restore current instance
    current_bd_instance $oldCurInst

    validate_bd_design
    save_bd_design
    close_bd_design $design_name 
  }
  # End of cr_bd_pynq()
  cr_bd_pynq ""
  set_property REGISTERED_WITH_MANAGER "1" [get_files pynq.bd ] 
  set_property SYNTH_CHECKPOINT_MODE "Hierarchical" [get_files pynq.bd ] 

  #call make_wrapper to create wrapper files
  set wrapper_path [make_wrapper -fileset sources_1 \
    -files [ get_files -norecurse pynq.bd] -top]
  add_files -norecurse -fileset sources_1 $wrapper_path
}

proc setup_runs { } {
  #### Set up the synthesis and implementation runs
  # Create 'synth_1' run (if not found)
  if {[string equal [get_runs -quiet synth_1] ""]} {
    create_run -name synth_1 \
      -part xc7z020clg400-1 \
      -flow {Vivado Synthesis 2021} \
      -strategy "Vivado Synthesis Defaults" \
      -report_strategy {No Reports} \
      -constrset constrs_1
  } else {
    set_property strategy "Vivado Synthesis Defaults" [get_runs synth_1]
    set_property flow "Vivado Synthesis 2021" [get_runs synth_1]
  }

  if {[string equal [get_runs -quiet impl_1] ""]} {
    create_run -name impl_1 \
      -part xc7z020clg400-1 \
      -flow {Vivado Implementation 2021} \
      -strategy "Vivado Implementation Defaults" \
      -report_strategy {No Reports} \
      -constrset constrs_1 \
      -parent_run synth_1
  } else {
    set_property strategy "Vivado Implementation Defaults" [get_runs impl_1]
    set_property flow "Vivado Implementation 2021" [get_runs impl_1]
  }
}

proc execute_runs { } {
  #### Actually run the synthesis and implementation
  launch_runs impl_1 -to_step write_bitstream -jobs 8
  wait_on_run impl_1
}


proc check_status { } {
  #### Check the status of the runs.  If they completed successfully, 
  # then copy the .bit and .hwh file to the build directory
  # The hwh file will be present in the .gen folder, not the impl folder
  set impl_status [get_property status [get_runs impl_1]]
  if { $impl_status eq "write_bitstream Complete!" } {
    set project_path [get_property directory [current_project]]
    set project_file [file rootname $project_path]
    set __project [current_project]
    set hw_dir [file dirname [get_files *.hwh]]
    set hwhandoff [glob [file join $hw_dir *.hwh]]
    set bitstream [glob [file join $project_path $__project.runs impl_1 *.bit]]

    #gather in the .prj directory
    file copy -force $hwhandoff $project_file.hwh
    file copy -force $bitstream $project_file.bit
    puts "The .bit and .hwh files should be available now in $project_path"
    puts "Copy them over to the Pynq board using scp or rsync"
  } else {
    puts "Implementation failed.  Check the logs."
  }
}

# Run the script
create_proj
setup_runs
execute_runs
check_status
close_project
