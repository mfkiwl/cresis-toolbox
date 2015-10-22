function layers = opsCopyLayers(param,copy_param)
% layers = opsCopyLayers(param,copy_param)
%
% Copies contents from one layers into another layer. The copy method can
% be merge, overwrite, or fill gaps.
%
% NOT COMPLETE, DOES NOT SUPPORT echogram destination or  "eval" field
%
% Input:
%   params: Specify the segment you wish to copy on the params spreadsheet
%   copy_param:
%     .layer_source = structure specifying the source layer
%       .name: string (e.g. 'surface', 'Surface', 'bottom', 'atm', etc)
%       .source: string (e.g. 'records', 'echogram', 'layerdata', or 'ops')
%       .echogram_source = string (e.g. 'qlook', 'mvdr', 'CSARP_post/standard')
%       .layerdata_source = string (e.g. 'layerData', 'CSARP_post/layerData')
%     .layer_dest = structure specifying the destination layer
%       .name: string (e.g. 'surface', 'Surface', 'bottom', 'atm', etc)
%       .source: string (e.g. 'records', 'echogram', 'layerdata', or 'ops')
%       .echogram_source = string (e.g. 'qlook', 'mvdr', 'CSARP_post/standard')
%       .layerdata_source = string (e.g. 'layerData', 'CSARP_post/layerData')
%     .group and .description fields must also be included if the layer does
%        not exist and is being inserted into "ops" source
%     .eval = Optional. If included, function evaluates this string with eval.
%        Variables available are gps_time (sec), along_track (m), source
%         interpolated onto dest (twtt in sec), and dest (twtt in sec).
%        The string should generally update "source" variable. For example:
%           '[B,A] = butter(0.1,2); source = filtfilt(B,A,source);'
%           'source = source + 0.1;'
%           'source = my_interp_function(gps_time,along_track,source,dest);'
%     .copy_method = string specifying one of these methods
%       'fillgaps': only gaps in destination data will be written to
%       'overwrite': none of the previous data are kept
%       'merge': anywhere source data exists, destination data will be
%         overwritten
%     .gap_fill: struct controlling interpolation across gaps in source
%     .gaps_dist: two element vector used by opsInterpLayersToMasterGPSTime
%     .method: string specifying one of these methods
%       'preserve_gaps': runs opsInterpLayersToMasterGPSTime
%       'interp_finite': runs interp_finite
%
% Authors: John Paden, Abbey Whisler
%
% See also: runOpsCopyLayers.m, opsMergeLayerData, opsCopyLayers


%% Determine if the copy method and gap filling method are valid
if ~any(strcmpi(copy_param.copy_method,{'fillgaps','overwrite','merge'}))
  error('Invalid copy_method %s', copy_param.copy_method);
end

if ~any(strcmpi(copy_param.gaps_fill.method,{'preserve_gaps','interp_finite'}))
  error('Invalid gap_fill.method %s', copy_param.gap_fill.method);
end

if strcmpi(copy_param.gaps_fill.method,'preserve_gaps') ...
    && ~isfield(copy_param.gaps_fill,'method_args') || isempty(copy_param.gaps_fill.method_args)
  copy_param.gaps_fill.method_args = [300 60];
end

physical_constants;

%% Load "frames" file
load(ct_filename_support(param,param.records.frames_fn,'frames'));

%% Determine which frames to be processed
if isempty(param.cmd.frms)
  param.cmd.frms = 1:length(frames.frame_idxs);
end
% Remove frames that do not exist from param.cmd.frms list
[valid_frms,keep_idxs] = intersect(param.cmd.frms, 1:length(frames.frame_idxs));
if length(valid_frms) ~= length(param.cmd.frms)
  bad_mask = ones(size(param.cmd.frms));
  bad_mask(keep_idxs) = 0;
  warning('Nonexistent frames specified in param.cmd.frms (e.g. frame "%g" is invalid), removing these', ...
    param.cmd.frms(find(bad_mask,1)));
  param.cmd.frms = valid_frms;
end

%% Load source layer data and existing destination layer data for this segment
% Load all frames (for better edge interpolation)
load_param = param;
load_param.cmd.frms = 1:length(frames.frame_idxs);
layer_source = opsLoadLayers(load_param,copy_param.layer_source);
layer_dest = opsLoadLayers(load_param,copy_param.layer_dest);

