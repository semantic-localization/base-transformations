for ver=0:200:18800
  cylindrify(ver);
end

function [img,new_img] = cylindrify(ver)
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

    img = imread(sprintf('Traderjoe/StPaul/image/image%07d.jpg', frame));
    im_cylindrical = CylindricalProjection(img, R);
    imwrite(im_cylindrical, sprintf('Traderjoe/StPaul/rectification/cylindrical/image%07d.jpg', frame));

    % imshow(new_img);
    if mod(i,10) == 0,  disp(sprintf('  Img: %d', i));   end
  end


  disp('  Done');
end
