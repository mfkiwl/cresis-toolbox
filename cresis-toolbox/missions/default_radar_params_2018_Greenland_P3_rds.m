function [param,defaults] = default_radar_params_2018_Greenland_P3_rds
% [param,defaults] = default_radar_params_2018_Greenland_P3_rds
%
% RDS: 2018_Greenland_P3
%
% Creates base "param" struct
% Creates defaults cell array for each type of radar setting
%
% Author: John Paden

%% Preprocess parameters
param.season_name = '2018_Greenland_P3';
param.radar_name = 'mcords3';

param.preprocess.daq.type = 'cresis';
param.preprocess.daq.xml_version = 2.0; % No XML file available
param.preprocess.daq.header_load_func = @basic_load_mcords3;
param.preprocess.daq.board_map = {'board0','board1','board2','board3'};
param.preprocess.daq.clk = 1e9/9;
param.preprocess.daq.rx_gain = 51.5;
param.preprocess.daq.adc_SNR_dB = 70;
param.preprocess.daq.max_wg_counts = 40000;
param.preprocess.daq.max_wg_voltage = sqrt(250*50)*10^(-2/20);
param.preprocess.daq.tx_mask = [1 1 1 1 1 1 1 0];

param.preprocess.wg.type = 'cresis';
param.preprocess.wg.tx_map = {'','','','','','','',''};

param.preprocess.file.version = 403;
param.preprocess.file.prefix = param.radar_name;
param.preprocess.file.suffix = '.bin';
param.preprocess.max_time_gap = 10;
param.preprocess.min_seg_size = 2;

%% Control parameters
% default.xml_file_prefix = 'mcords3';
% default.data_file_prefix = 'mcords3';
% default.header_load_func = @basic_load_mcords3;
% default.header_load_params = struct('clk',1e9/9,'presum_bug_fixed',false);
% default.xml_version = 2.0;
% 
% default.noise_50ohm = [-44.0	-44.0	-43.1	-43.9	-43.7	-43.6	-44.5	-43.2	-42.8	-43.0	-43.3	-45.3	-44.9	-44.2	-45.1	];
% 
% default.Pt = 500 * [1 1 1 1 1 1 1];
% default.Gt = 7*4;
% default.Ae = 2*0.468 * 0.468;
% 
% default.system_loss_dB = 10.^(-5.88/10);
% default.max_DDS_RAM = 40000;
% default.tx_voltage = sqrt(1000*50)*10^(-2/20);
% 
% default.iq_mode = 0;
% default.tx_DDS_mask = [1 1 1 1 1 1 1 0];
% 
% default.radar_worksheet_headers = {'Tpd','Tadc','Tadc_adjust','f0','f1','ref_fn','tukey','tx_weights','rx_paths','adc_gains','chan_equal_dB','chan_equal_deg','Tsys','DC_adjust','DDC_mode','DDC_freq'};
% default.radar_worksheet_headers_type = {'r','r','r','r','r','r','r','r','r','r','r','r','r','r','r','r'};
% 
% default.basic_surf_track_min_time = 2e-6; % Normally -inf for lab test, 2e-6 for flight test
% default.basic_surf_track_Tpd_factor = 1.1; % Normally -inf for lab test, 1.1 for flight test
% default.adc_folder_name = 'board%b';

