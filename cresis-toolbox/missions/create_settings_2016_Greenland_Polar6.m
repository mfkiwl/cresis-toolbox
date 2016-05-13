% script create_settings_2016_Greenland_Polar6
%
% Creates NI radar depth sounder settings
%
% See link_budgets.xls

physical_constants; % c = speed of light

% Define waveforms
if ispc
  base_dir = 'c:\waveforms\';
else
  base_dir = '~/waveforms/';
end

f0_list = [150e6 180e6 320e6];
f1_list = [520e6 210e6 350e6];
DDC_select_list = [1 1 1]; % Which DDC mode to use
cal_settings = [1 2 1];
prf = 10000;

% presums: Ensure lambda/4 sampling (fudge factor allows difference) and an
%   that presums are an even number.
velocity = [65 90 65]; % m/s
presums = round(c./abs(f1_list+f0_list)/2 ./ velocity * prf / 2)*2

final_DDS_phase = [];
final_DDS_phase_no_time = [];
final_DDS_amp = [];
final_DDS_time = [];
if 0
  % Initial conditions (usually all zeros phase/time with max amplitude)
  for idx = 1:length(f0_list)
    final_DDS_phase{idx} = [0 0 0 0 0 0 0 0];
    final_DDS_phase_no_time = [0 0 0 0 0 0 0 0]; % not used usually
    final_DDS_amp{idx} = [4000 4000 4000 4000 4000 4000 4000 4000];
    final_DDS_time{idx} =  [0 0 0 0 0 0 0 0];
  end
else
  % COPY AND PASTE RESULTS FROM basic_tx_chan_equalization_SEASON_NAME.m
  % HERE:
  
  % These are from transmit calibration during 20160401 test flight  
  % NOTE: These values are valid for when DDS channels 5-8 come up one 1440
  % MHz clock cycle after channels 1-4.
  
  % 150-520 MHz
  final_DDS_phase{end+1} = [63.3	86.1	-16.5	0.0	8.9	-17.4	68.8	51.1];
  final_DDS_phase_no_time{end+1} = [0 0 0 0 0 0 0 0]; % not used usually
  final_DDS_amp{end+1} = [1312	2849	2657	3572	4000	2618	2574	1386];
  final_DDS_time{end+1} =  [-2.62	-2.35	-0.13	0.00	-0.56	-0.82	-3.30	-3.50];
    
  % 180-210 MHz
  final_DDS_phase{end+1} = [61.4	85.2	-15.1	0.0	8.7	-1.0	76.8	56.1];
  final_DDS_phase_no_time{end+1} = [0 0 0 0 0 0 0 0]; % not used usually
  final_DDS_amp{end+1} = [1172	2550	3026	3650	4000	3106	2361	1223];
  final_DDS_time{end+1} =  [-2.62	-2.35	-0.13	0.00	-0.56	-0.82	-3.30	-3.50];  
  
  % 320-350 MHz
  final_DDS_phase{end+1} = [63.3	86.1	-16.5	0.0	8.9	-17.4	68.8	51.1];
  final_DDS_phase_no_time{end+1} = [0 0 0 0 0 0 0 0]; % not used usually
  final_DDS_amp{end+1} = [1312	2849	2657	3572	4000	2618	2574	1386];
  final_DDS_time{end+1} =  [-2.62	-2.35	-0.13	0.00	-0.56	-0.82	-3.30	-3.50];
end

% Base settings are with DDS channels 1-4 perfectly aligned and 5-8 all 
% offset behind 1-4 by 1/1440 MHz = 0.6944 ns.
if 1
  fprintf('Typical clock corrections:\n');
  fprintf(' [0 0 0 0 0 0 0 0]: Use this correction when 1-4 are aligned and 5-8 are lagging by 0.69 ns *\n');
  fprintf(' [0 0 0 0 1 1 1 1]: Use this correction when 1-8 are aligned\n');
  fprintf('Example of some other cases for understanding:\n');
  fprintf(' [0 0 0 0 1 0 1 1]: Use this correction when 1-5 & 7-8 are aligned and 6 is lagging by 0.69 ns\n');
  fprintf(' [0 0 0 0 1 0 0 0]: Use this correction when 1-5 are aligned and 6-8 are lagging by 0.69 ns\n');
  fprintf('Recalibrate DDS if correction requires <0 or >0.69 ns correction.\n');
  user_clock_correction = [];
  while length(user_clock_correction) ~= 8
    user_clock_correction = input('Please enter the clock cycle correction for each DDS [0 0 0 0 0 0 0 0]: ');
    if isempty(user_clock_correction)
      user_clock_correction = zeros(1,8);
    end
  end
  % If all DDS channels (1-8) are all perfectly aligned, then a single DDC
  % clock cycle needs to be added to channels 5-8:
  for freq_idx = 1:length(f0_list)
    final_DDS_time{freq_idx} =  final_DDS_time{freq_idx} ...
      + 6.9444e-1 * user_clock_correction;
  end
