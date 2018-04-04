function run_master
% run_master
%
% Script which sets up parameters and then calls master. Please
% make a local copy of this script.
%
% THIS MASTER RUNS FROM THE PARAM GENERATED BY read_param_xls.m,
% which reads in an excel spread sheet
% (e.g. RADAR_param_YYYY_Mission_Aircraft.xls).
%
% Authors: Brady Maasen, John Paden
%
% See also: master, read_param_xls

%error('Copy this script locally, comment this line, and then run.\n');

% =====================================================================
% User Settings
% =====================================================================
%clear; % Optional
%close all; % Optional

params = read_param_xls(ct_filename_param('replace_this_filename.xls'));
% Syntax for running a specific segment and frame by overriding parameter spreadsheet values
%params = read_param_xls(ct_filename_param('replace_this_filename.xls'),'YYYYMMDD_SS');
% params = ct_set_params(params,'cmd.csarp',0);
% params = ct_set_params(params,'cmd.csarp',1,'day_seg','YYYYMMDD_SS');

param_override = [];

ctrl_chain = master(params,param_override);