if 1
  % Example 1: Normal configuration:
  %   Connect antenna N to WFG N for all N = 1 to 7
  ref_adc = 6;
  default.txequal.img = [(1:7).', ref_adc*ones(7,1)];
  default.txequal.ref_wf_adc = 3;
  default.txequal.wf_mapping = [1 2 3 4 5 6 7 0];
  default.txequal.Hwindow_desired = [1 1 1 1 1 1 1 0];
  default.txequal.max_DDS_amp = [40000 40000 40000 40000 40000 40000 40000 0];
  default.txequal.time_delay_desired = [0 0 0 0 0 0 0 0];
  default.txequal.phase_desired = [0 0 0 0 0 0 0 0];
  default.txequal.time_validation = [3 3 3 3 3 3 3 3]*1e-9;
  default.txequal.amp_validation = [3 3 3 3 3 3 3 3];
  default.txequal.phase_validation = [35 35 35 35 35 35 35 35];
  default.txequal.remove_linear_phase_en = true;
  % Example 1: Antenna 2 bad configuration:
  %   Connect antenna N to WFG N for all N = 1, 3 to 7
  ref_adc = 6;
  default.txequal.img = [(1:7).', ref_adc*ones(7,1)];
  default.txequal.ref_wf_adc = 1;
  default.txequal.wf_mapping = [1 0 3 4 5 6 7 0];
  default.txequal.Hwindow_desired = [1 1 1 1 1 1 1 0];
  default.txequal.max_DDS_amp = [40000 40000 40000 40000 40000 40000 40000 0];
  default.txequal.time_delay_desired = [0 0 0 0 0 0 0 0];
  default.txequal.phase_desired = [0 0 0 0 0 0 0 0];
  default.txequal.time_validation = [3 3 3 3 3 3 3 3]*1e-9;
  default.txequal.amp_validation = [3 3 3 3 3 3 3 3];
  default.txequal.phase_validation = [35 35 35 35 35 35 35 35];
  default.txequal.remove_linear_phase_en = true;
end

%% Records worksheet
default.records.gps.time_offset = 1;
default.records.file.adcs = [2:16];
default.records.file.adc_headers = [2:16];
default.records.file.version = 403;
default.records.gps.en = 1;
default.records.frames.mode = 1;
default.records.frames.geotiff_fn = 'greenland\Landsat-7\mzl7geo_90m_lzw.tif';
default.records.presum_bug_fixed = 0;

%% Qlook worksheet
default.qlook.out_path = '';
default.qlook.en = 1;
default.qlook.block_size = 10000;
default.qlook.dec = 50;
default.qlook.inc_dec = 10;
default.qlook.surf.en = 1;
default.qlook.surf.method = 'threshold';
default.qlook.surf.noise_rng = [0 -50 10];
default.qlook.surf.min_bin = 1.8e-6;
default.qlook.surf.max_bin = [];
default.qlook.surf.threshold = 15;
default.qlook.surf.sidelobe = 15;
default.qlook.surf.medfilt = 3;
default.qlook.surf.search_rng = [0:2];

%% SAR worksheet
default.sar.out_path = '';
default.sar.imgs = {[1*ones(4,1),(9:12).'],[2*ones(4,1),(9:12).'],[3*ones(4,1),(9:12).']};
default.sar.frm_types = {0,[0 1],0,0,-1};
default.sar.chunk_len = 5000;
default.sar.chunk_overlap = 10;
default.sar.frm_overlap = 0;
default.sar.coh_noise_removal = 0;
default.sar.combine_rx = 0;
default.sar.time_of_full_support = 3.5e-5;
default.sar.pulse_rfi.en = [];
default.sar.pulse_rfi.inc_ave= [];
default.sar.pulse_rfi.thresh_scale = [];
default.sar.trim_vals = [];
default.sar.pulse_comp = 1;
default.sar.ft_dec = 1;
default.sar.ft_wind = @hanning;
default.sar.ft_wind_time = 0;
default.sar.lever_arm_fh = @lever_arm;
default.sar.mocomp.en = 1;
default.sar.mocomp.type = 2;
default.sar.mocomp.filter = {@butter  [2]  [0.1000]};
default.sar.mocomp.uniform_en = 1;
default.sar.sar_type = 'fk';
default.sar.sigma_x = 2.5;
default.sar.sub_aperture_steering = 0;
default.sar.st_wind = @hanning;
default.sar.start_eps = 3.15;

%% Array worksheet
default.array.in_path = '';
default.array.array_path = '';
default.array.out_path = '';
default.array.method = 'standard';
default.array.window = @hanning;
default.array.bin_rng = 0;
default.array.rline_rng = -5:5;
default.array.dbin = 1;
default.array.dline = 6;
default.array.DCM = [];
default.array.three_dim.en = 0;
default.array.three_dim.layer_fn = '';
default.array.Nsv = 1;
default.array.theta_rng = [0 0];
default.array.sv_fh = @array_proc_sv;
default.array.diag_load = 0;
default.array.Nsig = 2;

%% Radar worksheet
default.radar.fs = 1e9/9;
default.radar.Tadc = []; % normally leave empty to use value in file header
default.radar.adc_bits = 14;
default.radar.Vpp_scale = 2;

default.radar.wfs.rx_paths = [8 9 10 11 1 1 2 3 4 5 6 7 12 13 14 15];
default.radar.wfs.noise_figure = 2;
default.radar.wfs.Tadc_adjust = -1.4455e-06; % System time delay: leave this empty or set it to zero at first, determine this value later using data over surface with known height or from surface multiple

%% Post worksheet
default.post.data_dirs = {'qlook'};
default.post.layer_dir = 'layerData';
default.post.maps_en = 1;
default.post.echo_en = 1;
default.post.layers_en = 0;
default.post.data_en = 0;
default.post.csv_en = 1;
default.post.concat_en = 1;
default.post.pdf_en = 1;
default.post.map.location = 'Greenland';
default.post.map.type = 'combined';
default.post.echo.elev_comp = 3;
default.post.echo.depth = '[publish_echogram_switch(Bbad,0.25,Surface_Elev,-3500,DBottom,-100),max(Surface_Elev+100)]';
default.post.echo.er_ice = 3.15;
default.post.ops.en = 0;
default.post.ops.location = 'arctic';
default.post.ops.layers = {'bottom','surface'};
default.post.ops.gaps_dist = [300 60];


%% Radar Settings
defaults = {};

default.radar.wfs(1).Tsys = [65.3 60.8 63.3 62.9 62.3 60 58.1 -9 -9.9 -15.7 -16.3 -20.1 -19.6 -14.6 -11.3]/1e9;
default.radar.wfs(1).chan_equal_dB = [0.0 -2.1 -3.9 -5.6 -6.0 -2.3 -1.6 2.0 -1.5 -0.2 1.0 1.5 -0.4 -1.3 1.6];
default.radar.wfs(1).chan_equal_deg = [0.0 80.9 -135.4 57.3 -11.2 -8.6 -155.0 78.3 -179.5 86.9 -90.4 -70.7 41.3 -165.5 -173.3];

% survey mode
default.qlook.img_comb = [3e-06 -inf 1e-06 1e-05 -inf 3e-06];
default.qlook.imgs = {[1*ones(4,1),(9:12).'],[2*ones(4,1),(9:12).'],[3*ones(4,1),(9:12).']};
default.sar.imgs = default.qlook.imgs;
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.radar.DC_adjust = {'','',''};
default.radar.ref_fn = '';
default.config_regexp = '(survey_.*thick.xml';
default.name = 'Survey Mode';
defaults{end+1} = default;

% survey mode
default.qlook.img_comb = [3e-06 -inf 1e-06];
default.qlook.imgs = {[1*ones(4,1),(9:12).'],[2*ones(4,1),(9:12).']};
default.sar.imgs = default.qlook.imgs;
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.config_regexp = 'survey_.*thin_ice.xml';
default.name = 'Thin Ice Mode';
defaults{end+1} = default;

% image mode
default.qlook.img_comb = [3e-06 -inf 1e-06 1e-05 -inf 3e-06];
default.qlook.imgs = {[1*ones(4,1),(9:12).'],[3*ones(4,1),(9:12).'],[5*ones(4,1),(9:12).']};
default.sar.imgs = default.qlook.imgs;
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.config_regexp = 'image_.*thick.xml';
default.name = 'Image Mode';
defaults{end+1} = default;

% image mode
default.qlook.img_comb = [3e-06 -inf 1e-06];
default.qlook.imgs = {[1*ones(4,1),(9:12).'],[3*ones(4,1),(9:12).']};
default.sar.imgs = default.qlook.imgs;
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.config_regexp = 'image_.*thin_ice.xml';
default.name = 'Image Mode Thin Ice';
defaults{end+1} = default;

% high altitude mode
default.qlook.img_comb = [1e-05 -inf 3e-06];
default.qlook.imgs = {[1*ones(4,1),(9:12).'],[2*ones(4,1),(9:12).']};
default.sar.imgs = default.qlook.imgs;
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.config_regexp = 'survey_.*high_altitude.xml';
default.name = 'High Altitude Mode';
defaults{end+1} = default;

% deconvolution mode
default.qlook.img_comb = [];
default.qlook.imgs = {[1*ones(4,1),(9:12).'],[2*ones(4,1),(9:12).'],[3*ones(4,1),(9:12).']};
default.sar.imgs = default.qlook.imgs;
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.config_regexp = 'survey_.*DECONVOLUTION.xml';
default.name = 'Deconvolution Mode';
defaults{end+1} = default;

% Other settings

default.qlook.img_comb = [];
default.qlook.imgs = [];
default.sar.imgs = default.qlook.imgs;
default.array.imgs = default.qlook.imgs;
default.array.img_comb = default.qlook.img_comb;
default.config_regexp = '.*';
default.name = 'Other Settings';
defaults{end+1} = default;

%% Add default settings

param.preprocess.defaults = defaults;