end

% Hwindow_orig: Desired window created during transmit calibration
%  This is used any time a window that is different from that used
%  during calibration is to be used.
Hwindow_orig = chebwin(8,30).';

%% SETUP
% =========================================================================

param = [];
param.season_name = '2016_Greenland_Polar6';
param.radar_name = 'rds';
param.gps_source = 'awi-final';
clear phase_centers;
for tx_chan = 1:8
  % Just enable the current antenna to determine its phase center
  tx_weights = zeros(1,8);
  tx_weights(tx_chan) = 1;
  rxchan = 12; % Fix the receiver (it should not matter which one you choose)
  % Determine phase center for the antenna
  phase_centers(:,tx_chan) = lever_arm(param, tx_weights, rxchan);
end
% Adjust phase centers to the mean phase center position
phase_centers = bsxfun(@minus,phase_centers,mean(phase_centers,2));

% Create waveforms directories if they do not exist
if ~exist(base_dir,'dir')
  mkdir(base_dir);
end
calval_dir = fullfile(base_dir, 'calval');
if ~exist(calval_dir,'dir')
  mkdir(calval_dir);
end

%% Survey Mode + loopback, noise, and deconv modes
% <3250 m thick ice, 1200 +/- 700 ft AGL
ice_thickness = [3250 3250];
for freq_idx = [1 2]
  param = struct('radar_name','mcords5','num_chan',24,'aux_dac',[255 255 255 255 255 255 255 255],'version','14.0f1','TTL_prog_delay',650,'xml_version',2.0,'fs',1600e6,'fs_sync',90.0e6,'fs_dds',1440e6,'TTL_mode',[2.5e-6 260e-9 -1100e-9]);
  param.max_tx = [4000 4000 4000 4000 4000 4000 4000 4000]; param.max_data_rate = 750; param.flight_hours = 3.5; param.sys_delay = 0.75e-6; param.use_mcords4_names = true;
  param.DDC_select = DDC_select_list(freq_idx);
  param.max_duty_cycle = 0.12;
  param.create_IQ = false;
  param.tg.staged_recording = [1 2 3];
  param.tg.altitude_guard = 700*12*2.54/100;
  param.tg.Haltitude = 1200*12*2.54/100;
  param.tg.Hice_thick = ice_thickness(freq_idx);
  param.prf = prf;
  param.presums = [2 4 presums(freq_idx)-6];
  param.wfs(1).atten = 37;
  param.wfs(2).atten = 0;
  param.wfs(3).atten = 0;
  DDS_amp = final_DDS_amp{cal_settings(freq_idx)};
  param.tx_weights = DDS_amp;
  param.tukey = 0.08;
  param.wfs(1).Tpd = 1e-6;
  param.wfs(2).Tpd = 3e-6;
  param.wfs(3).Tpd = 10e-6;
  param.wfs(1).phase = final_DDS_phase{cal_settings(freq_idx)};
  param.wfs(2).phase = final_DDS_phase{cal_settings(freq_idx)};
  param.wfs(3).phase = final_DDS_phase{cal_settings(freq_idx)};
  param.delay = final_DDS_time{cal_settings(freq_idx)};
  param.f0 = f0_list(freq_idx);
  param.f1 = f1_list(freq_idx);
  param.DDC_freq = (param.f0+param.f1)/2;
  [param.wfs(1:3).tx_mask] = deal([0 0 0 0 0 0 0 0]);
  param.fn = fullfile(base_dir,sprintf('survey_%.0f-%.0fMHz_%.0fft_%.0fus_%.0fmthick.xml',param.f0/1e6,param.f1/1e6,param.tg.Haltitude*100/12/2.54,param.wfs(end).Tpd*1e6,param.tg.Hice_thick));
  write_cresis_xml(param);
  if freq_idx == 1
    % Default Mode
    param.fn = fullfile(base_dir,'default.xml');
    write_cresis_xml(param);
  end
  % Loopback Mode without delay line
  param.tg.staged_recording = false;
  param.tg.altitude_guard = 1000*12*2.54/100;
  param.tg.Haltitude = 0e-6 * c/2;
  param.tg.Hice_thick = 0; % Long enough for 10 us delay line
  param.fn = fullfile(calval_dir,sprintf('survey_%.0f-%.0fMHz_%.0fus_LOOPBACK_NO_DELAY.xml',param.f0/1e6,param.f1/1e6,param.wfs(end).Tpd*1e6));
  write_cresis_xml(param);
  % Loopback Mode (10e-6 delay line)
  param.tg.staged_recording = false;
  param.tg.altitude_guard = 1000*12*2.54/100;
  param.tg.Haltitude = 10e-6 * c/2;
  param.tg.Hice_thick = 0; % Long enough for 10 us delay line
  param.fn = fullfile(calval_dir,sprintf('survey_%.0f-%.0fMHz_%.0fus_LOOPBACK.xml',param.f0/1e6,param.f1/1e6,param.wfs(end).Tpd*1e6));
  write_cresis_xml(param);
  % Deconvolution Mode (for over calm lake or sea ice lead)
  param.wfs(1).atten = 43;
  param.wfs(2).atten = 43;
  param.wfs(3).atten = 43;
  param.tg.staged_recording = false;
  param.tg.altitude_guard = 3000*12*2.54/100;
  param.tg.Haltitude = 4000*12*2.54/100;
  param.tg.Hice_thick = 0 * 12*2.54/100/sqrt(er_ice);
  param.fn = fullfile(calval_dir,sprintf('survey_%.0f-%.0fMHz_%.0fft_%.0fus_DECONV.xml',param.f0/1e6,param.f1/1e6,param.tg.Haltitude*100/12/2.54,param.wfs(end).Tpd*1e6));
  write_cresis_xml(param);
  if freq_idx == 1
    % Noise Mode
    param.tx_weights = [0 0 0 0 0 0 0 0];
    [param.wfs(1:3).tx_mask] = deal([1 1 1 1 1 1 1 1]);
    param.wfs(1).atten = 37;
    param.wfs(2).atten = 0;
    param.wfs(3).atten = 0;
    param.tg.staged_recording = [1 2 3];
    param.tg.altitude_guard = 500*12*2.54/100;
    param.tg.Haltitude = 1400*12*2.54/100;
    param.tg.Hice_thick = 3250;
    param.fn = fullfile(calval_dir,sprintf('survey_%.0f-%.0fMHz_%.0fus_NOISE.xml',param.f0/1e6,param.f1/1e6,param.wfs(end).Tpd*1e6));
    write_cresis_xml(param);
  end
