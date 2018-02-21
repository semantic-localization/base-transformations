K = [ 562.89536 1.03815 630.7712; 0 557.29656 363.16152; 0 0 1 ] * eye(3,4);
projections = containers.Map('UniformValues',false);


for f_i = 0:200:18801
  f_name = sprintf('reconstruction00%05d/camera.txt', f_i);
  fid = fopen(f_name);
  if fid ~= -1
    textscan(fid, '%*[^\n]', 3);
    poses = extract_poses(fid);
    i = 1;
    while i <= 200 && i <= size(poses,2)
      projections = project_onto_frame(i, f_i, poses, K, projections);
      i = i + 1;
    end
    fclose(fid);
  else
      disp(sprintf('%s does not exist.', f_name));
  end
end


save('projections.mat', 'projections');


function [poses] = extract_poses(fid)
  poses = {};
  while true
    frame = textscan(fid, '%d %d', 1);
    frame = frame{2};
    if ~isempty(frame)
      C = cell2mat(textscan(fid, '%f %f %f', 1))';
      R = eye(4); R(1:3,1:3) = cell2mat(textscan(fid, '%f %f %f', 3));
      pose = {}; pose{1} = R; pose{2} = C;
      poses{frame + 1} = pose;
    else
      break
    end
  end
end


function [projections] = project_onto_frame(i, f_i, poses, K, projections)
  pose = poses{i};
  if isempty(pose), return, end
  R_i = pose{1};
  c_i = pose{2}; C_i = zeros(4); C_i(1:3,4) = c_i;
  prjctn_matrix = K * R_i * (eye(4) - C_i);

  initial_skip = 10;
  num_pred = 60;
  j = initial_skip + 1;
  projections_ = {};
  while j < num_pred + 1 && i+j <= size(poses, 2)
    pose = poses{i+j};
    if ~isempty(pose)
      % disp(f_i); disp(i); disp(j);
      pos = [pose{2}; 1];
      prjctn = prjctn_matrix * pos;
      prjctn = prjctn ./ prjctn(3);
      projections_{j-initial_skip} = prjctn(1:2);
    end
    j = j + 1;
  end
  projections(int2str(f_i + i)) = projections_;
end
