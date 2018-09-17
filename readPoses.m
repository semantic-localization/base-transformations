function [frameIds, Rs, Cs] = readPoses(ver)
  mfile = sprintf('reconstruction%07d/poses.mat', ver);
  if exist(mfile, 'file') == 2
    load(mfile);
    return;
  end

  cfname = sprintf('reconstruction%07d/camera.txt', ver);
  cfid = fopen(cfname);
  if cfid == -1
    frameIds = [];
    Rs = [];
    Cs = [];
    return;
  end

  for i=1:2, fgetl(cfid); end

  num_poses = textscan(cfid, '%s %d', 1); num_poses = num_poses{2};
  frameIds = zeros(num_poses, 1); 
  Rs = zeros(num_poses, 4, 4);
  Cs = zeros(num_poses, 3);

  for i=1:num_poses
    frame = textscan(cfid, '%d %d', 1);
    frame = frame{2}+1;
    frameIds(i) = frame;

    Cs(i,:) = cell2mat(textscan(cfid, '%f %f %f', 1));
    R = eye(4); R(1:3,1:3) = cell2mat(textscan(cfid, '%f %f %f', 3));
    Rs(i,:,:) = R;
  end

  save(mfile, 'frameIds', 'Rs', 'Cs');
end