end


%% Survey Mode for thin ice
% <2500 m thick ice, 1200 +/- 700 ft AGL
ice_thickness = [2500 2500];
for freq_idx = [1 2]
  param = struct('radar_name','mcords5','num_chan',24,'aux_dac',[255 255 255 255 255 255 255 255],'version','14.0f1','TTL_prog_delay',650,'xml_version',2.0,'fs',1600e6,'fs_sync',90.0e6,'fs_dds',1440e6,'TTL_mode',[2.5e-6 260e-9 -1100e-9]);
  param.max_tx = [4000 4000 4000 4000 4000 4000 4000 4000]; param.max_data_rate = 750; param.flight_hours = 3.5; param.sys_delay = 0.75e-6; param.use_mcords4_names = true;
  param.DDC_select = DDC_select_list(freq_idx);
  param.max_duty_cycle = 0.12;
  param.create_IQ = false;
  param.tg.staged_recording = [1 2 3];
  param.tg.rg_stop_offset = [500*sqrt(3.15) 0 0]; % Keep waveform 1 on for 500 m of ice
  param.tg.altitude_guard = 700*12*2.54/100;
  param.tg.Haltitude = 1200*12*2.54/100;
  param.tg.Hice_thick = ice_thickness(freq_idx);
  param.prf = prf;
  param.presums = [8 2 presums(freq_idx)-10];
  param.wfs(1).atten = 35;
  param.wfs(2).atten = 0;
  param.wfs(3).atten = 0;
  DDS_amp = final_DDS_amp{cal_settings(freq_idx)};
  param.tx_weights = DDS_amp;
  param.tukey = 0.08;
  param.wfs(1).Tpd = 1e-6;
  param.wfs(2).Tpd = 1e-6;
  param.wfs(3).Tpd = 3e-6;
  param.wfs(1).phase = final_DDS_phase{cal_settings(freq_idx)};
  param.wfs(2).phase = final_DDS_phase{cal_settings(freq_idx)};
  param.wfs(3).phase = final_DDS_phase{cal_settings(freq_idx)};
  param.delay = final_DDS_time{cal_settings(freq_idx)};
  param.f0 = f0_list(freq_idx);
  param.f1 = f1_list(freq_idx);
  param.DDC_freq = (param.f0+param.f1)/2;
  [param.wfs(1:3).tx_mask] = deal([0 0 0 0 0 0 0 0]);
  param.fn = fullfile(base_dir,sprintf('thinice_%.0f-%.0fMHz_%.0fft_%.0fus_%.0fmthick.xml',param.f0/1e6,param.f1/1e6,param.tg.Haltitude*100/12/2.54,param.wfs(end).Tpd*1e6,param.tg.Hice_thick));
  write_cresis_xml(param);
