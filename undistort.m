% for ver=3000:200:18800
for ver=1200:200:1400
  disp(sprintf('Ver: %d', ver));

  [frameIds, Rs, Cs] = readPoses(ver);
  num_poses = size(frameIds,1);

  for i=1:num_poses
    frame = ver+frameIds(i);
    img = imread(sprintf('image/image%07d.jpg', frame));
    im_undistorted = Undistort(img);
    imwrite(im_undistorted, sprintf('undistorted/image%07d.jpg', frame));
  end

  disp('  Done');
end
