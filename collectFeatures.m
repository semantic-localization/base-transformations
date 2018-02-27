[labels, ~, ~] = readLabels('traderjoe');

s = 0;  e = 800;
for ver=s:200:e
  collectFeatures_(ver, labels);
end

function collectFeatures_(ver, labels)
  % get votes, labels from here
  disp(sprintf('Ver: %d', ver));

  [num_pt, pts, ~] = readPointCloud(ver);
  if num_pt == 0 
    disp('  No points');
    return; 
  end

  disp('  Cloud read');
  load(sprintf('reconstruction%07d/labeled_cloud.mat', ver));
  disp('  Sections in cloud:');
  num_labels = size(labels,2);
  for i=1:num_labels
    s = sum(votes==i);
    if s > 0, disp(sprintf('    %s - %d%% votes', labels{i}, round(100*s/size(votes,1)))); end
  end
  features = zeros(num_labels,1);

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
  % frameIds = zeros(num_poses, 1); % poses = zeros(num_poses, 3, 4);

  for i=1:num_poses
    frame = textscan(cfid, '%d %d', 1);
    frame = frame{2}+1;
    % frameIds(i) = frame;
    frame = ver+frame;

    C = zeros(4);   c = cell2mat(textscan(cfid, '%f %f %f', 1))';   C(1:3,4) = c;
    R = eye(4);     r = cell2mat(textscan(cfid, '%f %f %f', 3));    R(1:3,1:3) = r;
    zaxis = r' * [0 0 1]';
    zs = (pts(:,1:3) - repmat(c',num_pt,1)) * zaxis;
    idx = zs > 0;
    pts_to_project = pts(idx, :);
    votes_zs = votes(idx);

    pose = K * R * (I - C);
    % poses(i,:,:) = pose;

    img = imread(sprintf('image/image%07d.jpg', frame));

    projections = (pose * pts_to_project')';
    projections = projections ./ projections(:,3);
    xs = projections(:,1);  ys = projections(:,2);
    n = size(xs);
    for j=1:n
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

    height = 720; width = 1280;
    num_features_in_img = nnz(0 < xs & xs <= width & 0 < ys & ys <= 720);
    feature_threshold = 0.05 * num_features_in_img;   % 5 percent
    % disp(num_features_in_img);
    % disp(feature_threshold);
    step = 100;
    for h=1:step:720
      for w=1:step:1280
        eh = min(h+step-1,720); ew = min(w+step-1,1280);
        sample_pts = w <= xs & xs <= ew & h <= ys & ys <= eh;
        if nnz(sample_pts) >= feature_threshold
          % disp(nnz(sample_pts));
          label = mode(votes_zs(sample_pts));
          img_ = img(h:eh, w:ew, :);
          img_name = sprintf('image_%d_%d_%d', ver+i, w, h);
          dir_name = sprintf('features/%s', labels{label});
          features(label) = features(label) + 1;
          ensureDir(dir_name);
          imwrite(img_, sprintf('%s/%s.jpg', dir_name, img_name));
        end
      end
    end

   if mod(i,50) == 0,  disp(sprintf('  Img: %d', i));   end

%    projections(:,3) = projections(:,3) * 3;
%    colors = 255 * label_colors(votes(idx), :);
%    img = insertShape(img, 'FilledCircle', projections, 'Color', colors);
%
%    frame_label = frame_labels(idivide(frame,int32(25))+1, :);
%    frame_label = labels(frame_label');
%    img = insertObjectAnnotation(img, 'rectangle', [320, 500, 0, 0; 960, 500, 0, 0], frame_label, 'Color', 'Green', 'FontSize', 14);
%    imwrite(img, sprintf('projected/image%07d.jpg', frame));
    % imshow(img);

%     Y = 0 < ys & ys <= 720;
%     left = find(0 < xs & xs <= 640 & Y);
%     right = find(640 < xs & xs <= 1280 & Y);
% 
%     frame = idivide(frame,int32(25))+1;
%     frame_label = frame_labels(frame, :);
%     llabel = frame_label(1); rlabel = frame_label(2);
%     for pt = left,  votes(pt,llabel) = votes(pt,llabel) + 1; end
%     for pt = right, votes(pt,rlabel) = votes(pt,rlabel) + 1; end
  end

  disp('  Features collected:');
  for i=1:num_labels
    if features(i) > 0, disp(sprintf('    %s - %d%', labels{i}, features(i))); end
  end

  disp('  Done');
  fclose(cfid);
end
