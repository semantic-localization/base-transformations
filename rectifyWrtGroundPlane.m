function [img,new_img] = rectifyWrtGroundPlane(ver)
  %% Ver: 0
  gravity = [-0.06943232,  0.99357245, -0.08940322]';
  %% Ver: 200
  % gravity = [-0.10855688  0.95380726 -0.28011983]';

  % get votes, labels from here
  disp(sprintf('Ver: %d', ver));

  %% Point Cloud reading - not required right now
  % [num_pt, pts, ~, rgb] = readPointCloud(ver);
  % xs = pts(:,1);
  % ys = pts(:,2);
  % zs = pts(:,3);
  % xs_inliers = (xs > prctile(xs,5)) & (xs < prctile(xs,95));
  % ys_inliers = (ys > prctile(ys,5)) & (ys < prctile(ys,95));
  % zs_inliers = (zs > prctile(zs,5)) & (zs < prctile(zs,95));
  % pts = pts(xs_inliers & ys_inliers & zs_inliers, :);

  % centers = median([xs,ys,zs]);
  % sigma = std([xs,ys,zs]);
  % % scatter3(xs,ys,zs,[],rgb./255,'filled');
  % scatter3(xs,ys,zs,'filled');
  % foo = [centers(1)-sigma(1), centers(1)+sigma(1), centers(2)-sigma(2), centers(2)+sigma(2), centers(3)-sigma(3), centers(3)+sigma(3)];
  % disp(foo);
  % axis(foo);
  % ax = gca;
  % ax.DataAspectRatio = [1 1 1];
  % line([0 gravity(1)], [0 gravity(2)], [0 gravity(3)], 'Color', 'red');
  % line([640 640+n(1)], [100 100+n(2)]);

  %% Refer calib_fisheye_zshade.txt
  fx = 562.89536;
  fy = 557.29656;
  px = 630.7712;
  py = 363.16152;
  omega = 1.03815;
  slant = 0;
  tan_omega_half_2 = 2 * tan(omega/2);
  % K = [ fx slant px; 0 fy py; 0 0 1 ] * eye(3,4);  I = eye(4);
  K = [ fx slant px; 0 fy py; 0 0 1 ];
  Kinv = inv(K);

  [frameIds, Rs, Cs] = readPoses(ver);
  num_poses = size(frameIds,1);

  for i=1:num_poses
    frame = ver+frameIds(i);

    R = reshape(Rs(i,:,:), [4,4]);  R = R(1:3,1:3);
    %% Only K and R needed for Homography
    % c = Cs(i,:);  C = zeros(4);     C(1:3,4) = c;

    % pose = K * R * (I - C);

    Ry = gravity;
    Rz = R(3,:)';
    Rz = Rz - (Rz' * Ry) * Ry;  % Orthogonalize against gravity
    Rx = cross(Ry,Rz);
    Rg = [ Rx Ry Rz ]';
    H = K * Rg * R' * Kinv;

    img = imread(sprintf('Traderjoe/StPaul/image/image%07d.jpg', frame));
    im_warped = ImageWarping(img, H);

    % new_img = zeros(720,1280,3,'like',img);
    % for j=1:720
    %   for k=1:1280
    %     % u = k;  v = j;
    %     % rgb = img(j,k,:);
    %     % pix = K * Rg * R' * Kinv * [ u v 1 ]';
    %     % pix = pix ./ pix(3);
    %     % u = pix(1);   v = pix(2);

    %     % % undistort
    %     % % u_n = (u - px)/fx;
    %     % % v_n = (v - py)/fy;

    %     % % r_u = sqrt(u_n^2 + v_n^2);
    %     % % r_d = 1/omega * atan(r_u * tan_omega_half_2);

    %     % % u_dn = r_d/r_u * u_n;
    %     % % v_dn = r_d/r_u * v_n;

    %     % % u_d = fx*u_dn + px;
    %     % % v_d = fy*v_dn + py;

    %     % % u_d = int32(u_d);
    %     % % v_d = int32(v_d);

    %     % u_d = int32(u);
    %     % v_d = int32(v);
    %     % if u_d >= 1 & u_d <= 1280 & v_d >= 1 & v_d <= 720
    %     %   new_img(v_d, u_d, :) = rgb;
    %     % end
    %   end
    % end
    % imwrite(img, sprintf('Traderjoe/StPaul/rectification/original/image%07d.jpg', frame));
    imwrite(im_warped, sprintf('Traderjoe/StPaul/rectification/final/image%07dRectified.jpg', frame));
    % imshow(new_img);
    if mod(i,10) == 0,  disp(sprintf('  Img: %d', i));   end
  end


  disp('  Done');
end