%% Load framing information (to determine start/stop gps times of each frame)
if strcmpi(copy_param.layer_dest.source,'ops')
  sys = ct_output_dir(param.radar_name);
  ops_param = struct('properties',[]);
  ops_param.properties.season = param.season_name;
  ops_param.properties.segment = param.day_seg;
  [~,ops_frames] = opsGetSegmentInfo(sys,ops_param);
else
  % records, lidar, layerdata, and echogram sources use records file for
  % framing gps time info
  records_fn = ct_filename_support(param,param.records.records_fn,'records');
  records = load(records_fn,'gps_time','surface','elev','lat','lon');
end

%% Copy/Merge based on destination, copy_method, and gaps_fill.method.
%    Lists below describe the steps for each possible combination of
%    layer_dest.source, copy_method, and gaps_fill.method settings.
%
% If layer_dest.source is 'records', 'layerdata', or 'echogram':
%
% copy_method = 'fillgaps',gaps_fill.method = 'interp_finite'
%   - Find NaN in destination
%   - Interpolate source onto these points using interpfinite style of interpolation
%   - Only update these points in the destination
% fillgaps,preserve_gaps
%   - Find NaN in destination
%   - Interpolate source onto these points using opsInterpLayersToMasterGPSTime
%   - Only update these points in the destination
% overwrite,interp_finite
%   - Find all points in destination
%   - Interpolate source onto these points using interpfinite style of interpolation
%   - Write these points on to the destination (does not require original layer information)
% overwrite,preserve_gaps
%   - Find all points in destination
%   - Interpolate source onto these points using opsInterpLayersToMasterGPSTime
%   - Write these points on to the destination (does not require original layer information)
% merge,interp_finite
%   - This is identical to overwrite,interp_finite (does not require original layer information)
% merge,preserve_gaps
%   - Find all points in destination
%   - Interpolate source onto these points using opsInterpLayersToMasterGPSTime
%   - Keep only the ~isnan points
%   - Only update these points in the destination
%
% If layer_dest.source is 'ops':
%
% fillgaps,interp_finite
%   - Find flightline points that don't have a pick in the destination
%   - Interpolate source onto these points using interpfinite style of interpolation
%   - Only update these points in the destination (does not require original layer information)
% fillgaps,preserve_gaps
%   - Find flightline points that don't have a pick in the destination
%   - Interpolate source onto these points using opsInterpLayersToMasterGPSTime
%   - Only update these points in the destination (does not require original layer information)
% overwrite,interp_finite
%   - Find all points in destination
%   - Interpolate source onto these points using interpfinite style of interpolation
%   - Write these points on to the destination (does not require original layer information)
% overwrite,preserve_gaps
%   - Find all points in destination
%   - Interpolate source onto these points using opsInterpLayersToMasterGPSTime
%   - Write these points on to the destination (does not require original layer information)
% merge,interp_finite
%   - This is identical to overwrite,interp_finite
% merge,preserve_gaps
%   - Find all points in destination
%   - Interpolate source onto these points using opsInterpLayersToMasterGPSTime
%   - Keep only the ~isnan points
%   - Only update these points in the destination (does not require original layer information)

%% Create all_points: a structure containing every point in the destination
% for this segments with these fields
%  .gps_time, .lat, .lon, .elev
%  .ids: only if ops is the destination (database point IDs)
%  .twtt: the current twtt for each point (NaN means does not exist)
%  .twtt_interp: the new twtt for each point
if strcmpi(copy_param.layer_dest.source,'ops')
  % OPS source only returns points with picks from opsLoadLayers. So to get the
  % points that do not have picks, we have to load the flight lines.
  ops_param = struct('properties',[]);
  ops_param.properties.location = param.post.ops.location;
  ops_param.properties.season = param.season_name;
  ops_param.properties.start_gps_time = ops_frames.properties.start_gps_time(1);
  ops_param.properties.stop_gps_time = ops_frames.properties.stop_gps_time(end);
  ops_param.properties.nativeGeom = true;
  %ops_param.properties.lyr_id = ops_data.properties.id;
  [~,ops_data] = opsGetPath(sys,ops_param);

  all_points.gps_time = ops_data.properties.gps_time;
  all_points.lat = ops_data.properties.Y;
  all_points.lon = ops_data.properties.X;
  all_points.elev = ops_data.properties.elev;

  % Runs through each data point. At each ops_data point id, if there is
  % no layer_dest point id that matches it, that point is assigned NaN
  all_points.ids = ops_data.properties.id;
  all_points.twtt = zeros(size(ops_data.properties.id));

  for point_idx = 1:length(all_points.ids)
    match_idx = find(all_points.ids(point_idx) == layer_dest.point_path_id);
    if isempty(match_idx)
     all_points.twtt(point_idx) = NaN;
    else
     all_points.twtt(point_idx) = layer_dest.twtt(match_idx);
    end
  end

