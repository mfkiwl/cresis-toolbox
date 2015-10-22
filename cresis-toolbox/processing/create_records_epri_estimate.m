function [init_EPRI_estimate,first_file] = create_records_epri_estimate(param,file_idxs,fns)
% [init_EPRI_estimate,first_file] = create_records_epri_estimate(param,file_idxs,fns)
%
% Provides an EPRI estimate based on time stamps in the header records of
% the first file which provides a consistent result based on comparing
% the mean and the median EPRI estimates.
% This is a support function called from create_records_RADAR_NAME functions.
%
% In:
%  param: usually the param structure from read_param_xls. Must have these fields:
%   .vectors.gps.utc_time_halved
%   .radar.fs
%   .radar_name
%   .records.presum_bug_fixed
%  file_idxs: indexes into fns filename list corresponding to this segment
%  fns: cell vector of filenames
%
% Out:
%  init_EPRI_estimate: EPRI estimate
%  first_file: header fields
%
% Author: John Paden

if ~isfield(param.records,'presum_bug_fixed') || isempty(param.records.presum_bug_fixed)
  param.records.presum_bug_fixed = false;
end

%% Load the first file to get initial EPRI estimate
first_byte = 2^26;

init_EPRI_file_idx = 0;
first_run = true;
while first_run || abs(init_EPRI_estimate-init_EPRI_estimate_median)/init_EPRI_estimate_median > 2e-4
  init_EPRI_file_idx = init_EPRI_file_idx + 1;
  
  if ~first_run
    warning('Median/Mean discrepancy in estimated EPRI, trying file %d', init_EPRI_file_idx);
    
    % Remove outliers and recompute the mean
    EPRI_estimates = (diff(first_file.utc_time_sod)./diff(first_file.epri));
    init_EPRI_estimate = mean(EPRI_estimates(abs(EPRI_estimates-init_EPRI_estimate_median) < init_EPRI_estimate_median/2));
    
    if abs(init_EPRI_estimate-init_EPRI_estimate_median)/init_EPRI_estimate_median <= 2e-4
      fprintf('Probably some 1 PPS errors??? If that is the case, then type "finish = 1" and "dbcont"\n');
      figure(1); clf;
      plot(first_file.utc_time_sod);
      finish = 0;
      keyboard
      if finish == 1
        break;
      end
    end
  end
  
  if init_EPRI_file_idx > length(file_idxs)
    fprintf('No good files to measure EPRI found in the whole segment\n');
    keyboard
  end
  
  if strcmp(param.radar_name,'snow') || strcmp(param.radar_name,'kuband')
    [first_file tmp] = basic_load_fmcw(fns{file_idxs(init_EPRI_file_idx)},...
      struct('clk',param.radar.fs,'utc_time_halved', ...
      param.vectors.gps.utc_time_halved,'first_byte',first_byte, ...
      'file_version', param.records.file_version));
  elseif strcmp(param.radar_name,'snow2') || strcmp(param.radar_name,'kuband2')
    [first_file tmp] = basic_load_fmcw2(fns{file_idxs(init_EPRI_file_idx)}, ...
      struct('clk',param.radar.fs,'utc_time_halved', ...
      param.vectors.gps.utc_time_halved,'first_byte',first_byte, ...
      'file_version', param.records.file_version));
  elseif any(strcmp(param.radar_name,{'snow3','kuband3','kaband3'}))
    if param.records.file_version == 4
      [first_file tmp] = basic_load_fmcw2(fns{file_idxs(init_EPRI_file_idx)}, ...
        struct('clk',param.radar.fs,'utc_time_halved', ...
        param.vectors.gps.utc_time_halved,'first_byte',first_byte, ...
        'file_version', param.records.file_version));
    elseif param.records.file_version == 5
      [first_file tmp] = basic_load_fmcw3(fns{file_idxs(init_EPRI_file_idx)}, ...
        struct('clk',param.radar.fs,'utc_time_halved', ...
        param.vectors.gps.utc_time_halved,'first_byte',first_byte, ...
        'file_version', param.records.file_version));
    end
  elseif any(strcmp(param.radar_name,{'snow5'}))
    [first_file tmp] = basic_load(fns{file_idxs(init_EPRI_file_idx)}, ...
      struct('clk',param.radar.fs,'utc_time_halved', ...
      param.vectors.gps.utc_time_halved,'first_byte',first_byte));
  elseif strcmp(param.radar_name,'accum')
    [first_file tmp] = basic_load_accum(fns{file_idxs(init_EPRI_file_idx)}, ...
      struct('clk',param.radar.fs,'utc_time_halved', ...
      param.vectors.gps.utc_time_halved,'first_byte',first_byte, ...
      'file_version', param.records.file_version));
  elseif strcmp(param.radar_name,'mcords2')
    [first_file,tmp] = basic_load_mcords2(fns{file_idxs(init_EPRI_file_idx)}, ...
      struct('clk',param.radar.fs,'first_byte',first_byte));
  elseif strcmp(param.radar_name,'mcords3')
    [first_file,tmp] = basic_load_mcords3(fns{file_idxs(init_EPRI_file_idx)}, ...
      struct('clk',param.radar.fs,'first_byte',first_byte));
  elseif strcmp(param.radar_name,'mcords4')
    [first_file,tmp] = basic_load_mcords4(fns{file_idxs(init_EPRI_file_idx)}, ...
      struct('clk',param.radar.fs/4,'first_byte',first_byte));
  elseif strcmp(param.radar_name,'mcords5')
    [first_file,tmp] = basic_load_mcords5(fns{file_idxs(init_EPRI_file_idx)}, ...
      struct('clk',param.radar.fs,'first_byte',first_byte,'presum_bug_fixed',param.records.presum_bug_fixed));
  end
  clear tmp;
  
  if any(strcmp(param.radar_name,{'snow','snow2','snow3','kuband','kuband2','kuband3','kaband3','snow5'}))
    if abs(param.radar.fs - max(first_file.fraction)) > 1e6
      if strcmpi(param.season_name,'2014_Greenland_P3') & (strcmpi(param.day_seg,'20140421_02') |...
          strcmpi(param.day_seg,'20140423_01') | strcmpi(param.day_seg,'20140502_00') | strcmpi(param.day_seg,'20140508_02'))
        warning('1 PPS missing');
      else
        warning('Radar sampling frequency is probably wrong (unless 1 PPS missing)\n');
        keyboard
      end
    end
  elseif any(strcmp(param.radar_name,{'accum'}))
    if abs(param.radar.fs/2 - max(first_file.fraction)) > 1e6
      warning('Radar sampling frequency is probably wrong (unless 1 PPS missing)\n');
      keyboard
    end
  elseif any(strcmp(param.radar_name,{'mcords','mcords2','mcords3','mcords4','mcords5'}))
    % No check is done
  else
    warning('Unsupported radar');
    keyboard
  end
  
  if any(strcmpi(param.season_name,{'2013_Greenland_P3','2013_Antarctica_Basler','2013_Antarctica_P3','2014_Alaska_TOnrl','2014_Greenland_P3'}))
    warning('2013 Greenland P3 EPRI HACK');
    EPRI_estimates = diff(first_file.utc_time_sod)./diff(first_file.epri);
    EPRI_estimates = EPRI_estimates(isfinite(EPRI_estimates));
    init_EPRI_estimate_median = median(EPRI_estimates);
    init_EPRI_estimate = mean(EPRI_estimates);
  elseif any(strcmp(param.radar_name,{'accum'}))
    % No EPRI field
    init_EPRI_estimate_median = median(diff(first_file.utc_time_sod));
    first_file.epri = round((first_file.utc_time_sod-first_file.utc_time_sod(1)) / init_EPRI_estimate_median);
    init_EPRI_estimate_median = median(diff(first_file.utc_time_sod)./diff(first_file.epri));
    init_EPRI_estimate = mean(diff(first_file.utc_time_sod)./diff(first_file.epri));
  else
    init_EPRI_estimate_median = median(diff(first_file.utc_time_sod)./diff(first_file.epri));
    init_EPRI_estimate = mean(diff(first_file.utc_time_sod)./diff(first_file.epri));
  end
  
  if isfield(param.records,'use_ideal_epri') && ~isempty(param.records.use_ideal_epri) && param.records.use_ideal_epri
    init_EPRI_estimate = init_EPRI_estimate_median;
    return;
  end
  
  first_run = false;
end
