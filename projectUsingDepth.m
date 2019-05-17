function [Ip] = projectUsingDepth(ver, n1, n2)
  K = getIntrinsicParams(); K = K(1:3,1:3);
  K = 0.25 * K; % Images are scaled by a factor of 0.25
  K(3,3) = 1;

  [I1,R1,C1,~] = imgCamPose(ver, n1);
  I1 = double(imresize(I1, 0.25));
  [I2,R2,C2,~] = imgCamPose(ver, n2);
  % Plot these images
  subplot(2,2,1);
  imshow(uint8(I1));
  title(sprintf('GT: %d', n1));
  subplot(2,2,2);
  imshow(imresize(I2,0.25));
  title(sprintf('GT: %d', n2));

  % Read depth-disparity mapping and disparities
  dfile = sprintf('depth/depth%07d.txt', n1);
  dmapping = readtable(dfile);
  dmapping = table2array(dmapping(1,1:256));
  opts = detectImportOptions(dfile);
  opts.DataLine = 3;
  disparity = readtable(dfile, opts);
  disparity = table2array(disparity(:,1:320));
  depth = dmapping(disparity+1);    % disparity range is from 0-255, so add 1 for matlab indexing
  z = depth;

  %% Using meshgrid + interpolation
  % [h,w] = size(z);
  % [ux, uy] = meshgrid(1:w, 1:h);
  % P = K*R2*inv(R1)*inv(K);
  % C = C1 - C2;
  % 
  % vx = z .* ( P(1,1)*ux + P(1,2)*uy + P(1,3) ) + C(1);
  % vy = z .* ( P(2,1)*ux + P(2,2)*uy + P(2,3) ) + C(2);
  % vz = z .* ( P(3,1)*ux + P(3,2)*uy + P(3,3) ) + C(3);
  % vx = vx ./ vz;
  % vy = vy ./ vz;
  % vx(:) = vx(:) + linspace(0,1,numel(vx))'*1e-9;  % Unique grid vectors
  % vy(:) = vy(:) + linspace(0,1,numel(vx))'*1e-9;

  % for i=1:3
  %   Ip(:,:,i) = griddata(vx, vy, I1(:,:,i), ux, uy);
  % end
  % Ip = uint8(Ip);
  % Ip1 = Ip;
  % subplot(2,2,3);
  % imshow(Ip);
  % title(sprintf('Meshgrid: %d', n2));


  %% Pixel by pixel for verification
  Rinv = inv(R1); Kinv = inv(K);
  [h,w] = size(z);
  Ip = zeros(size(I1));
  for u=1:w
    for v=1:h
      X = Rinv*Kinv*z(v,u)*[u v 1]' + C1;
      x = K*R2*(X-C2);
      if x(3) <= 0, continue; end
      x = x(1:2) / x(3);
      x = round(x);
      if 1 <= x(1) && x(1) <= w
        if 1 <= x(2) && x(2) <= h
          Ip(x(2), x(1), :) = I1(v,u,:);
        end
      end
    end
  end
  Ip = uint8(Ip);
  Ip2 = Ip;
  subplot(2,2,4);
  imshow(Ip);
  title(sprintf('Pixbypix: %d', n2));
end