end


%% Sea Ice
% 1200 +/- 1200 ft AGL
for freq_idx = [1]
  param = struct('radar_name','mcords5','num_chan',24,'aux_dac',[255 255 255 255 255 255 255 255],'version','14.0f1','TTL_prog_delay',650,'xml_version',2.0,'fs',1600e6,'fs_sync',90.0e6,'fs_dds',1440e6,'TTL_mode',[2.5e-6 260e-9 -1100e-9]);
  param.max_tx = [4000 4000 4000 4000 4000 4000 4000 4000]; param.max_data_rate = 750; param.flight_hours = 3.5; param.sys_delay = 0.75e-6; param.use_mcords4_names = true;
  param.DDC_select = DDC_select_list(freq_idx);
  param.max_duty_cycle = 0.12;
  param.create_IQ = false;
  param.tg.staged_recording = [0 0];
  param.tg.rg_stop_offset = [0 0]; % Keep waveform 1 on for 500 m of ice
  param.tg.altitude_guard = 1200*12*2.54/100;
  param.tg.Haltitude = 1200*12*2.54/100;
  param.tg.Hice_thick = 0;
  param.prf = prf;
  param.presums = [presums(freq_idx)/2 presums(freq_idx)/2];
  param.wfs(1).atten = 13;
  param.wfs(2).atten = 13;
  DDS_amp = final_DDS_amp{cal_settings(freq_idx)};
  param.tx_weights = DDS_amp;
  param.tukey = 0.08;
  param.wfs(1).Tpd = 1e-6;
  param.wfs(2).Tpd = 1e-6;
  param.wfs(1).phase = final_DDS_phase{cal_settings(freq_idx)};
  param.wfs(2).phase = final_DDS_phase{cal_settings(freq_idx)};
  param.delay = final_DDS_time{cal_settings(freq_idx)};
  param.f0 = f0_list(freq_idx);
  param.f1 = f1_list(freq_idx);
  param.DDC_freq = (param.f0+param.f1)/2;
  param.wfs(1).tx_mask = deal([0 1 1 1 1 1 1 1]);
  param.wfs(2).tx_mask = deal([1 1 1 1 1 1 1 0]);
  param.fn = fullfile(base_dir,sprintf('seaice_%.0f-%.0fMHz_%.0fft_%.0fus_%.0fmthick.xml',param.f0/1e6,param.f1/1e6,param.tg.Haltitude*100/12/2.54,param.wfs(end).Tpd*1e6,param.tg.Hice_thick));
  write_cresis_xml(param);
end

