for ver=0:200:18800
  undistort(ver);
end

function [img,new_img] = undistort(ver)
  disp(sprintf('Ver: %d', ver));

  [frameIds, Rs, Cs] = readPoses(ver);
  num_poses = size(frameIds,1);

  for i=1:num_poses
    frame = ver+frameIds(i);
    R = reshape(Rs(i,1:3,1:3), [3,3]);  C = reshape(Cs(i,:), [3,1]);
    img = imread(sprintf('Traderjoe/StPaul/image/image%07d.jpg', frame));
    im_undistorted = Undistort(img, R, C);
    imwrite(im_undistorted, sprintf('Traderjoe/StPaul/undistorted/image%07d.jpg', frame));
  end

  disp('  Done');
end
