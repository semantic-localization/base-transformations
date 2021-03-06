function [num_pt, pts, ptIds, rgb] = readPointCloud(ver)
  mfile = sprintf('reconstruction%07d/points.mat', ver);
  if exist(mfile, 'file') == 2
    load(mfile);
    return;
  end

  sfname = sprintf('reconstruction%07d/structure.txt', ver);
  sfid = fopen(sfname);
  if sfid == -1
    num_pt = 0;
    ptIds = [];
    pts = [];
    return;
  end

  num_pt = textscan(sfid, '%s %d', 1); num_pt = num_pt{2};

  % store point IDs
  ptIds = zeros(num_pt, 1);
  % store (x,y,z,1) pts w homogeneous coords
  pts = zeros(num_pt, 4);
  rgb = zeros(num_pt, 3);

  for i=1:num_pt
    pt = textscan(sfid, '%d %d %d %d %f %f %f', 1);
    ptIds(i) = pt{1};
    pts(i,:) = [ pt{5} pt{6} pt{7} 1 ];
    rgb(i,:) = [ pt{2} pt{3} pt{4} ];
  end
  fclose(sfid);

  save(mfile, 'num_pt', 'pts', 'ptIds', 'rgb');
end
