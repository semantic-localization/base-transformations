function vizPointCloudAirsim()
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

  figure; hold on; axis equal;
  lim = 50;
  % xlim([-lim, lim]);
  % ylim([-lim, lim]);
  % zlim([-lim, lim]);
  Xs = [];
  Ys = [];
  Zs = [];
  Cls = [];
  % Build point cloud from a small number of frames
  for n1=50:50:190
    load(sprintf('%s/pose%07d.mat', data_dir, n1));
    rx = R(2,:)';
    ry = -R(3,:)';
    rz = -R(1,:)';
    C1 = C';
    R1 = [ rx ry rz ]';

    I1 = imread(sprintf('%s/image%07d.png', data_dir, n1));
    load(sprintf('%s/depth%07d.mat', data_dir, n1));
    z = depth;
    max_depth = 100;
    z(z > max_depth) = max_depth;

    %%% Point cloud viz
    Rinv = inv(R1); Kinv = inv(K);
    [h,w] = size(z);
    pts = zeros(h,w,6);
    for u=1:w
      for v=1:h
        X = Rinv*Kinv*z(v,u)*[u v 1]' + C1;
        pts(v,u,1:3) = X;
        pts(v,u,4:6) = I1(v,u,:);
      end
    end
    xs = reshape(pts(:,:,1), [], 1);                Xs = [ Xs; xs ];
    ys = reshape(pts(:,:,2), [], 1);                Ys = [ Ys; ys ];
    zs = reshape(pts(:,:,3), [], 1);                Zs = [ Zs; zs ];
    cls = reshape(pts(:,:,4:6), [], 3) / 255;       Cls = [ Cls; cls ];


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
  end

  scatter3(Xs, Ys, Zs, 5, Cls, 'filled');
  xlabel('X');
  ylabel('Y');
  zlabel('Z');
  keyboard();

  Cls = Cls * 255;
  pts = [ Xs Ys Zs ]';
  N = numel(Xs);
  for n1=1:200
    if mod(n1,10) == 0, disp(n1); end
    load(sprintf('%s/pose%07d.mat', data_dir, n1));
    rx = R(2,:)';
    ry = -R(3,:)';
    rz = -R(1,:)';
    R = [ rx ry rz ]';
    C = C';

    pix = K * R * (pts - C);
    pix(1:2,:) = round(pix(1:2,:) ./ pix(3,:));
    Ip = zeros(h,w,3);
    for i=1:N
      u = pix(1,i);
      v = pix(2,i);
      if 1 <= u && u <= w
        if 1 <= v && v <= h
          if pix(3,i) > 0
            Ip(v,u,:) = Cls(i,:);
          end
        end
      end
    end
    Ip = uint8(Ip);
    imwrite(Ip, sprintf('%s/ptcloud_%03d.jpg', data_dir, n1));
    imwrite(Ip, sprintf('%s/view/ptcloud_%03d.jpg', data_dir, n1));

    pooled = max(Ip, [], 3);
    emptiness = sum(pooled(:) > 0) / (h*w);
    fprintf('%d: %0.2f\n', n1, emptiness);
  end
end
