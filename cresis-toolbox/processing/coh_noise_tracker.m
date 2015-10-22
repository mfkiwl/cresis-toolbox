% function coh_noise_tracker(param,param_override)
% coh_noise_tracker(param,param_override)
%
% 
%
% param = struct with processing parameters
%         -- OR --
%         function handle to script with processing parameters
% param_override = parameters in this struct will override parameters
%         in param.  This struct must also contain the gRadar fields.
%         Typically global gRadar; param_override = gRadar;
%
% Authors: John Paden
%
% See also: master.m, coh_noise_tracker_task.m

% =====================================================================
% General Setup
% =====================================================================

dbstack_info = dbstack;
if ~exist('param','var') || isempty(param) || length(dbstack_info) == 1
  % =====================================================================
  % Debug Setup
  % =====================================================================
%   param = read_param_xls(ct_filename_param('snow_param_2009_Greenland_P3.xls'),'20090425_02',{'analysis_coh_noise','analysis'});
%   param = read_param_xls(ct_filename_param('snow_param_2009_Greenland_P3.xls'),'20090421_02',{'analysis_coh_noise','analysis'});
%   param = read_param_xls(ct_filename_param('snow_param_2009_Greenland_P3.xls'),'20090331_01',{'analysis_coh_noise','analysis'});
%   param = read_param_xls(ct_filename_param('snow_param_2009_Greenland_P3.xls'),'20090402_01',{'analysis_coh_noise','analysis'});
%   param = read_param_xls(ct_filename_param('snow_param_2009_Greenland_P3.xls'),'20090405_01',{'analysis_spec','analysis'});
%   param = read_param_xls(ct_filename_param('snow_param_2010_Greenland_DC8.xls'),'20100323_05',{'analysis_coh_noise','analysis'});
%   param = read_param_xls(ct_filename_param('snow_param_2010_Greenland_P3.xls'),'20100510_02',{'analysis_coh_noise','analysis'});
%   param = read_param_xls(ct_filename_param('snow_param_2011_Greenland_P3.xls'),'20110415_01',{'analysis_spec','analysis'});
%   param = read_param_xls(ct_filename_param('snow_param_2011_Greenland_P3.xls'),'20110316_02',{'analysis_coh_noise','analysis'});
%   param = read_param_xls(ct_filename_param('snow_param_2011_Greenland_P3.xls'),'20110323_04',{'analysis_spec','analysis'});
%   param = read_param_xls(ct_filename_param('snow_param_2011_Greenland_P3.xls'),'20110322_01',{'analysis_spec','analysis'});
%   param = read_param_xls(ct_filename_param('snow_param_2012_Greenland_P3.xls'),'20120317_02',{'analysis_spec','analysis'});
%   param = read_param_xls(ct_filename_param('rds_param_2015_Greenland_C130.xls'),'20150319_09',{'analysis_spec','analysis'});
  param = read_param_xls(ct_filename_param('snow_param_2014_Greenland_P3.xls'),'20140328_01',{'analysis_coh_noise','analysis'});
%   param = read_param_xls(ct_filename_param('rds_param_2015_Greenland_C130.xls'),'20150313_14',{'analysis_surf','analysis'});
%   param = read_param_xls(ct_filename_param('rds_param_2015_Greenland_C130.xls'),'20150319_09',{'analysis_spec','analysis'});
%   param = read_param_xls(ct_filename_param('rds_param_2015_Greenland_Polar6.xls'),'20150912_02',{'analysis_spec','analysis'});


  clear('param_override');
  param_override.sched.type = 'no scheduler';
  param_override.sched.rerun_only = false;
%   param_override.analysis.out_path = 'noise';