%% Image Mode (Low Altitude, Thick Ice)
% Ice thickness "param.tg.Hice_thick_min" m to "param.tg.Hice_thick" m, "param.tg.Haltitude" +/- "param.tg.altitude_guard" ft AGL
for freq_idx = [1 2]
  param = struct('radar_name','mcords5','num_chan',24,'aux_dac',[255 255 255 255 255 255 255 255],'version','14.0f1','TTL_prog_delay',650,'xml_version',2.0,'fs',1600e6,'fs_sync',90.0e6,'fs_dds',1440e6,'TTL_mode',[2.5e-6 260e-9 -1100e-9]);
  param.max_tx = [4000 4000 4000 4000 4000 4000 4000 4000]; param.max_data_rate = 700; param.flight_hours = 3.5; param.sys_delay = 0.75e-6; param.use_mcords4_names = true;
  param.max_data_rate = 755;
  param.DDC_select = DDC_select_list(freq_idx);
  param.max_duty_cycle = 0.12;
  param.create_IQ = false;
  param.tg.staged_recording = [0 0 0];
  param.tg.start_ref = {'bottom','surface','bottom'};
  param.tg.stop_ref = {'bottom','surface','bottom'};
  param.tg.altitude_guard = 700 * 12*2.54/100;
  param.tg.Haltitude = 1200 * 12*2.54/100;
  param.tg.Hice_thick_min = 1500;
  param.tg.Hice_thick = 3000;
  param.tg.look_angle_deg = [40 0 40];
  param.prf = prf;
  param.presums = [ceil(presums(freq_idx)/4)*2 2 ceil(presums(freq_idx)/4)*2];
  % Switch from tx calibration window to hanning window to broaden beam
  DDS_amp = final_DDS_amp{freq_idx} .* hanning(8).' ./ Hwindow_orig;
  % Renormalize the amplitudes
  [~,relative_max_idx] = max(DDS_amp./param.max_tx);
  DDS_amp = round(DDS_amp .* param.max_tx(relative_max_idx) / DDS_amp(relative_max_idx));
  param.tx_weights = DDS_amp;
  param.tukey = 0.08;
  param.wfs(1).Tpd = 10e-6;
  param.wfs(2).Tpd = 1e-6;
  param.wfs(3).Tpd = 10e-6;
  param.wfs(1).phase = final_DDS_phase{freq_idx};
  param.wfs(2).phase = final_DDS_phase{freq_idx};
  param.wfs(3).phase = final_DDS_phase{freq_idx};
  % Add in time delays to each position, subtract out the nadir time delays since tx_equalization already took care of those
  beam_angle_deg = 20; % Positive to the left
  param.wfs(1).delay = final_DDS_time{freq_idx} ...
    - (phase_centers(2,:) / (c/2) * sind(beam_angle_deg))*1e9 ...
    - (phase_centers(3,:) / (c/2) * cosd(beam_angle_deg))*1e9 ...
    + (phase_centers(3,:) / (c/2) * cosd(0))*1e9;
  beam_angle_deg = 0; % Nadir
  param.wfs(2).delay = final_DDS_time{freq_idx} ...
    - (phase_centers(2,:) / (c/2) * sind(beam_angle_deg))*1e9 ...
    - (phase_centers(3,:) / (c/2) * cosd(beam_angle_deg))*1e9 ...
    + (phase_centers(3,:) / (c/2) * cosd(0))*1e9;
  beam_angle_deg = -20; % Negative to the right
  param.wfs(3).delay = final_DDS_time{freq_idx} ...
    - (phase_centers(2,:) / (c/2) * sind(beam_angle_deg))*1e9 ...
    - (phase_centers(3,:) / (c/2) * cosd(beam_angle_deg))*1e9 ...
    + (phase_centers(3,:) / (c/2) * cosd(0))*1e9;
  param.f0 = f0_list(freq_idx);
  param.f1 = f1_list(freq_idx);
  param.DDC_freq = (param.f0+param.f1)/2;
  [param.wfs(1:3).tx_mask] = deal([0 0 0 0 0 0 0 0]);
  param.wfs(1).atten = 0;
  param.wfs(2).atten = 37;
  param.wfs(3).atten = 0;
  param.fn = fullfile(base_dir,sprintf('image_%.0f-%.0fMHz_%.0fft_%.0fus_%.0fmthick.xml', ...
    param.f0/1e6,param.f1/1e6,param.tg.Haltitude*100/2.54/12,param.wfs(end).Tpd*1e6,param.tg.Hice_thick));
  write_cresis_xml(param);
end

