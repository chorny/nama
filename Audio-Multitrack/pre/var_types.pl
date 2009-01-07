
@global_vars = qw(
						$effects_cache_file
						$ladspa_sample_rate
						$state_store_file
						$chain_setup_file
						$tk_input_channels
						$use_monitor_version_for_mixdown 
						$unit								);
						
@config_vars = qw(
						%abbreviations
						%devices
						$ecasound_globals
						$mix_to_disk_format
						$raw_to_disk_format
						$mixer_out_format
						$mixer_out_device
						$record_device	
						$project_root 	
 						$controller_ports
						$jack_enable
						$use_pager    );

						
						

@persistent_vars = qw(

						%cops 			
						$cop_id 		
						%copp 			
						%marks			
						$unit			
						%oid_status		
						%old_vol		
						$this_op
						@tracks_data
						@groups_data
						@marks_data
						$loop_enable
						@loop_endpoints
						$length
						$jack_enable
						$mixer_out_device_jack

						);
					 
@effects_static_vars = qw(

						@effects		
						%effect_i	
						%e_bound
						@ladspa_sorted
						%effects_ladspa	
						%effects_ladspa_file
						);
					


@effects_dynamic_vars = qw(

						%state_c_ops
						%cops    
						$cop_id     
						%copp   
						@marks 	
						$unit				);



@status_vars = qw(

						%state_c
						%state_t
						%copp
						%cops
						%post_input
						%pre_output   
						%inputs
						%outputs      );