param_override.sched.num_submissions = 16;
param_override.sched.submit_mode = 'fill'; % 'group' or 'fill'
param_override.sched.group_size = 4;
% param_override.sched.group_submit_arguments = '-l nodes=1:ppn=1,pmem=1725mb,walltime=%d:00';
% param_override.sched.group_submit_arguments = '-l nodes=1:ppn=1,pmem=2300mb,walltime=%d:00';
param_override.sched.group_submit_arguments = '-l nodes=1:ppn=1,pmem=3450mb,walltime=%d:00';
param_override.sched.group_walltime = 30;
param_override.sched.test_mode = false;
param_override.sched.max_in_queue = 4*62;

  % Input checking
  if ~exist('param','var')
    error('A struct array of parameters must be passed in\n');
  end
  global gRadar;
  if exist('param_override','var')
    param_override = merge_structs(gRadar,param_override);
  else
    param_override = gRadar;
  end
  
elseif ~isstruct(param)
  % Functional form
  param();
end
param = merge_structs(param, param_override);

fprintf('=====================================================================\n');
fprintf('%s: %s (%s)\n', dbstack_info(1).name, param.day_seg, datestr(now,'HH:MM:SS'));
fprintf('=====================================================================\n');

% HACK FOR DEVELOPMENT:
% param.analysis.block_size = 10000;
% param.analysis.imgs = {[1 1]};
% param.analysis.out_path = '';
% param.analysis.coh_ave.en = 0;
% param.analysis.coh_ave.block_ave = 1000;
% param.analysis.coh_ave.power_threshold = 0;
% param.analysis.specular.en = 1;
% param.analysis.specular.ave = 128;
% param.analysis.specular.threshold = 40;
% param.analysis.specular.rbins = -60:160;
% param.analysis.specular.rbins = -111:60;
% if any(strcmp(param.day_seg,{'20110322_03','20110323_02'}))
%   param.analysis.specular.Nt_shorten = [1700 600]; % 20110322_03
% else
%   param.analysis.specular.Nt_shorten = [600 400]; % Everything else?
% end

if ~isfield(param.analysis,'specular')
  param.analysis.specular.en = 0;
end

if ~isfield(param.analysis,'coh_ave')
  param.analysis.coh_ave.en = 0;
end

if ~isfield(param.analysis,'surf')
  param.analysis.surf.en = 0;
end

if param.analysis.specular.en && param.analysis.coh_ave.en
  error('Run coh ave first, then specular');
end

if ~isfield(param.analysis,'out_path')
  param.analysis.out_path = '';
end

if param.analysis.coh_ave.en
  % Coherent noise removal must be turned off to measure it
  param.get_heights.coh_noise_method    = 0;
  param.get_heights.coh_noise_arg       = [];
  % PSD smoothing must be turned off
  param.get_heights.psd_smooth = 0;
end

if param.analysis.specular.en
  % PSD smoothing must be turned off
  param.get_heights.psd_smooth = 0;
end

% =====================================================================
% Setup processing
% =====================================================================

% Get WGS84 ellipsoid parameters
physical_constants;

% Load frames file
load(ct_filename_support(param,param.records.frames_fn,'frames'));
% Load records file
records_fn = ct_filename_support(param,param.records.records_fn,'records');
records = load(records_fn);

global g_data;
g_data = [];

coh_noise_out_path = ct_filename_out(param, param.analysis.out_path, 'CSARP_noise');

if ~isfield(param.sched,'rerun_only') || isempty(param.sched.rerun_only)
  param.sched.rerun_only = false;
end

% Cleanup folders
if ~param.sched.rerun_only
  if exist(coh_noise_out_path,'dir')
    warning('Removing path %s', coh_noise_out_path);
    rmdir(coh_noise_out_path,'s');
  end
end

% =====================================================================
% Setup static inputs for coh_noise_tracker_task
% =====================================================================
task_param = param;
task_param.load.imgs = param.analysis.imgs;
  
% =====================================================================
% Setup the scheduler
% =====================================================================

if strcmpi(param.sched.type,'custom_torque')
  global ctrl; % Make this global for convenience in debugging
  ctrl = torque_new_batch(param);
  fprintf('Torque batch: %s\n', ctrl.batch_dir);
  torque_compile('coh_noise_tracker_task.m',ctrl.sched.hidden_depend_funs,ctrl.sched.force_compile);
  