%% Image Mode Pattern Measurements
% 3500 ft +/- 1000 ft AGL
for freq_idx = [1 2]
  param = struct('radar_name','mcords5','num_chan',24,'aux_dac',[255 255 255 255 255 255 255 255],'version','14.0f1','TTL_prog_delay',650,'xml_version',2.0,'fs',1600e6,'fs_sync',90.0e6,'fs_dds',1440e6,'TTL_mode',[2.5e-6 260e-9 -1100e-9]);
  param.max_tx = [4000 4000 4000 4000 4000 4000 4000 4000]; param.max_data_rate = 700; param.flight_hours = 3.5; param.sys_delay = 0.75e-6; param.use_mcords4_names = true;
  param.max_data_rate = 755;
  param.DDC_select = DDC_select_list(freq_idx);
  param.max_duty_cycle = 0.12;
  param.create_IQ = false;
  param.tg.staged_recording = [0 0];
  param.tg.start_ref = {'surface','surface'};
  param.tg.altitude_guard = 1000 * 12*2.54/100;
  param.tg.Haltitude = 3500 * 12*2.54/100;
  param.tg.Hice_thick_min = 0;
  param.tg.Hice_thick = 0;
  param.tg.look_angle_deg = [0 0 0];
  param.prf = prf;
  param.presums = [ceil(presums(freq_idx)/4)*2 ceil(presums(freq_idx)/4)*2];
  % Switch from tx calibration window to hanning window to broaden beam
  DDS_amp = final_DDS_amp{freq_idx} .* hanning(8).' ./ Hwindow_orig;
  % Renormalize the amplitudes
  [~,relative_max_idx] = max(DDS_amp./param.max_tx);
  DDS_amp = round(DDS_amp .* param.max_tx(relative_max_idx) / DDS_amp(relative_max_idx));
  param.tx_weights = DDS_amp;
  param.tukey = 0.08;
  param.wfs(1).Tpd = 3e-6;
  param.wfs(2).Tpd = 3e-6;
  param.wfs(1).phase = final_DDS_phase{freq_idx};
  param.wfs(2).phase = final_DDS_phase{freq_idx};
  % Add in time delays to each position, subtract out the nadir time delays since tx_equalization already took care of those
  beam_angle_deg = 20; % Positive to the left
  param.wfs(1).delay = final_DDS_time{freq_idx} ...
    - (phase_centers(2,:) / (c/2) * sind(beam_angle_deg))*1e9 ...
    - (phase_centers(3,:) / (c/2) * cosd(beam_angle_deg))*1e9 ...
    + (phase_centers(3,:) / (c/2) * cosd(0))*1e9;
  beam_angle_deg = -20; % Negative to the right
  param.wfs(2).delay = final_DDS_time{freq_idx} ...
    - (phase_centers(2,:) / (c/2) * sind(beam_angle_deg))*1e9 ...
    - (phase_centers(3,:) / (c/2) * cosd(beam_angle_deg))*1e9 ...
    + (phase_centers(3,:) / (c/2) * cosd(0))*1e9;
  param.f0 = f0_list(freq_idx);
  param.f1 = f1_list(freq_idx);
  param.DDC_freq = (param.f0+param.f1)/2;
  [param.wfs(1:2).tx_mask] = deal([0 0 0 0 0 0 0 0]);
  [param.wfs(1:2).atten] = deal(43);
  param.fn = fullfile(calval_dir,sprintf('image_%.0f-%.0fMHz_%.0fft_%.0fus_PATTERN.xml', ...
    param.f0/1e6,param.f1/1e6,param.tg.Haltitude*100/2.54/12,param.wfs(end).Tpd*1e6));
  write_cresis_xml(param);
end

%% Image Mode (High Altitude, Thin Ice)
% Ice thickness "param.tg.Hice_thick_min" m to "param.tg.Hice_thick" m, "param.tg.Haltitude" +/- "param.tg.altitude_guard" ft AGL
freq_idx_WB = 1;
freq_idx_NB = 3;
param = struct('radar_name','mcords5','num_chan',24,'aux_dac',[255 255 255 255 255 255 255 255],'version','14.0f1','TTL_prog_delay',650,'xml_version',2.0,'fs',1600e6,'fs_sync',90.0e6,'fs_dds',1440e6,'TTL_mode',[2.5e-6 260e-9 -1100e-9]);
param.max_tx = [4000 4000 4000 4000 4000 4000 4000 4000]; param.max_data_rate = 700; param.flight_hours = 3.5; param.sys_delay = 0.75e-6; param.use_mcords4_names = true;
param.max_data_rate = 755;
param.DDC_select = DDC_select_list(freq_idx_WB);
param.max_duty_cycle = 0.12;
param.create_IQ = false;
param.tg.staged_recording = [0 0 0];
param.tg.start_ref = {'bottom','surface','bottom'};
param.tg.stop_ref = {'bottom','bottom','bottom'};
param.tg.altitude_guard = 1000 * 12*2.54/100;
param.tg.Haltitude = 6000 * 12*2.54/100;
param.tg.Hice_thick_min = 0;
param.tg.Hice_thick = 1000;
param.tg.look_angle_deg = [40 0 40];
param.prf = prf;
param.presums = [ceil(presums(freq_idx_WB)/4)*2 4 ceil(presums(freq_idx_WB)/4)*2];
% Switch from tx calibration window to hanning window to broaden beam
DDS_amp = final_DDS_amp{freq_idx_WB} .* hanning(8).' ./ Hwindow_orig;
% Renormalize the amplitudes
[~,relative_max_idx] = max(DDS_amp./param.max_tx);
DDS_amp = round(DDS_amp .* param.max_tx(relative_max_idx) / DDS_amp(relative_max_idx));
param.tx_weights = DDS_amp;
param.tukey = 0.08;
param.wfs(1).Tpd = 3e-6;
param.wfs(2).Tpd = 1e-6;
param.wfs(3).Tpd = 3e-6;
param.wfs(1).phase = final_DDS_phase{freq_idx_NB};
param.wfs(2).phase = final_DDS_phase{freq_idx_WB};
param.wfs(3).phase = final_DDS_phase{freq_idx_NB};
% Add in time delays to each position, subtract out the nadir time delays since tx_equalization already took care of those
beam_angle_deg = 20; % Positive to the left
param.wfs(1).delay = final_DDS_time{freq_idx_NB} ...
  - (phase_centers(2,:) / (c/2) * sind(beam_angle_deg))*1e9 ...
  - (phase_centers(3,:) / (c/2) * cosd(beam_angle_deg))*1e9 ...
  + (phase_centers(3,:) / (c/2) * cosd(0))*1e9;
