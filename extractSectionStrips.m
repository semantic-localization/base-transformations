function extractSectionStrips(ver)
  K = getIntrinsicParams(); K = K(:,1:3);
  fig = gcf;

  [fs, Rs, Cs] = readPoses(ver);
  afile = sprintf('reconstruction%07d/vp_3dannotations.mat', ver);
  if exist(afile) == 2
    load(afile);
    sctn = squeeze(sections(2,:,:));
    x1 = sctn(:,1); x2 = sctn(:,2); x3 = sctn(:,3); x4 = sctn(:,4); x5 = sctn(:,5); x6 = sctn(:,6); x7 = sctn(:,7); x8 = sctn(:,8);
    x = unit(x2-x1);
    y = unit(x4-x1);
    z = unit(x1-x5);
    Rn = [ y -z -x ]';

    for i=1:size(fs,1)
      clf;
      axis([0 1280 0 720]);
      hold on;
      axis 'manual';
      set(fig,'PaperUnits','inches','PaperPosition',[0 0 16 9])

      % Tight fitting
      ax = gca;
      outerpos = ax.OuterPosition;
      % ti = ax.TightInset;
      left = outerpos(1);
      bottom = outerpos(2);
      ax_width = outerpos(3);
      ax_height = outerpos(4);
      ax.Position = [left bottom ax_width ax_height];

      % single img exp
      if fs(i) ~= 30, continue; end

      I = imread(sprintf('undistorted/image%07d.jpg', fs(i)+ver));
      R = reshape(Rs(i,1:3,1:3), [3,3]);
      C = reshape(Cs(i,:), [3,1]);
      P = K * R * [ eye(3) -C ];
      Pn = K * Rn * [ eye(3) -C ];
      H = K * Rn * R' * inv(K);
      In = ImageWarping(I, H);
      imshow(In);
      hold on;
      keyboard();
      In = double(In);

      lft = Pn * [ x2; 1 ];   lft = lft / lft(3);
      rgt = Pn * [ x3; 1 ];   rgt = rgt / rgt(3);
      lftbtm = Pn * [ x6; 1 ];  lftbtm = lftbtm / lftbtm(3);
      top = round(max(1,lft(2)));  btm = round(min(720,lftbtm(2)));
      % keyboard();
      % assert(rgt(3) - lft(3) < 1e-8);
      % scale = lft(3);
      % lft = lft/scale;  rgt = rgt/scale;
      ckpts = lft(1):100:rgt(1);    % only x-coord will vary on x2-x3 line
      lidx = min(find(ckpts >= 1));
      ridx = max(find(ckpts <= 1280));
      if isempty(lidx) || isempty(ridx)
        disp(fs(i));
        disp('nothing here: is this black img?');
        keyboard();
      end

      pts = [ ckpts(lidx:ridx); repmat(top, 1, ridx-lidx+1) ];
      pts_rgb = [];
      try
        pts_rgb(:,1) = interp2(In(:,:,1), pts(1,:), pts(2,:));
        pts_rgb(:,2) = interp2(In(:,:,2), pts(1,:), pts(2,:));
        pts_rgb(:,3) = interp2(In(:,:,3), pts(1,:), pts(2,:));
      catch
        keyboard();
      end
      % Have Nx3 matrix

      n = 0;
      for j=1:ridx-lidx
        lftpt = pts_rgb(j,:);
        rgtpt = pts_rgb(j+1,:);
        if norm(lftpt) == 0 && norm(rgtpt) == 0
          continue;
        else
          n = n+1;
          p1 = round(ckpts(lidx+j-1));  
          p2 = round(ckpts(lidx+j));
          % Istrip = In(top:btm, round(ckpts(lidx+j-1)):round(ckpts(lidx+j)), :);
          % Istrip = uint8(Istrip);
          % imshow(Istrip);
          % keyboard();
          line([p1 p2], [top top], 'Color', 'g', 'LineWidth', 5);
          line([p2 p2], [top btm], 'Color', 'g', 'LineWidth', 5);
          line([p1 p2], [btm btm], 'Color', 'g', 'LineWidth', 5);
          line([p1 p1], [top btm], 'Color', 'g', 'LineWidth', 5);
        end
      end
      % input(sprintf('%d-%d section strips, press Enter to cont', fs(i), n),'s');
      print(sprintf('annotated/sectioned/image%07d.jpg', fs(i)+ver), '-djpeg', '-r80');
      pause(0.5);
      keyboard();


      % lft = P * [ x2; 1 ];    lft = lft / lft(3);
      % rgt = P * [ x3; 1 ];    rgt = rgt / rgt(3);
      % ckpts = lft(kkkkkkkkkkk      
      
    end
  end
end