elseif ~strcmpi(param.sched.type,'no scheduler')
  fd = [get_filenames(param.path,'','','.m',struct('recursive',1)); ...
    get_filenames(param.path,'','','.mexa64',struct('recursive',1))];
  fd_override = [get_filenames(param.path_override,'','','.m',struct('recursive',1)); ...
    get_filenames(param.path_override,'','','.mexa64',struct('recursive',1))];
  
  fd = merge_filelists(fd, fd_override);
  
  % Remove SVN files from path
  non_svn_path = zeros(size(fd));
  for fn_idx = 1:length(fd)
    if isempty(strfind(fd{fn_idx},'.svn'))
      non_svn_path(fn_idx) = 1;
    end
  end
  fd = fd(non_svn_path);
  
  % Initialize submission ctrl structure
  global ctrl; % Make this global for convenience in debugging
  ctrl = [];
  ctrl.cmd = 'init';
  ctrl.sched = param.sched;
  ctrl.fd = fd;
  ctrl = create_task(ctrl);
  
  % Prepare submission ctrl structure for queing jobs
  ctrl.cmd = 'task';
end

% =====================================================================
% Load data and run equal tasks
%
% For each frame load REC_BLOCK_SIZE records at a time (code groups
% by file index, but has to watch negative offset values which imply
% the record starts in a previous file and carries over into the next)
%    --> The last block can be up to 2*REC_BLOCK_SIZE
% =====================================================================
out_recs = {};
retry_fields = {};

% Determine where breaks in processing are going to occur
breaks = 1:param.analysis.block_size:length(records.gps_time);
if length(records.gps_time)-breaks(end) < param.analysis.block_size/2 ...
    && length(breaks) > 1
  breaks = breaks(1:end-1);
end
% breaks(end) =[];

for break_idx = 1:length(breaks)
  rec_load_start = breaks(break_idx);
  
  % Create the array_proc output directories
  if ~exist(coh_noise_out_path,'dir')
    mkdir(coh_noise_out_path);
  end

  if break_idx == length(breaks)
    rec_load_stop = length(records.gps_time);
  else
    rec_load_stop = rec_load_start+param.analysis.block_size-1;
  end

  if 0
    % Deconvolution hack snow 20110323_01
    rec_load_start = 264270;
    rec_load_stop = 265950;
  elseif 0
    % Deconv hack snow 20110415_01
    rec_load_start = 787654;
    rec_load_stop = 792374;
  elseif 0
    % Deconv hack snow 20120317_02
    rec_load_start = 355217-5000;
    rec_load_stop = 355217+5000;
  elseif 0
    % Deconv hack rds 20150319
    rec_load_start = 219438;
    rec_load_stop = rec_load_start + 10000;
  elseif 0
    warning('HACK FOR DEBUGGING');
    rec_load_start = 2714000;
    rec_load_stop = rec_load_start + 10000;
  elseif 0 & break_idx == length(breaks)
    % Deconv hack rds 20140315_02
    rec_load_stop = 6880000;
 end
  
  % =====================================================================
  % Prepare task inputs
  % =====================================================================
  cur_recs = [rec_load_start rec_load_stop];
  task_param.load.recs = cur_recs;
  
  % =================================================================
  % Rerun only mode: Test to see if we need to run this task
  if param.sched.rerun_only
    % If we are in rerun only mode AND all the coh_noise_tracker task output files
    % already exists, then we do not run the task
    file_exists = true;
    
    if param.analysis.coh_ave.en
      out_fn = fullfile(ct_filename_out(param, ...
        param.analysis.out_path, 'CSARP_noise'), ...
        sprintf('coh_noise_%d_%d.mat',cur_recs(1),cur_recs(end)));
    elseif param.analysis.specular.en
      out_fn = fullfile(ct_filename_out(param, ...
        param.analysis.out_path, 'CSARP_noise'), ...
        sprintf('specular_%d_%d.mat',cur_recs(1),cur_recs(end)));
    elseif param.analysis.surf.en
      out_fn = fullfile(ct_filename_out(param, ...
        param.analysis.out_path, 'CSARP_noise'), ...
        sprintf('surf_%d_%d.mat',cur_recs(1),cur_recs(end)));
    end
    
    if ~exist(out_fn,'file')
      file_exists = false;
    end

    if file_exists
      fprintf('  %d-%d: Already exists [rerun_only skipping] (%s)\n', ...
        cur_recs(1), cur_recs(end), datestr(now));
      continue;
    end
  end
  
  % =================================================================
  % Execute tasks/jobs
  fh = @coh_noise_tracker_task;
  arg{1} = task_param;
  
  if strcmp(param.sched.type,'custom_torque')
    create_task_param.conforming = true;
    create_task_param.notes = sprintf('%s records %d-%d of %d total', ...
      param.day_seg, cur_recs(1), cur_recs(end), length(records.gps_time));
    ctrl = torque_create_task(ctrl,fh,1,arg,create_task_param);
    
  elseif ~strcmp(param.sched.type,'no scheduler')
    [ctrl,job_id,task_id] = create_task(ctrl,fh,1,arg);
    fprintf('%s records %d-%d of %d total in job,task %d,%d (%s)\n', ...
      param.day_seg, cur_recs(1), cur_recs(end), length(records.gps_time), job_id, task_id, datestr(now));
    retry_fields{job_id,task_id}.arg = arg;
    out_recs{end + 1} = cur_recs;
    retry_fields{job_id,task_id}.out_idx = length(out_recs);
  else
    fprintf('\n  %s records %d-%d of %d total (%s)\n', ...
      param.day_seg, cur_recs(1), cur_recs(end), length(records.gps_time), datestr(now));
    [success] = fh(arg{1});
  end
  
