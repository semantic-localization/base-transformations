function constructAdjacencyMatrix(store)
  filename = sprintf('%s_adjacency.mat', lower(store));
  load(filename);
  imagesc(adjacency_matrix);
  colorbar;
  xticks(1:size(adjacency_matrix, 1));
  xticklabels(labels);
  yticks(1:size(adjacency_matrix, 1));
  yticklabels(labels);
  title(sprintf('%s Adjacency Matrix', store));
end
