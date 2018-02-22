% [labels, frame_labels, label_colors] = readLabels('traderjoe');
[labels, ~, ~] = readLabels('traderjoe');

n = size(labels,2);
adjacency_matrix = zeros(n);
freqs = zeros(n);
for ver=0:200:800
  adjacency_matrix_ver = adjacencyMatrixFromCloud_(ver, labels);
  adjacency_matrix = adjacency_matrix + adjacency_matrix_ver;
  % disp(adjacency_matrix);
  idx = adjacency_matrix_ver > 0;
  freqs(idx) = freqs(idx) + 1;
end
freqs(freqs == 0) = 1;
adjacency_matrix = adjacency_matrix ./ freqs;
disp(adjacency_matrix);
save('adjacencyMatrixFromCloud.mat', 'adjacency_matrix', 'freqs');

function [adjacency_matrix_ver] = adjacencyMatrixFromCloud_(ver, labels)
  % get votes, labels from here
  disp(sprintf('Ver: %d', ver));
  n = size(labels,2)-1;
  adjacency_matrix_ver = zeros(n);

  [num_pt, pts, ~] = readPointCloud(ver);
  if num_pt == 0 
    disp('  No points');
    return; 
  end

  pts = pts(:,1:3);
  disp('  Cloud read');

  load(sprintf('reconstruction%07d/labeled_cloud.mat', ver));

  sums = zeros(n,1);
  locs = zeros(n,3);
  sum_threshold = 10;
  for i=1:n
    idx = votes == i;
    s = sum(idx);
    sums(i) = s;
    if s > sum_threshold
      locs(i,:) = median(pts(idx, :));
    end
  end
  for i=1:n-1
    si = sums(i);
    if si > sum_threshold
      for j=i+1:n
        sj = sums(j);
        if sj > sum_threshold
          dist = norm(locs(i) - locs(j));
          adjacency_matrix_ver(i,j) = dist;   adjacency_matrix_ver(j,i) = dist;
        end
      end
    end
  end
end