end

% =======================================================================
% Wait for jobs to complete if a scheduler was used
% =======================================================================
if strcmpi(param.sched.type,'custom_torque')
  % Wait until all submitted jobs to complete
  ctrl = torque_rerun(ctrl);
  if ~all(ctrl.error_mask == 0)
    if ctrl.sched.stop_on_fail
      torque_cleanup(ctrl);
      error('Not all jobs completed, but out of retries (%s)', datestr(now));
    else
      warning('Not all jobs completed, but out of retries (%s)', datestr(now));
      keyboard;
    end
  else
    fprintf('Jobs completed (%s)\n\n', datestr(now));
  end
  torque_cleanup(ctrl);
  
elseif ~strcmpi(param.sched.type,'no scheduler')
  % ======================================================================
  % Wait for jobs to finish and clean up
  ctrl.cmd = 'done';
  ctrl = create_task(ctrl);
  if ctrl.error_mask ~= 0 && ctrl.error_mask ~= 2
    % Quit if a bad error occurred
    fprintf('Bad errors occurred, quitting (%s)\n\n', datestr(now));
    if strcmp(ctrl.sched.type,'torque')
      fprintf('Often on the Torque scheduler, these are not bad errors\n');
      fprintf('because of system instabilities (e.g. file IO failure)\n');
      fprintf('and the task simply needs to be resubmitted. If this is the case,\n');
      fprintf('run "ctrl.error_mask = 2" and then run "dbcont".\n');
      keyboard
      if ctrl.error_mask ~= 0 && ctrl.error_mask ~= 2
        return;
      end
    else
      return
    end
  end
  
  % ======================================================================
  % Retry jobs that failed
  retry = 1;
  while ctrl.error_mask == 2 && retry <= param.sched.max_retries
    fprintf('Tasks failed, retry %d of max %d\n', retry, param.sched.max_retries);
    
    % Bookkeeping (move previous run information to "old_" variables)
    old_ctrl = ctrl;
    old_retry_fields = retry_fields;
    retry_fields = {};
    old_out_recs = out_recs;
    out_recs = {};
    
    % Initialize submission ctrl structure
    ctrl = [];
    ctrl.cmd = 'init';
    ctrl.sched = param.sched;
    ctrl.fd = fd;
    ctrl = create_task(ctrl);
    
    % Prepare submission ctrl structure for queing jobs
    ctrl.cmd = 'task';
    
    % Submit failed tasks, but keep track of these in case they fail again
    for job_idx = 1:length(old_ctrl.jobs)
      for task_idx = old_ctrl.jobs{job_idx}.error_idxs
        [ctrl,job_id,task_id] = create_task(ctrl,fh,2,old_retry_fields{job_idx,task_idx}.arg);
        out_idx = old_retry_fields{job_idx,task_idx}.out_idx;
        fprintf('  %d/%d: Processing records %d to %d in job,task %d,%d (%s)\n', ...
          old_retry_fields{job_idx,task_idx}.frm, old_retry_fields{job_idx,task_idx}.break_idx, ...
          old_out_recs{out_idx}(1), old_out_recs{out_idx}(end), ...
          job_id, task_id, datestr(now));
        retry_fields{job_id,task_id} = old_retry_fields{job_idx,task_idx};
        out_recs{end + 1} = old_out_recs{out_idx};
        retry_fields{job_id,task_id}.out_idx = length(out_recs);
      end
    end
    
    % Wait for tasks to complete and then cleanup
    ctrl.cmd = 'done';
    ctrl = create_task(ctrl);
    retry = retry + 1;
    
    if ctrl.error_mask ~= 0 && ctrl.error_mask ~= 2
      % Quit if a bad error occurred
      fprintf('Bad errors occurred, quitting (%s)\n\n', datestr(now));
      if strcmp(ctrl.sched.type,'torque')
        fprintf('Often on the Torque scheduler, these are not bad errors\n');
        fprintf('because of system instabilities (e.g. file IO failure)\n');
        fprintf('and the task simply needs to be resubmitted. If this is the case,\n');
        fprintf('run "ctrl.error_mask = 2" and then run "dbcont".\n');
        keyboard
        if ctrl.error_mask ~= 0 && ctrl.error_mask ~= 2
          return;
        end
      else
        return
      end
    end
  end
  if ctrl.error_mask ~= 0
    fprintf('Not all jobs completed, but out of retries (%s)\n', datestr(now));
    return;
  else
    fprintf('Jobs completed (%s)\n\n', datestr(now));
  end
