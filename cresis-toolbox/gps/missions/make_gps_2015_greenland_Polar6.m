% script make_gps_2015_greenland_Polar6
%
% Makes the GPS files for 2015 Greenland Polar6 field season

tic;

global gRadar;

support_path = '';
data_support_path = '';

if isempty(support_path)
  support_path = gRadar.support_path;
end

gps_path = fullfile(support_path,'gps','2015_Greenland_Polar6');
if ~exist(gps_path,'dir')
  fprintf('Making directory %s\n', gps_path);
  fprintf('  Press a key to proceed\n');
  pause;
  mkdir(gps_path);
end

if isempty(data_support_path)
  data_support_path = gRadar.data_support_path;
end

debug_level = 1;

in_base_path = fullfile(data_support_path,'2015_Greenland_Polar6');

file_idx = 0; in_fns = {}; out_fns = {}; file_type = {}; params = {}; gps_source = {};
sync_fns = {}; sync_params = {};

gps_source_to_use = 'AWI';

if strcmpi(gps_source_to_use,'NMEA')
%   file_idx = file_idx + 1;
%   year = 2015; month = 7; day = 30;
%   in_fns{file_idx} = get_filenames(in_base_path,sprintf('GPS_%04d%02d%02d',year,month,day),'','.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;
  
%   file_idx = file_idx + 1;
%   year = 2015; month = 9; day = 11;
%   in_fns{file_idx} = get_filenames(in_base_path,sprintf('GPS_%04d%02d%02d',year,month,day),'','.txt');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
%   file_type{file_idx} = 'NMEA';
%   params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
%   gps_source{file_idx} = 'nmea-field';
%   sync_flag{file_idx} = 0;

  file_idx = file_idx + 1;
  year = 2015; month = 9; day = 13;
  in_fns{file_idx} = get_filenames(in_base_path,sprintf('GPS_%04d%02d%02d',year,month,day),'','.txt');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
  file_type{file_idx} = 'NMEA';
  params{file_idx} = struct('year',year,'month',month,'day',day,'format',1,'time_reference','utc');
  gps_source{file_idx} = 'nmea-field';
  sync_flag{file_idx} = 0;
end

if strcmpi(gps_source_to_use,'AWI')
%   file_idx = file_idx + 1;
%   year = 2015; month = 9; day = 11;
%   in_fns{file_idx} = get_filenames(in_base_path,sprintf('GPS_R_L1_%04d%02d%02d',year,month,day),'','.nc');
%   in_fns_ins{file_idx} = get_filenames(in_base_path,sprintf('INS_L1_%04d%02d%02d',year,month,day),'','.nc');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
%   file_type{file_idx} = 'awi_netcdf+awi_netcdf';
%   gps_source{file_idx} = 'awi-field';
%   sync_flag{file_idx} = 0;
%   params{file_idx} = struct('time_reference','utc');
%   params{file_idx}.nc_field = {'TIME','LATITUDE','LONGITUDE','ALTITUDE','YEAR','MONTH','DAY'};
%   params{file_idx}.nc_type = {'v','v','v','v','a','a','a'};
%   params{file_idx}.types = {'sec','lat_deg','lon_deg','elev_m','year','month','day'};
%   params{file_idx}.scale = [1e-3 1 1 1 1 1 1];
%   params_ins{file_idx} = struct('time_reference','utc');
%   params_ins{file_idx}.nc_field = {'TIME','ROLL','PITCH','THDG','YEAR','MONTH','DAY'};
%   params_ins{file_idx}.nc_type = {'v','v','v','v','a','a','a'};
%   params_ins{file_idx}.types = {'sec','roll_deg','pitch_deg','heading_deg','year','month','day'};
%   params_ins{file_idx}.scale = [1e-3 1 1 1 1 1 1];
  
%   file_idx = file_idx + 1;
%   year = 2015; month = 9; day = 12;
%   in_fns{file_idx} = get_filenames(in_base_path,sprintf('GPS_R_L1_%04d%02d%02d',year,month,day),'','.nc');
%   in_fns_ins{file_idx} = get_filenames(in_base_path,sprintf('INS_L1_%04d%02d%02d',year,month,day),'','.nc');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
%   file_type{file_idx} = 'awi_netcdf+awi_netcdf';
%   gps_source{file_idx} = 'awi-field';
%   sync_flag{file_idx} = 0;
%   params{file_idx} = struct('time_reference','utc');
%   params{file_idx}.nc_field = {'TIME','LATITUDE','LONGITUDE','ALTITUDE','YEAR','MONTH','DAY'};
%   params{file_idx}.nc_type = {'v','v','v','v','a','a','a'};
%   params{file_idx}.types = {'sec','lat_deg','lon_deg','elev_m','year','month','day'};
%   params{file_idx}.scale = [1e-3 1 1 1 1 1 1];
%   params_ins{file_idx} = struct('time_reference','utc');
%   params_ins{file_idx}.nc_field = {'TIME','ROLL','PITCH','THDG','YEAR','MONTH','DAY'};
%   params_ins{file_idx}.nc_type = {'v','v','v','v','a','a','a'};
%   params_ins{file_idx}.types = {'sec','roll_deg','pitch_deg','heading_deg','year','month','day'};
%   params_ins{file_idx}.scale = [1e-3 1 1 1 1 1 1];  
    
%   file_idx = file_idx + 1;
%   year = 2015; month = 9; day = 13;
%   in_fns{file_idx} = get_filenames(in_base_path,sprintf('GPS_R_L1_%04d%02d%02d',year,month,day),'','.nc');
%   in_fns_ins{file_idx} = get_filenames(in_base_path,sprintf('INS_L1_%04d%02d%02d',year,month,day),'','.nc');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
%   file_type{file_idx} = 'awi_netcdf+awi_netcdf';
%   gps_source{file_idx} = 'awi-field';
%   sync_flag{file_idx} = 0;
%   params{file_idx} = struct('time_reference','utc');
%   params{file_idx}.nc_field = {'TIME','LATITUDE','LONGITUDE','ALTITUDE','YEAR','MONTH','DAY'};
%   params{file_idx}.nc_type = {'v','v','v','v','a','a','a'};
%   params{file_idx}.types = {'sec','lat_deg','lon_deg','elev_m','year','month','day'};
%   params{file_idx}.scale = [1e-3 1 1 1 1 1 1];
%   params_ins{file_idx} = struct('time_reference','utc');
%   params_ins{file_idx}.nc_field = {'TIME','ROLL','PITCH','THDG','YEAR','MONTH','DAY'};
%   params_ins{file_idx}.nc_type = {'v','v','v','v','a','a','a'};
%   params_ins{file_idx}.types = {'sec','roll_deg','pitch_deg','heading_deg','year','month','day'};
%   params_ins{file_idx}.scale = [1e-3 1 1 1 1 1 1];  
%   
%   file_idx = file_idx + 1;
%   year = 2015; month = 9; day = 14;
%   in_fns{file_idx} = get_filenames(in_base_path,sprintf('GPS_R_L1_%04d%02d%02d',year,month,day),'','.nc');
%   in_fns_ins{file_idx} = get_filenames(in_base_path,sprintf('INS_L1_%04d%02d%02d',year,month,day),'','.nc');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
%   file_type{file_idx} = 'awi_netcdf+awi_netcdf';
%   gps_source{file_idx} = 'awi-field';
%   sync_flag{file_idx} = 0;
%   params{file_idx} = struct('time_reference','utc');
%   params{file_idx}.nc_field = {'TIME','LATITUDE','LONGITUDE','ALTITUDE','YEAR','MONTH','DAY'};
%   params{file_idx}.nc_type = {'v','v','v','v','a','a','a'};
%   params{file_idx}.types = {'sec','lat_deg','lon_deg','elev_m','year','month','day'};
%   params{file_idx}.scale = [1e-3 1 1 1 1 1 1];
%   params_ins{file_idx} = struct('time_reference','utc');
%   params_ins{file_idx}.nc_field = {'TIME','ROLL','PITCH','THDG','YEAR','MONTH','DAY'};
%   params_ins{file_idx}.nc_type = {'v','v','v','v','a','a','a'};
%   params_ins{file_idx}.types = {'sec','roll_deg','pitch_deg','heading_deg','year','month','day'};
%   params_ins{file_idx}.scale = [1e-3 1 1 1 1 1 1];  
  
%   file_idx = file_idx + 1;
%   year = 2015; month = 9; day = 16;
%   in_fns{file_idx} = get_filenames(in_base_path,sprintf('GPS_R_L1_%04d%02d%02d',year,month,day),'','.nc');
%   in_fns_ins{file_idx} = get_filenames(in_base_path,sprintf('INS_L1_%04d%02d%02d',year,month,day),'','.nc');
%   out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
%   file_type{file_idx} = 'awi_netcdf+awi_netcdf';
%   gps_source{file_idx} = 'awi-field';
%   sync_flag{file_idx} = 0;
%   params{file_idx} = struct('time_reference','utc');
%   params{file_idx}.nc_field = {'TIME','LATITUDE','LONGITUDE','ALTITUDE','YEAR','MONTH','DAY'};
%   params{file_idx}.nc_type = {'v','v','v','v','a','a','a'};
%   params{file_idx}.types = {'sec','lat_deg','lon_deg','elev_m','year','month','day'};
%   params{file_idx}.scale = [1e-3 1 1 1 1 1 1];
%   params_ins{file_idx} = struct('time_reference','utc');
%   params_ins{file_idx}.nc_field = {'TIME','ROLL','PITCH','THDG','YEAR','MONTH','DAY'};
%   params_ins{file_idx}.nc_type = {'v','v','v','v','a','a','a'};
%   params_ins{file_idx}.types = {'sec','roll_deg','pitch_deg','heading_deg','year','month','day'};
%   params_ins{file_idx}.scale = [1e-3 1 1 1 1 1 1];  
  
  file_idx = file_idx + 1;
  year = 2015; month = 9; day = 17;
  in_fns{file_idx} = get_filenames(in_base_path,sprintf('GPS_R_L1_%04d%02d%02d',year,month,day),'','.nc');
  in_fns_ins{file_idx} = get_filenames(in_base_path,sprintf('INS_L1_%04d%02d%02d',year,month,day),'','.nc');
  out_fns{file_idx} = sprintf('gps_%04d%02d%02d.mat',year,month,day);
  file_type{file_idx} = 'awi_netcdf+awi_netcdf';
  gps_source{file_idx} = 'awi-field';
  sync_flag{file_idx} = 0;
  params{file_idx} = struct('time_reference','utc');
  params{file_idx}.nc_field = {'TIME','LATITUDE','LONGITUDE','ALTITUDE','YEAR','MONTH','DAY'};
  params{file_idx}.nc_type = {'v','v','v','v','a','a','a'};
  params{file_idx}.types = {'sec','lat_deg','lon_deg','elev_m','year','month','day'};
  params{file_idx}.scale = [1e-3 1 1 1 1 1 1];
  params_ins{file_idx} = struct('time_reference','utc');
  params_ins{file_idx}.nc_field = {'TIME','ROLL','PITCH','THDG','YEAR','MONTH','DAY'};
  params_ins{file_idx}.nc_type = {'v','v','v','v','a','a','a'};
  params_ins{file_idx}.types = {'sec','roll_deg','pitch_deg','heading_deg','year','month','day'};
  params_ins{file_idx}.scale = [1e-3 1 1 1 1 1 1];  
end

% ======================================================================
% Read and translate files according to user settings
% ======================================================================
make_gps;

%% Lab Measurement Data: Fakes GPS position information
match_idx = strmatch('gps_20150730.mat',out_fns,'exact');
if ~isempty(match_idx)
  gps_fn = fullfile(gps_path,out_fns{match_idx});
  fprintf('Creating fake gps data for %s\n', gps_fn);
  gps = load(gps_fn);
  gps.lon = -45 * ones(size(gps.lon));
  gps.lat = 70 + (1:length(gps.gps_time)) * 6e-4;
  save(gps_fn,'-append','-struct','gps','lat','lon');
end


