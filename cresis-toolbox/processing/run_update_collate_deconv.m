% Script run_update_collate_deconv.m
%
% Runs update_collate_deconv.m
%
% Author: John Paden

%% USER SETTINGS
% =========================================================================

params = read_param_xls(ct_filename_param('snow_param_2017_Greenland_P3.xls'),'',{'analysis_spec' 'analysis'});

params = ct_set_params(params,'cmd.generic',0);
params = ct_set_params(params,'cmd.generic',1,'day_seg','20170508_01');
param_override.update_collate_deconv.cmd = {};
% param_override.update_collate_deconv.cmd{end+1}.method = 'delete';
% param_override.update_collate_deconv.cmd{end}.idxs = [1];
param_override.update_collate_deconv.cmd{end+1}.method = 'replace';
param_override.update_collate_deconv.cmd{end}.day_seg = {'20170311_02'}
param_override.update_collate_deconv.cmd{end}.idxs = {[1]};

% 2-18 GHz Deconvolution Settings (3 sets)
% params = ct_set_params(params,'analysis.cmd{1}.abs_metric',[58 4.5 -25 -35 inf inf]);
% param_override.update_collate_deconv.in_dir = 'analysis_uwb';

% params = ct_set_params(params,'analysis.cmd{1}.abs_metric',[58 9.8 -25 -35 inf inf]);
% param_override.update_collate_deconv.in_dir = 'analysis';

params = ct_set_params(params,'analysis.cmd{1}.abs_metric',[58 24 -25 -28 inf inf]);
param_override.update_collate_deconv.in_dir = 'analysis_kuband';

% 2-8 GHz Deconvolution Settings
% params = ct_set_params(params,'analysis.cmd{1}.abs_metric',[65 4.5 -25 -35 inf inf]);
% param_override.update_collate_deconv.in_dir = 'analysis';

param_override.update_collate_deconv.gps_time_penalty = 1/(10*24*3600);

param_override.update_collate_deconv.cmd_idx = 1;
param_override.update_collate_deconv.imgs = 1;
param_override.update_collate_deconv.wf_adcs = [];

%% Automated Section
% =====================================================================

% Input checking
global gRadar;
if exist('param_override','var')
  param_override = merge_structs(gRadar,param_override);
else
  param_override = gRadar;
end

% Process each of the segments
for param_idx = 1:length(params)
  param = params(param_idx);
  if ~isfield(param.cmd,'generic') || iscell(param.cmd.generic) || ischar(param.cmd.generic) || ~param.cmd.generic
    continue;
  end
  %update_collate_deconv(param,param_override);
  update_collate_deconv
  
end