end

if param.analysis.surf.en
   %% Loop through all the surface tracker files and combine
  % =====================================================================
  for img = 1:length(param.analysis.imgs)
    gps_time = [];
    lat = [];
    lon = [];
    elev = [];
    roll = [];
    pitch = [];
    heading = [];
    surf_vals = [];
    surf_bins = [];
    for break_idx = 1:length(breaks)
      rec_load_start = breaks(break_idx);
      
      if break_idx == length(breaks)
        rec_load_stop = length(records.gps_time);
      else
        rec_load_stop = rec_load_start+param.analysis.block_size-1;
      end
      
      % =====================================================================
      % Prepare task inputs
      % =====================================================================
      cur_recs = [rec_load_start rec_load_stop];
      
      out_fn = fullfile(ct_filename_out(param, ...
        param.analysis.out_path, 'CSARP_noise'), ...
        sprintf('surf_img_%02d_%d_%d.mat', img, cur_recs(1),cur_recs(end)));
      
      surf = load(out_fn);
      
      gps_time = cat(2,gps_time,surf.gps_time);
      lat = cat(2,lat,surf.lat);
      lon = cat(2,lon,surf.lon);
      elev = cat(2,elev,surf.elev);
      roll = cat(2,roll,surf.roll);
      pitch = cat(2,pitch,surf.pitch);
      heading = cat(2,heading,surf.heading);
      surf_vals = cat(2,surf_vals,surf.surf_vals);
      surf_bins = cat(2,surf_bins,surf.surf_bins);
    end
    
    surf.gps_time = gps_time;
    surf.lat = lat;
    surf.lon = lon;
    surf.elev = elev;
    surf.roll = roll;
    surf.pitch = pitch;
    surf.heading = heading;
    surf.surf_vals = surf_vals;
    surf.surf_bins = surf_bins;
    
    out_fn_dir = fileparts(out_fn);
    out_segment_fn_dir = fileparts(out_fn_dir);
    out_segment_fn = fullfile(out_segment_fn_dir,sprintf('surf_%s_img_%02d.mat', param.day_seg, img));
    fprintf('Saving output %s (%s)\n', out_segment_fn, datestr(now));
    save(out_segment_fn,'-struct','surf');
  end
  
