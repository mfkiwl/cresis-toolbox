

folders_to_create = {'../../../../tuning_results', ...
  '../../../../tuning_results/grid_search_viterbi_3D',...
  '../../../../tuning_results/grid_search_viterbi_2D',...
  '../../../../tuning_results/grid_search_trws_3D',...
  '../../../../tuning_results/random_search_viterbi_3D',...
  '../../../../tuning_results/random_search_viterbi_2D',...
  '../../../../tuning_results/random_search_trws_3D'
  };


for idx = 1:length(folders_to_create)
  if exist(folders_to_create{idx}, 'dir')    
    continue;
  else
    mkdir(folders_to_create{idx});
  end
end