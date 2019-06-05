function projectUsingDepthAirsim(ver)
  %{
    SYNTHESIZING IMAGES @ NOVEL LOCS

    load(sprintf('reconstruction%07d/vp_3dannotations.mat', ver));
    sctn = squeeze(sections(1,:,:));
    g = unit(sctn(:,5) - sctn(:,1));
    grid_scale = 0.1;
  %}
  
  deg_thetas = [-20, -10, 10 20];
  K = [ 128 0 128; 0 128 72; 0 0 1 ];

  data_dir = '/home/jayant/monkey/grocery_data/Supermarket/data/simulated_capture';

  for n1=1:200
    load(sprintf('%s/pose%07d.mat', data_dir, n1));
    rx = R(2,:)';
    ry = -R(3,:)';
    rz = -R(1,:)';
    C1 = C';
    R1 = [ rx ry rz ]';

    I1 = imread(sprintf('%s/image%07d.png', data_dir, n1));
    load(sprintf('%s/depth%07d.mat', data_dir, n1));
    z = depth;

    %%% Point cloud viz
    % Rinv = inv(R1); Kinv = inv(K);
    % [h,w] = size(z);
    % pts = zeros(h,w,6);
    % for u=1:w
    %   for v=1:h
    %     X = Rinv*Kinv*z(v,u)*[u v 1]' + C1;
    %     pts(v,u,1:3) = X;
    %     pts(v,u,4:6) = I1(v,u,:);
    %   end
    % end
    % xs = reshape(pts(:,:,1), [], 1);
    % ys = reshape(pts(:,:,2), [], 1);
    % zs = reshape(pts(:,:,3), [], 1);
    % cls = reshape(pts(:,:,4:6), [], 3) / 255;
    % figure; hold on; scatter3(xs, ys, zs, 5, cls, 'filled'); axis equal;
    % keyboard();


    %{
      SYNTHESIZING IMAGES @ NOVEL LOCS
      (also uncomment vp_3dannotations load above)

    xj = unit(R1(1,:))';
    xj = xj - (xj'*g)*g; xj = unit(xj);
    zj = unit(cross(xj,g));
    Rgrid = [ xj g zj ]';
    xInc = grid_scale*xj; zInc = grid_scale*zj;

    for k=1:50
      C2 = C1 + 0.5*k*xInc + 1*k*zInc;
      R2 = Rgrid;
    %}

    if mod(n1,10) == 0, disp(n1); end
    for n2=n1+1:min(n1+90,200)
      load(sprintf('%s/pose%07d.mat', data_dir, n2));
      rx = R(2,:);
      ry = -R(3,:);
      rz = -R(1,:);
      C2 = C';
      R2 = [ rx; ry; rz; ];
      [Ip, emptiness] = projectUsingDepthHelper(K, R1, C1, I1, z, R2, C2);
      if emptiness >= 0.2
        imwrite(Ip, sprintf('%s/depth_%03d_%03d.jpg', data_dir, n1, n2));
      end

      for th=deg_thetas
        theta = deg2rad(th);
        R2 = [ rx*cos(theta) + ry*sin(theta); 
              -rx*sin(theta) + ry*cos(theta); 
               rz ];
        [Ip, emptiness] = projectUsingDepthHelper(K, R1, C1, I1, z, R2, C2);
        if emptiness >= 0.2
          imwrite(Ip, sprintf('%s/depth_%03d_%03d_rotz%d.jpg', data_dir, n1, n2, th));
        end

        R2 = [ -rz*sin(theta) + rx*cos(theta); 
                ry; 
                rz*cos(theta) + rx*sin(theta) ];
        [Ip, emptiness] = projectUsingDepthHelper(K, R1, C1, I1, z, R2, C2);
        if emptiness >= 0.2
          imwrite(Ip, sprintf('%s/depth_%03d_%03d_roty%d.jpg', data_dir, n1, n2, th));
        end

        R2 = [ rx;
               ry*cos(theta) + rz*sin(theta);
              -ry*sin(theta) + rz*cos(theta) ]; 
        [Ip, emptiness] = projectUsingDepthHelper(K, R1, C1, I1, z, R2, C2);
        if emptiness >= 0.2
          imwrite(Ip, sprintf('%s/depth_%03d_%03d_rotx%d.jpg', data_dir, n1, n2, th));
        end
      end
    end
  end
end


function [Ip, emptiness] = projectUsingDepthHelper(K, R1, C1, I1, z, R2, C2)
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
  pooled = max(Ip, [], 3);
  emptiness = sum(pooled(:) > 0) / (h*w);
end


function [Ip] = projectUsingDepthInterp(ver, n1, n2)
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