beam_angle_deg = 0; % Nadir
param.wfs(2).delay = final_DDS_time{freq_idx_WB} ...
  - (phase_centers(2,:) / (c/2) * sind(beam_angle_deg))*1e9 ...
  - (phase_centers(3,:) / (c/2) * cosd(beam_angle_deg))*1e9 ...
  + (phase_centers(3,:) / (c/2) * cosd(0))*1e9;
beam_angle_deg = -20; % Negative to the right
param.wfs(3).delay = final_DDS_time{freq_idx_NB} ...
  - (phase_centers(2,:) / (c/2) * sind(beam_angle_deg))*1e9 ...
  - (phase_centers(3,:) / (c/2) * cosd(beam_angle_deg))*1e9 ...
  + (phase_centers(3,:) / (c/2) * cosd(0))*1e9;
param.wfs(1).f0 = f0_list(freq_idx_NB);
param.wfs(2).f0 = f0_list(freq_idx_WB);
param.wfs(3).f0 = f0_list(freq_idx_NB);
param.wfs(1).f1 = f1_list(freq_idx_NB);
param.wfs(2).f1 = f1_list(freq_idx_WB);
param.wfs(3).f1 = f1_list(freq_idx_NB);
param.DDC_freq = (param.wfs(2).f0+param.wfs(2).f1)/2;
[param.wfs(1:3).tx_mask] = deal([0 0 0 0 0 0 0 0]);
param.wfs(1).atten = 0;
param.wfs(2).atten = 23;
param.wfs(3).atten = 0;
param.fn = fullfile(base_dir,sprintf('imagehighthin_%.0f-%.0fMHz_%.0fft_%.0fus_%.0fmthick.xml', ...
  param.wfs(2).f0/1e6,param.wfs(2).f1/1e6,param.tg.Haltitude*100/2.54/12,param.wfs(end).Tpd*1e6,param.tg.Hice_thick));
write_cresis_xml(param);

