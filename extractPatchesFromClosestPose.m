ver = 800;
disp(sprintf('Ver: %d', ver));
dir_name = sprintf('reconstruction%07d/point_patches', ver);
ensureDir(dir_name);

[num_pt, pts, ~] = readPointCloud(ver);
[frameIds, Rs, Cs] = readPoses(ver);
K = getIntrinsicParams();

num_pts = size(pts,1);
num_poses = size(frameIds, 1);
I = eye(4);
for j=1:num_pts
  pt = pts(j,:);
  min_dist = inf;      % large number to compare against in min checks
  for i=1:num_poses
    R = reshape(Rs(i,:,:), [4,4]);  c = Cs(i,:);
    vec = pt(1:3) - c;
    if norm(vec) < min_dist                   % IF camera is closer to point
      if vec * (R(1:3,1:3)' * [0 0 1]') > 0   % IF point lies in front of cam
        C = zeros(4); C(1:3,4) = c;
        pose = K * R * (I - C);
        proj = pose * pt';

        x = proj(1) / proj(3);
        y = proj(2) / proj(3);

        [x y] = undistort(x,y);

        if 0 < y & y <= 720 & 0 < x & x <= 1280   % IF point falls in frame
          min_dist = norm(vec);
          min_frame = frameIds(i);
          min_proj = [x y];
        end
      end
    end
  end
  % extract patch around point and save
  img = imread(sprintf('image/image%07d.jpg', ver+min_frame));
  x = min_proj(1);  y = min_proj(2);
  x = round(x); y = round(y);
  xs = x-50;  xe = x+49;
  if xs < 1
    xs = 1; xe = xs+100;
  elseif xe > 1280
    xe = 1280; xs = xe-100;
  end
  ys = y-50;  ye = y+49;
  if ys < 1
    ys = 1; ye = ys+100;
  elseif ye > 720
    ye = 720; ys = ye-100;
  end
  imwrite(img(ys:ye,xs:xe,:), sprintf('%s/%05d.jpg', dir_name, j));
  if mod(j,1000) == 0, disp(sprintf(' %d done', j)); end
end
