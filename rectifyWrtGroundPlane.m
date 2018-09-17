function rectifyWrtGroundPlane()
  for ver=0:200:18800
    %% Ver: 0
    % gravity = [-0.06943232,  0.99357245, -0.08940322]';
    %% Ver: 200
    % gravity = [-0.10855688  0.95380726 -0.28011983]';

    % get votes, labels from here
    disp(sprintf('Ver: %d', ver));

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
    if num_poses == 0
      continue;
    end

    % load gravity vector
    gfile = sprintf('reconstruction%07d/gravity.mat', ver);
    if exist(gfile, 'file') == 2
      load(gfile);
    end

    for i=1:num_poses
      frame = ver+frameIds(i);

      R = reshape(Rs(i,:,:), [4,4]);  R = R(1:3,1:3);
      Ry = reshape(gravity, 3, 1);
      Rz = R(3,:)';
      Rz = Rz - (Rz' * Ry) * Ry;  % Orthogonalize against gravity
      Rx = cross(Ry,Rz);
      Rg = [ Rx Ry Rz ]';
      H = K * Rg * R' * Kinv;

      img = imread(sprintf('image/image%07d.jpg', frame));
      im_warped = CylindricalProjection(img, H);

      % imwrite(img, sprintf('Traderjoe/StPaul/rectification/original/image%07d.jpg', frame));
      imwrite(im_warped, sprintf('rectification/cylindrical/image%07d.jpg', frame));
      % imshow(new_img);
      if mod(i,10) == 0,  disp(sprintf('  Img: %d', i));   end
    end
  end
end