%% Equalization (Using Ocean)
% Haltitude +/- 1000 ft
% For lower altitude, increase attenuation
% Use these settings over ocean or sea ice for fast-time equalization,
% transmit equalization, and receiver equalization.
% Creates one waveform for each of N DDS-transmitters plus a combined
% waveform with all transmitters going.
Haltitude = [1500 1500 0 3000 6000];
Tpd_list = [1e-6 1e-6 3e-6 3e-6 3e-6];
attenuation = [43 39 43 43 43];
fn_hint = {'WATER','ICE','NO_DELAY','WATER','WATER'};
for Tpd_idx = 1:length(Tpd_list)
  Tpd = Tpd_list(Tpd_idx);
  for freq_idx = [1 2]
    param = struct('radar_name','mcords5','num_chan',24,'aux_dac',[255 255 255 255 255 255 255 255],'version','14.0f1','TTL_prog_delay',650,'xml_version',2.0,'fs',1600e6,'fs_sync',90.0e6,'fs_dds',1440e6,'TTL_mode',[2.5e-6 260e-9 -1100e-9]);
    param.max_tx = [4000 4000 4000 4000 4000 4000 4000 4000]; param.max_data_rate = 700; param.flight_hours = 3.5; param.sys_delay = 0.75e-6; param.use_mcords4_names = true;
    param.DDC_select = DDC_select_list(freq_idx);
    param.max_duty_cycle = 0.12;
    param.create_IQ = false;
    param.tg.staged_recording = false;
    param.tg.altitude_guard = 1000*12*2.54/100;
    param.tg.Haltitude = Haltitude(Tpd_idx)*12*2.54/100;
    param.tg.Hice_thick = 0;
    param.prf = prf;
    param.presums = [10 10 10 10 10 10 10 10 10];
    [param.wfs(1:8).atten] = deal(attenuation(Tpd_idx)-12);
    [param.wfs(9:9).atten] = deal(attenuation(Tpd_idx));
    param.tx_weights = final_DDS_amp{cal_settings(freq_idx)};
    param.tukey = 0.08;
    param.Tpd = Tpd;
    for wf=1:9
      param.wfs(wf).phase = final_DDS_phase{cal_settings(freq_idx)};
    end
    param.delay = final_DDS_time{cal_settings(freq_idx)};
    param.f0 = f0_list(freq_idx);
    param.f1 = f1_list(freq_idx);
    param.DDC_freq = (param.f0+param.f1)/2;
    for wf=1:8
      param.wfs(wf).tx_mask = ones(1,8);
      param.wfs(wf).tx_mask(9-wf) = 0;
    end
    for wf=9:9
      param.wfs(wf).tx_mask = [0 0 0 0 0 0 0 0];
    end
    param.fn = fullfile(calval_dir,sprintf('txequal_%.0f-%.0fMHz_%.0fft_%.0fus_%s.xml',param.f0/1e6,param.f1/1e6,param.tg.Haltitude*100/12/2.54,param.Tpd*1e6,fn_hint{Tpd_idx}));
    write_cresis_xml(param);
  end
end

%% Max power mode with max frequency range (only for EMI survey)
freq_idx = 1;
param = struct('radar_name','mcords5','num_chan',24,'aux_dac',[255 255 255 255 255 255 255 255],'version','14.0f1','TTL_prog_delay',650,'xml_version',2.0,'fs',1600e6,'fs_sync',90.0e6,'fs_dds',1440e6,'TTL_mode',[2.5e-6 260e-9 -1100e-9]);
param.max_tx = [4000 4000 4000 4000 4000 4000 4000 4000]; param.max_data_rate = 750; param.flight_hours = 3.5; param.sys_delay = 0.75e-6; param.use_mcords4_names = true;
param.DDC_select = DDC_select_list(freq_idx);
param.max_duty_cycle = 0.12;
param.create_IQ = false;
param.tg.staged_recording = false;
param.tg.altitude_guard = 1000*12*2.54/100;
param.tg.Haltitude = 1400*12*2.54/100;
param.tg.Hice_thick = 0;
param.prf = prf;
param.presums = presums(freq_idx);
param.wfs(1).atten = 43;
param.tukey = 0;
param.wfs(1).Tpd = 10e-6;
param.wfs(1).phase = [0 0 0 0 0 0 0 0];
param.delay = [0 0 0 0 0 0 0 0];
param.f0 = f0_list(freq_idx);
param.f1 = f1_list(freq_idx);
param.DDC_freq = (param.f0+param.f1)/2;
[param.wfs(1:1).tx_mask] = deal([1 1 1 1 1 1 1 1]);
param.tx_weights = [4000 4000 4000 4000 4000 4000 4000 4000] * sqrt(0);
param.fn = fullfile(calval_dir,sprintf('singlewf_%.0f-%.0fMHz_%.0fus_TX_OFF.xml',param.f0/1e6,param.f1/1e6,param.wfs(end).Tpd*1e6));
write_cresis_xml(param);
[param.wfs(1:1).tx_mask] = deal([0 0 0 0 0 0 0 0]);
param.tx_weights = [4000 4000 4000 4000 4000 4000 4000 4000] * sqrt(1.00);
param.fn = fullfile(base_dir,sprintf('singlewf_%.0f-%.0fMHz_%.0fus_DDS_CHECK.xml',param.f0/1e6,param.f1/1e6,param.wfs(end).Tpd*1e6));
write_cresis_xml(param);
