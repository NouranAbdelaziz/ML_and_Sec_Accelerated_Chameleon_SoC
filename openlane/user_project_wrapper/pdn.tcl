# SPDX-FileCopyrightText: 2020 Efabless Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# SPDX-License-Identifier: Apache-2.0

# Power nets
set ::power_nets $::env(_VDD_NET_NAME)
set ::ground_nets $::env(_GND_NET_NAME)

if { $::env(CONNECT_GRIDS) } {
	pdngen::specify_grid stdcell {
	    name grid
		core_ring {
			met5 {width $::env(_WIDTH) spacing $::env(_SPACING) core_offset $::env(_H_OFFSET)}
			met4 {width $::env(_WIDTH) spacing $::env(_SPACING) core_offset $::env(_V_OFFSET)}
		}
		rails {
		    met1 {width $::env(FP_PDN_RAIL_WIDTH) pitch $::env(PLACE_SITE_HEIGHT) offset $::env(FP_PDN_RAIL_OFFSET)}
	    }
	    straps {
		    met4 {width $::env(_WIDTH) pitch $::env(_V_PITCH) offset $::env(_V_PDN_OFFSET)}
		    met5 {width $::env(_WIDTH) pitch $::env(_H_PITCH) offset $::env(_H_PDN_OFFSET)}
	    }
	    connect {{met1 met4} {met4 met5}}
	}
} else {
	pdngen::specify_grid stdcell {
	    name grid
		core_ring {
			met5 {width $::env(_WIDTH) spacing $::env(_SPACING) core_offset $::env(_H_OFFSET)}
			met4 {width $::env(_WIDTH) spacing $::env(_SPACING) core_offset $::env(_V_OFFSET)}
		}
		rails {
		    met1 {width $::env(FP_PDN_RAIL_WIDTH) pitch $::env(PLACE_SITE_HEIGHT) offset $::env(FP_PDN_RAIL_OFFSET)}
	    }
	   
	    connect {{met4 met5}}
	}
}

pdngen::specify_grid macro {
	instance "obs_core_obs"
    power_pins $::env(_VDD_NET_NAME)
    ground_pins $::env(_GND_NET_NAME)
    blockages "li1 met1 met2 met3 met4 met5"
    straps { 
    } 
    connect {}
}

if { $::env(CONNECT_GRIDS) } {
	pdngen::specify_grid macro {
	    orient {R0 R180 MX MY R90 R270 MXR90 MYR90}
	    power_pins "VPWR"
	    ground_pins "VGND"
	    blockages "li1 met1 met2 met3 met4"
	    straps { 
	    } 
	    connect {{met4_PIN_ver met5}}
	}
} else {
	pdngen::specify_grid macro {
	    orient {R0 R180 MX MY R90 R270 MXR90 MYR90}
	    power_pins "VPWR"
	    ground_pins "VGND"
	    blockages "li1 met1 met2 met3 met4"
	    straps { 
	    } 
	    connect {}
	}
}

set ::halo 5

# POWER or GROUND #Std. cell rails starting with power or ground rails at the bottom of the core area
set ::rails_start_with "POWER" ;

# POWER or GROUND #Upper metal stripes starting with power or ground rails at the left/bottom of the core area
set ::stripes_start_with "POWER" ;
