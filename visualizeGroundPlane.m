function visualizeGroundPlane(ver, i)
  % gravity = [ 0.0128601  0.99023344  -0.1388249 1 ]';
  gravity = [-0.06943232,  0.99357245, -0.08940322 1]';

  % get votes, labels from here
  disp(sprintf('Ver: %d', ver));

  [num_pt, pts, ~, rgb] = readPointCloud(ver);
  xs = pts(:,1);
  ys = pts(:,2);
  zs = pts(:,3);
  % xs_inliers = (xs > prctile(xs,5)) & (xs < prctile(xs,95));
  % ys_inliers = (ys > prctile(ys,5)) & (ys < prctile(ys,95));
  % zs_inliers = (zs > prctile(zs,5)) & (zs < prctile(zs,95));
  % pts = pts(xs_inliers & ys_inliers & zs_inliers, :);

  centers = median([xs,ys,zs]);
  sigma = std([xs,ys,zs]);
  % scatter3(xs,ys,zs,[],rgb./255,'filled');
  scatter3(xs,ys,zs,'filled');
  foo = [centers(1)-sigma(1), centers(1)+sigma(1), centers(2)-sigma(2), centers(2)+sigma(2), centers(3)-sigma(3), centers(3)+sigma(3)];
  disp(foo);
  axis(foo);
  ax = gca;
  ax.DataAspectRatio = [1 1 1];
  line([0 gravity(1)], [0 gravity(2)], [0 gravity(3)], 'Color', 'red');
  % line([640 640+n(1)], [100 100+n(2)]);

  %% Refer calib_fisheye_zshade.txt
  fx = 562.89536;
  fy = 557.29656;
  px = 630.7712;
  py = 363.16152;
  omega = 1.03815;
  slant = 0;
  tan_omega_half_2 = 2 * tan(omega/2);
  K = [ fx slant px; 0 fy py; 0 0 1 ] * eye(3,4);  I = eye(4);

  [frameIds, Rs, Cs] = readPoses(ver);
  num_poses = size(frameIds,1);

  % for i=1:1
  frame = ver+frameIds(i);

  c = Cs(i,:);  C = zeros(4);     C(1:3,4) = c;
  R = reshape(Rs(i,:,:), [4,4]);  r = R(1:3,1:3);
  zaxis = r' * [0 0 1]';

  % pose = K * R * (I - C);

  n = K * R * gravity;
  n = n ./ n(3);      % project onto image

  img = imread(sprintf('TraderJoe/image/image%07d.jpg', frame));

  % undistort
  u = n(1); v = n(2);
  
  u_n = (u - px)/fx;
  v_n = (v - py)/fy;

  r_u = sqrt(u_n^2 + v_n^2);
  r_d = 1/omega * atan(r_u * tan_omega_half_2);

  u_dn = r_d/r_u * u_n;
  v_dn = r_d/r_u * v_n;

  u_d = fx*u_dn + px;
  v_d = fy*v_dn + py;

  n(1) = u_d;
  n(2) = v_d;

  % draw line and save
  % imwrite(img, sprintf('foo/image%07d.jpg', frame));
  % imshow(img);
  % line([640 640+n(1)], [100 100+n(2)]);
  if mod(i,50) == 0,  disp(sprintf('  Img: %d', i));   end
  % end

  disp('  Done');
end
