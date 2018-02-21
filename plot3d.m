fid = fopen(sprintf('reconstruction%07d/structure.txt', 600));
if fid ~= -1
  num_pt = textscan(fid, '%s %d', 1); num_pt = num_pt{2};
  pts = {}; 
  xs = zeros(num_pt,1); ys = zeros(num_pt,1); zs = zeros(num_pt,1);
  rgb = zeros(num_pt,3);
  for i=1:num_pt
    pt = textscan(fid, '%d %d %d %d %f %f %f', 1);
    xs(i) = pt{5}; ys(i) = pt{6}; zs(i) = pt{7};
    rgb(i,:) = [ pt{2} pt{3} pt{4} ];
    pts{i} = pt;
  end
  centers = median([xs,ys,zs]);
  sigma = std([xs,ys,zs]);
  scatter3(xs,ys,zs,[],rgb./255,'filled');
  axis([centers(1)-sigma(1), centers(1)+sigma(1), centers(2)-sigma(2), centers(2)+sigma(2), centers(3)-sigma(3), centers(3)+sigma(3)]);
  ax = gca;
  ax.DataAspectRatio = [1 1 1];
end
fclose(fid);