else
  % Non-OPS sources automatically include all points since NaN are used to
  % fill in missing points
  all_points.gps_time = layer_dest.gps_time;
  all_points.lat = layer_dest.lat;
  all_points.lon = layer_dest.lon;
  all_points.elev = layer_dest.elev;
  all_points.ids = layer_dest.point_path_id;
  all_points.twtt = layer_dest.twtt;
end

% Set invalid types to "auto" or 2
layer_source.type(isnan(layer_source.type)) = 2;
% Set invalid quality levels to "good" or 1
layer_source.quality(isnan(layer_source.quality)) = 1;
layer_source.quality(layer_source.quality ~= 1 & layer_source.quality ~= 2 & layer_source.quality ~= 3) = 1;

if strcmpi(copy_param.gaps_fill.method,'preserve_gaps')
  %% interpolation preserves_gaps
  
  master = [];
  master.GPS_time = all_points.gps_time;
  master.Latitude = all_points.lat;
  master.Longitude = all_points.lon;
  master.Elevation = all_points.elev;
  ops_layer = [];
  ops_layer{1}.gps_time = layer_source.gps_time;
  ops_layer{1}.type = layer_source.type;
  ops_layer{1}.quality = layer_source.quality;
  ops_layer{1}.twtt = layer_source.twtt;
  lay = opsInterpLayersToMasterGPSTime(master,ops_layer,copy_param.gaps_fill.method_args);
  all_points.twtt_interp = lay.layerData{1}.value{2}.data;
  
elseif strcmpi(copy_param.gaps_fill.method,'interp_finite')
  %% interpolation follows interp_finite
  
  % Interpolate source onto destination points using linear interpolation
  all_points.twtt_interp = interp1(layer_source.gps_time, layer_source.twtt, all_points.gps_time);
  % Fill in NaN gaps using interp_finite
  all_points.twtt_interp = interp_finite(all_points.twtt_interp,1);
end

%% Combine the newly interpolated result with the current values
if strcmpi(copy_param.copy_method,'fillgaps')
  update_mask = isnan(all_points.twtt) & ~isnan(all_points.twtt_interp);
elseif strcmpi(copy_param.copy_method,'merge')
  update_mask = ~isnan(all_points.twtt_interp);
elseif strcmpi(copy_param.copy_method,'overwrite')
  update_mask = logical(ones(size(all_points.twtt)));
end 

%% For nonselected frames, set update_mask to zero for all points in those frames
all_frms = 1:length(frames.frame_idxs);
% If the user selects all frames in the segment on the params
% spreadsheet, then the update mask will not change.
% Otherwise we will create a new mask where each point within the start
% and stop gps times of the selected frames is equal to 1 and all other
% points are equal to 0.
frms_mask = zeros(size(update_mask));
if strcmpi(copy_param.layer_dest.source,'ops')
  for frm = param.cmd.frms
    frms_mask(all_points.gps_time >= ops_frames.properties.start_gps_time(frm)...
          & all_points.gps_time < ops_frames.properties.stop_gps_time(frm)) = 1;
  end
  
else
  for frm = param.cmd.frms
    records.gps_time(frames.frame_idxs(frm));
    if frm < length(frames.frame_idxs)
      frms_mask(all_points.gps_time >= records.gps_time(frames.frame_idxs(frm))...
        & all_points.gps_time < records.gps_time(frames.frame_idxs(frm+1))) = 1;
    else
      frms_mask(all_points.gps_time >= records.gps_time(frames.frame_idxs(frm))...
        & all_points.gps_time < records.gps_time(end)) = 1;
    end
  end
end

update_mask = frms_mask & update_mask;

%% Perform function evaluation
if isfield(copy_param,'eval') && ~isempty(copy_param.eval)
  error('copy_param.eval is not supported');
end

%% Write the new layer data to the destination
surface = all_points.twtt;
surface(update_mask) = all_points.twtt_interp(update_mask);