end

if param.analysis.coh_ave.en
  % determine the most freqent number of samples in all coherent noise
  % files, and use this number for concatenation 
  coh_noise_fns = get_filenames(ct_filename_out(param,param.analysis.out_path, 'CSARP_noise'),...
    'coh_noise','','.mat');
  num_samples = [];
  for fn_idx = 1:length(coh_noise_fns)
    matObj = matfile(coh_noise_fns{fn_idx});
    num_samples = [num_samples,size(matObj,'coh_ave',1)];
  end
  num_samples = mode(num_samples);

  %% Loop through all the coherent noise tracker files and combine
  % =====================================================================
  gps_time = [];
  lat = [];
  lon = [];
  elev = [];
  roll = [];
  pitch = [];
  heading = [];
  coh_ave = [];
  coh_ave_samples = [];
  doppler_concat = [];
  for break_idx = 1:length(breaks)
    rec_load_start = breaks(break_idx);
    
    if break_idx == length(breaks)
      rec_load_stop = length(records.gps_time);
    else
      rec_load_stop = rec_load_start+param.analysis.block_size-1;
    end
    
    % =====================================================================
    % Prepare task inputs
    % =====================================================================
    cur_recs = [rec_load_start rec_load_stop];
    
    out_fn = fullfile(ct_filename_out(param, ...
      param.analysis.out_path, 'CSARP_noise'), ...
      sprintf('coh_noise_%d_%d.mat',cur_recs(1),cur_recs(end)));
    
    noise = load(out_fn);
    if size(noise.coh_ave,1) ~= num_samples
      if any(any(isnan(noise.coh_ave))) || any(any(isnan(noise.coh_ave_samples)))
        sprintf('NaN found in noise.coh_ave or noise.coh_ave_samples')
      end
      noise.coh_ave = interp1([1:size(noise.coh_ave,1)],noise.coh_ave,linspace(1,size(noise.coh_ave,1),num_samples));
      noise.coh_ave_samples = interp1([1:size(noise.coh_ave_samples,1)],noise.coh_ave_samples,linspace(1,size(noise.coh_ave_samples,1),num_samples));
    end
    
    gps_time = cat(2,gps_time,noise.gps_time);
    lat = cat(2,lat,noise.lat);
    lon = cat(2,lon,noise.lon);
    elev = cat(2,elev,noise.elev);
    roll = cat(2,roll,noise.roll);
    pitch = cat(2,pitch,noise.pitch);
    heading = cat(2,heading,noise.heading);
    coh_ave = cat(2,coh_ave,noise.coh_ave);
    coh_ave_samples = cat(2,coh_ave_samples,noise.coh_ave_samples);
    noise.doppler = reshape(noise.doppler,[numel(noise.doppler) 1]);
    if break_idx > 1 && size(noise.doppler,1) ~= size(doppler_concat,1)
      % Block was a different size than other Doppler spectrums, re-sample
      % so that it can be stored in the output matrix
      noise.doppler = interp1(0:numel(noise.doppler)-1,noise.doppler,linspace(0,numel(noise.doppler)-1,size(doppler_concat,1)).');
    end
    doppler_concat = cat(2,doppler_concat,noise.doppler);
    
  end
  
  noise.gps_time = gps_time;
  noise.lat = lat;
  noise.lon = lon;
  noise.elev = elev;
  noise.roll = roll;
  noise.pitch = pitch;
  noise.heading = heading;
  noise.coh_ave = coh_ave;
  noise.coh_ave_samples = coh_ave_samples;
  noise.doppler = doppler_concat;
  out_fn_dir = fileparts(out_fn);
  out_segment_fn_dir = fileparts(out_fn_dir);
  out_segment_fn = fullfile(out_segment_fn_dir,sprintf('coh_noise_%s.mat', param.day_seg));
  fprintf('Saving output %s (%s)\n', out_segment_fn, datestr(now));
  save(out_segment_fn,'-struct','noise');
  
end

if param.analysis.specular.en
  % determine the most freqent number of samples in all coherent noise
  % files, and use this number for concatenation 
  specular_fns = get_filenames(ct_filename_out(param,param.analysis.out_path, 'CSARP_noise'),...
    'specular','','.mat');
  num_samples = [];
  for fn_idx = 1:length(specular_fns)
    matObj = matfile(specular_fns{fn_idx});
    num_samples = [num_samples,cellfun(@length,matObj.deconv_mean)];
  end
  num_samples = mode(num_samples);

  %% Loop through all the specular files and combine
  % Returns results about each block of data processed.
  % For blocks with good peakiness (assumed to be specular leads), we
  %   also return the return. To achieve better SNR and understanding
  %   of the waveform we group analysis.specular.ave range lines. After
  %   amplitude, delay, and phase alignment, we store the mean and std
  %   of these range lines. We also store a single range line from the
  %   center of the group for estimating the properties of the deconvolution.
  % =====================================================================
  gps_time = [];
  lat = [];
  lon = [];
  elev = [];
  roll = [];
  pitch = [];
  heading = [];
  peakiness = [];
  deconv_gps_time = [];
  deconv_mean = {};
  deconv_std = {};
  deconv_sample = {};
  deconv_time = {};
  deconv_freq = [];
  deconv_twtt = [];
  deconv_forced = [];
  for break_idx = 1:length(breaks)
    rec_load_start = breaks(break_idx);
    
    if break_idx == length(breaks)
      rec_load_stop = length(records.gps_time);
    else
      rec_load_stop = rec_load_start+param.analysis.block_size-1;
    end
    
    % =====================================================================
    % Prepare task inputs
    % =====================================================================
    cur_recs = [rec_load_start rec_load_stop];
    
    out_fn = fullfile(ct_filename_out(param, ...
      param.analysis.out_path, 'CSARP_noise'), ...
      sprintf('specular_%d_%d.mat',cur_recs(1),cur_recs(end)));
    
    spec = load(out_fn);
    
    if ~isempty(spec.deconv_mean) && size(spec.deconv_mean{1},1) ~= num_samples
      for idx = 1:length(spec.deconv_mean)
        spec.deconv_mean{idx} = interp1([1:length(spec.deconv_mean{idx})]',spec.deconv_mean{idx},linspace(1,length(spec.deconv_mean{idx}),num_samples)');
        spec.deconv_std{idx} = interp1([1:length(spec.deconv_std{idx})]',spec.deconv_std{idx},linspace(1,length(spec.deconv_std{idx}),num_samples)');
        spec.deconv_sample{idx} = interp1([1:length(spec.deconv_sample{idx})]',spec.deconv_sample{idx},linspace(1,length(spec.deconv_sample{idx}),num_samples)');
     end
    end
    wfs_time = {};
    wfs_freq = [];
    if ~isempty(spec.deconv_mean) && size(spec.wfs.freq,1) ~= num_samples
      for idx = 1:length(spec.deconv_mean)
        wf_time = interp1([1:length(spec.wfs.time{1})]',spec.wfs.time{1},linspace(1,length(spec.wfs.time{1}),num_samples)');
        wf_freq = interp1([1:length(spec.wfs.freq)]',spec.wfs.freq,linspace(1,length(spec.wfs.freq),num_samples)');
        wfs_time = cat(2,wfs_time,wf_time);
        wfs_freq = cat(2,wfs_freq,wf_freq);
      end
    elseif ~isempty(spec.deconv_mean)
      for idx = 1:length(spec.deconv_mean)
        wf_time = spec.wfs.time;
        wf_freq = spec.wfs.freq;
        wfs_time = cat(2,wfs_time,wf_time);
        wfs_freq = cat(2,wfs_freq,wf_freq);
     end
    end
    gps_time = cat(2,gps_time,spec.gps_time);
    lat = cat(2,lat,spec.lat);
    lon = cat(2,lon,spec.lon);
    elev = cat(2,elev,spec.elev);
    roll = cat(2,roll,spec.roll);
    pitch = cat(2,pitch,spec.pitch);
    heading = cat(2,heading,spec.heading);
    peakiness = cat(2,peakiness,spec.peakiness);
    deconv_gps_time = cat(2,deconv_gps_time,spec.deconv_gps_time);
    deconv_mean = cat(2,deconv_mean,spec.deconv_mean);
    deconv_std = cat(2,deconv_std,spec.deconv_std);
    deconv_sample = cat(2,deconv_sample,spec.deconv_sample);
    deconv_time = cat(2,deconv_time,wfs_time);
    deconv_freq = cat(2,deconv_freq,wfs_freq);
    deconv_twtt = cat(2,deconv_twtt,spec.deconv_twtt);
    if ~isfield(spec,'deconv_forced')% HACK: IF STATEMENT SHOULD BE REMOVED
      spec.deconv_forced = zeros(size(spec.deconv_twtt));
    end
    deconv_forced = cat(2,deconv_forced,spec.deconv_forced);
  end
  
  spec.gps_time = gps_time;
  spec.lat = lat;
  spec.lon = lon;
  spec.elev = elev;
  spec.roll = roll;
  spec.pitch = pitch;
  spec.heading = heading;
  spec.peakiness = peakiness;
  spec.deconv_gps_time = deconv_gps_time;
  spec.deconv_mean = deconv_mean;
  spec.deconv_std = deconv_std;
  spec.deconv_sample = deconv_sample;
  spec.wf_time = deconv_time;
  spec.wf_freq = deconv_freq;
  spec.deconv_twtt = deconv_twtt;
  spec.deconv_forced = deconv_forced;
  out_fn_dir = fileparts(out_fn);
  out_segment_fn_dir = fileparts(out_fn_dir);
  out_segment_fn = fullfile(out_segment_fn_dir,sprintf('specular_%s.mat', param.day_seg));
  fprintf('Saving output %s (%s)\n', out_segment_fn, datestr(now));
  save(out_segment_fn,'-struct','spec');
end

return;

figure(101); clf;
imagesc(lp(coh_ave))
xlabel('Range line (slow time)');
ylabel('Range bin (fast time)');
h = colorbar;
ylabel(h,'Relative power (dB)');

imagesc(angle(coh_ave))
imagesc(coh_ave_samples)

% Cross correlate to track time shift from one record to the next
coh_ave_f = fft(coh_ave,2*size(coh_ave,1));
Mt = 10;
coh_ave_xcorr = fftshift(ifft(coh_ave_f .* repmat(conj(coh_ave_f(:,1)), [1 size(coh_ave_f,2)]), Mt*size(coh_ave_f,1)),1);
% coh_ave_xcorr = interpft(coh_ave_xcorr,Mt*size(coh_ave_xcorr,1));
[peak_corr offset] = max(coh_ave_xcorr);
figure(1); clf;
plot((offset-offset(1))/Mt);
xlabel('Range line');
ylabel('Cross correlation bin offset');

figure(2); clf;
plot(unwrap(angle(coh_ave([2728:100:3400],:)).')*180/pi)
% plot(angle(coh_ave([4000:100:4600],:)).'*180/pi)
xlabel('Range line');
ylabel('Angle');

figure(3); clf;
plot(lp(coh_ave([4000:100:4600],:)).')
xlabel('Range line');
ylabel('Log power (dB)');

plot(lp(coh_ave_xcorr(:,2)))

