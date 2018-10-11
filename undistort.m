% for ver=3000:200:18800
for ver=1200:200:1400
  disp(sprintf('Ver: %d', ver));

  [frameIds, Rs, Cs] = readPoses(ver);
  num_poses = size(frameIds,1);

  for i=1:num_poses
    frame = ver+frameIds(i);
    R = reshape(Rs(i,1:3,1:3), [3,3]);  C = reshape(Cs(i,:), [3,1]);
    img = imread(sprintf('image/image%07d.jpg', frame));
    im_undistorted = Undistort(img, R, C);
    imwrite(im_undistorted, sprintf('undistorted/image%07d.jpg', frame));
  end

  disp('  Done');
end