if 0
  % Debug code
  figure(1); clf;
  plot(all_points.twtt);
  hold on;
  plot(surface(update_mask),'rx');
  grid on;
  hold off;
  drawnow;
  pause(1);
end

if strcmpi(copy_param.layer_dest.source,'ops')
  %% Remove all_points that are not in the selected frames
  % Use update_mask to exclude all points that are not getting updated
  ops_param.properties.point_path_id = all_points.ids(update_mask);
  ops_param.properties.twtt = surface(update_mask);
  ops_param.properties.type = 2*ones(size(ops_param.properties.twtt));
  ops_param.properties.quality = 1*ones(size(ops_param.properties.twtt));
  ops_param.properties.lyr_name = copy_param.layer_dest.name;
  
  %% Update these points
  opsCreateLayerPoints(sys,ops_param);
  
elseif strcmpi(copy_param.layer_dest.source,'layerdata')
  for frm = param.cmd.frms
    %% Loop through and update selected frame files with surface
    layer_fn = fullfile(ct_filename_out(param,copy_param.layer_dest.layerdata_source,''),...
      sprintf('Data_%s_%03d.mat', param.day_seg, frm));
    if ~exist(layer_fn,'file')
      warning('Layer data file does not exist: %s\n', layer_fn);
      continue;
    end
    lay = load(layer_fn);
    
    % Determine which index into lay.layerData needs to be updated
    if strcmpi(copy_param.layer_dest.name,'surface')
      lay_idx = 1;
      found = true;
    elseif strcmpi(copy_param.layer_dest.name,'bottom')
      lay_idx = 2;
      found = true;
    else
      found = false;
      for lay_idx = 1:length(lay.layerData)
        if isfield(lay.layerData{lay_idx},'name') ...
            && strcmpi(lay.layerData{lay_idx}.name,copy_param.layer_dest.name)
          found = true;
          break;
        end
      end
      if ~found
        % Add a new layer if layer does not exist
        lay_idx = length(lay.layerData) + 1;
        lay.layerData{lay_idx}.name = copy_param.layer_dest.name;
        % Create manual points
        lay.layerData{lay_idx}.value{1}.data = NaN*zeros(size(lay.GPS_time));
        % Create auto points
        lay.layerData{lay_idx}.value{2}.data = NaN*zeros(size(lay.GPS_time));
        % Set quality to good
        lay.layerData{lay_idx}.quality = 1*ones(size(lay.GPS_time));
      end
    end
    
    % Manual points
    % Not supported
    
    % Automated points
    lay.layerData{lay_idx}.value{2}.data = interp1(all_points.gps_time,surface,lay.GPS_time);
    
    % Append the new results back to the layerData file
    save(layer_fn,'-append','-struct','lay','layerData');
  end
  
elseif strcmpi(copy_param.layer_dest.source,'echogram')
  %% Loop through and update selected frame files with surface
  for frm = param.cmd.frms
    % Create file name for each frame
    echo_fn = fullfile(ct_filename_out(param,copy_param.layer_dest.echogram_source,''), ...
      sprintf('Data_%s_%03d.mat', param.day_seg, frm));
    if ~exist(echo_fn,'file')
      warning('Echogram data file does not exist: %s\n', echo_fn);
      continue;
    end
    
    % Load echogram
    echo = load(echo_fn,'GPS_time');
    
    % Create automated points:
    % Surface
    if strcmpi(copy_param.layer_dest.name,'surface')
      echo.Surface = interp1(all_points.gps_time,surface,echo.GPS_time);
      % Append the new results back to the echogram file
      save(echo_fn,'-append','-struct','echo','Surface'); 
    % Bottom
    elseif strcmpi(copy_param.layer_dest.name,'bottom')
      echo.Bottom = interp1(all_points.gps_time,surface,echo.GPS_time);
      % Append the new results back to the echogram file
      save(echo_fn,'-append','-struct','echo','Bottom');
    else
      echo.(copy_param.layer_dest.name) = interp1(all_points.gps_time,surface,echo.GPS_time);
      % Append the new results back to the echogram file
      save(echo_fn,'-append','-struct','echo',copy_param.layer_dest.name);
    end
  
  end
  
elseif strcmpi(copy_param.layer_dest.source,'records')
  save(records_fn,'-append','surface');
  create_records_aux_files(records_fn);
  
end

return;