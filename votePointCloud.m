[labels, frame_labels] = readLabels('traderjoe');

for ver=0:200:800
  votePointCloud_(ver, labels, frame_labels)
end

function votePointCloud_(ver, labels, frame_labels)
  disp(sprintf('Ver: %d', ver));

  [num_pt, pts, ptIds] = readPointCloud(ver);
  if num_pt == 0 
    disp('  No points');
    return; 
  end

  disp('  Cloud read');

  votes = zeros(num_pt, size(labels,2));

  %% Refer calib_fisheye_zshade.txt
  fx = 562.89536;
  fy = 557.29656;
  px = 630.7712;
  py = 363.16152;
  omega = 1.03815;
  slant = 0;
  tan_omega_half_2 = 2 * tan(omega/2);
  K = [ fx slant px; 0 fy py; 0 0 1 ] * eye(3,4);  I = eye(4);

  cfname = sprintf('reconstruction%07d/camera.txt', ver);
  cfid = fopen(cfname);
  for i=1:2, fgetl(cfid); end
  num_poses = textscan(cfid, '%s %d', 1); num_poses = num_poses{2};
  frameIds = zeros(num_poses, 1); % poses = zeros(num_poses, 3, 4);

  for i=1:num_poses
    frame = textscan(cfid, '%d %d', 1);
    frame = frame{2}+1;
    frameIds(i) = frame;
    frame = ver+frame;

    C = zeros(4);   c = cell2mat(textscan(cfid, '%f %f %f', 1))';   C(1:3,4) = c;
    R = eye(4);     r = cell2mat(textscan(cfid, '%f %f %f', 3));    R(1:3,1:3) = r;
    zaxis = r' * [0 0 1]';
    zs = (pts(:,1:3) - repmat(c',num_pt,1)) * zaxis;

    pose = K * R * (I - C);
    % poses(i,:,:) = pose;

    projections = (pose * pts')';
    projections = projections ./ projections(:,3);
    xs = projections(:,1);  ys = projections(:,2);
    for j=1:num_pt
      u = xs(j); v = ys(j);
      
      u_n = (u - px)/fx;
      v_n = (v - py)/fy;

      r_u = sqrt(u_n^2 + v_n^2);
      r_d = 1/omega * atan(r_u * tan_omega_half_2);

      u_dn = r_d/r_u * u_n;
      v_dn = r_d/r_u * v_n;

      u_d = fx*u_dn + px;
      v_d = fy*v_dn + py;

      xs(j) = u_d;
      ys(j) = v_d;
    end

    % determine valid points being projected onto image and then segment left-right
    Z = zs > 0;
    Y = 0 < ys & ys <= 720;
    left = find(0 < xs & xs <= 640 & Y & Z);
    right = find(640 < xs & xs <= 1280 & Y & Z);

    frame = idivide(frame,int32(25))+1;
    frame_label = frame_labels(frame, :);
    llabel = frame_label(1); rlabel = frame_label(2);
    for pt = left,  votes(pt,llabel) = votes(pt,llabel) + 1; end
    for pt = right, votes(pt,rlabel) = votes(pt,rlabel) + 1; end
  end

  [~, votes] = max(votes');
  votes = votes';
  save(sprintf('reconstruction%07d/labeled_cloud.mat', ver), 'labels', 'ptIds', 'votes');

  disp('  Sections found:');
  for i=1:17
    s = sum(votes==i);
    if s > 0, disp(sprintf('    %s - %d%% votes', labels{i}, round(100*s/size(votes,1)))); end
  end

  fclose(cfid);
end
