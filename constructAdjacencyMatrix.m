function constructAdjacencyMatrix(store, cmax)
  filename = sprintf('visualization/adjacency_matrices/%s_adjacency.mat', lower(store));
  load(filename);
  if exist('cmax', 'var')
    imagesc(adjacency_matrix, [0 cmax]);
  else
    imagesc(adjacency_matrix);
  end
  colorbar;
  xticks(1:size(adjacency_matrix, 1));
  xticklabels(labels);
  yticks(1:size(adjacency_matrix, 1));
  yticklabels(labels);
  title(sprintf('%s Adjacency Matrix', store));
end
