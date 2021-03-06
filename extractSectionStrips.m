function extractSectionStrips(ver, sectionId, orientation, alpha)
  display = false;
  disp(sprintf('VERSION: %d', ver));
  [K,fx,fy,px,py] = getIntrinsicParams(); K = K(:,1:3);
  fig = gcf;

  [fs, Rs, Cs] = readPoses(ver);
  afile = sprintf('reconstruction%07d/vp_3dannotations.mat', ver);
  if exist(afile) == 2
    load(afile);
    sctn = squeeze(sections(sectionId,:,:));
    labelkey = getLabelKey(); 
    lbl = labelkey{labels(sectionId)};

    x1 = sctn(:,1); x2 = sctn(:,2); x3 = sctn(:,3); x4 = sctn(:,4); x5 = sctn(:,5); x6 = sctn(:,6); x7 = sctn(:,7); x8 = sctn(:,8);
    x = unit(x2-x1);
    y = unit(x4-x1);
    z = unit(x1-x5);

    if nargin < 4
      alpha = 1;
    else
      y = unit(alpha*y + (1-alpha)*x);
      x = unit(cross(y,z));
    end
    if strcmp(orientation, 'left')
      %% Left section-aware rectification
      %% x vector as cross product when not perfectly orthogonal
      % x = unit(cross(y,z));
      Rn = [ y -z -x ]';
      lft3d = [ x2; 1 ];  lftbtm3d = [ x6; 1 ];
      rgt3d = [ x3; 1 ];
    elseif strcmp(orientation, 'right')
      %% Right section-aware rectification
      %% x vector as cross product when not perfectly orthogonal
      % x = unit(cross(y,z));
      Rn = [ -y -z x ]';
      lft3d = [ x4; 1 ];  lftbtm3d = [ x8; 1 ];
      rgt3d = [ x1; 1 ];
    elseif strcmp(orientation, 'front')
      %% Front section-aware rectification
      Rn = [ x -z y ]';
      lft3d = [ x1; 1 ];  lftbtm3d = [ x5; 1 ];
      rgt3d = [ x2; 1 ];
    %% Subtle diff; notice lft3d & rgt3d
    elseif strcmp(orientation, 'far_right')
      %% eg: meat from far in StPaul
      Rn = [ x -z y ]';
      lft3d = [ x4; 1 ];  lftbtm3d = [ x8; 1 ];
      rgt3d = [ x1; 1 ];
    end

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
      % if mod(fs(i),5) ~= 0, continue; end
      % if fs(i) ~= 170, continue; end
      % if fs(i) >= 200, continue; end

      I = imread(sprintf('undistorted/image%07d.jpg', fs(i)+ver));
      R = reshape(Rs(i,1:3,1:3), [3,3]);
      C = reshape(Cs(i,:), [3,1]);
      P = K * R * [ eye(3) -C ];
      Pn = K * Rn * [ eye(3) -C ];
      H = K * Rn * R' * inv(K);
      In = ImageWarping(I, H);
      imshow(In);
      hold on;
      In = double(In);
      n = 0;  % counter for num_strips

      lft = Pn * lft3d;         lftInRotatedCoords = Rn * [ eye(3) -C ] * lft3d;
      rgt = Pn * rgt3d;
      if ~(lft(3) > 0 && rgt(3) > 0)
        if rgt(3) < 0
          disp('Right point behind camera');
        elseif lft(3) < 0
          disp('Left point behind camera');
        end
      else
        dz = lft(3);
        lft = lft / lft(3);
        rgt = rgt / rgt(3);
        lftbtm = Pn * lftbtm3d;  lftbtm = lftbtm / lftbtm(3);
        % keyboard();
        if lft(2) > 720
          if rgt(2) > 720
            continue;
          end
          top = rgt(2);
        else
          %% ONE TIME - SHOULD BE lft(2)
          top = lft(2);
        end
        top = round(max(1,top));  
        btm = round(min(720,lftbtm(2)));
        ckpts = lft(1):100:rgt(1);    % only x-coord will vary on x2-x3 line
        lidx = min(find(ckpts >= 1));
        ridx = max(find(ckpts <= 1280));
        % keyboard();
        if isempty(lidx) || isempty(ridx)
          disp('No strip completely in frame');
          % disp(sprintf('%d - nothing here: is this black img?', fs(i)));
          % keyboard();
        else
          pts_onefourth = [ ckpts(lidx:ridx); repmat((3*top+btm)/4, 1, ridx-lidx+1) ];
          pts_onehalf = [ ckpts(lidx:ridx); repmat((top+btm)/2, 1, ridx-lidx+1) ];
          pts_threefourth = [ ckpts(lidx:ridx); repmat((top+3*btm)/4, 1, ridx-lidx+1) ];
          pts = [ pts_onefourth; pts_onehalf; pts_threefourth ];
          pts = reshape(pts, 2, []);
          pts_rgb = [];
          try
            pts_rgb(:,1) = interp2(In(:,:,1), pts(1,:), pts(2,:));
            pts_rgb(:,2) = interp2(In(:,:,2), pts(1,:), pts(2,:));
            pts_rgb(:,3) = interp2(In(:,:,3), pts(1,:), pts(2,:));
          catch
            keyboard();
          end
          % Have Nx3 matrix
          % keyboard();

          for j=1:ridx-lidx
            % if j ~= 5, continue; end
            % lftpt = pts_rgb(j,:);
            % rgtpt = pts_rgb(j+1,:);
            % if norm(lftpt) == 0 && norm(rgtpt) == 0
            if (norm(pts_rgb(3*j-2:3*j,:)) == 0) || (norm(pts_rgb(3*j+1:3*j+3,:)) == 0)    % leave a strip with one side in total black
            % if norm(pts_rgb(3*j-2:3*j+3)) == 0
              continue;
            else
              n = n+1;
              p1 = round(ckpts(lidx+j-1));  
              p2 = round(ckpts(lidx+j));

              dpix1 = 100 * (lidx+j-2);   dx1 = dpix1 * dz/fx;
              dpix2 = 100 * (lidx+j-1);   dx2 = dpix2 * dz/fx;
              camFrameCoords1 = [ dx1 lftInRotatedCoords(2) lftInRotatedCoords(3) ];

              if display
                line([p1 p2], [top top], 'Color', 'g', 'LineWidth', 5);
                line([p2 p2], [top btm], 'Color', 'g', 'LineWidth', 5);
                line([p1 p2], [btm btm], 'Color', 'g', 'LineWidth', 5);
                line([p1 p1], [top btm], 'Color', 'g', 'LineWidth', 5);
                % keyboard();
              else
                Istrip = In(top:btm, p1:p2-1, :);
                Istrip = uint8(Istrip);
                % imshow(Istrip);
                % keyboard();

                %% Scale to make appear from canonical viewpoint - same distance as height of section
                dpv = btm-top;
                const = 1;
                mul = const * dpv/fy;
                scale = 1/mul;
                Ir = imresize(Istrip, scale);
                k = 1;
                w = size(Ir,2);
                while k+99 <= w
                  Ir_strip = Ir(:,k:k+99,:);
                  imwrite(Ir_strip, sprintf('sectioning_scaled/%s/image%07d_%s%d_%d_%d.jpg', lbl, ver+fs(i), orientation, sectionId, j, k));
                  k = k+100;
                end
                % boundary condition
                if k+50 <= w
                  Ir_strip = Ir(:,max(1,w-99):w,:);
                  imwrite(Ir_strip, sprintf('sectioning_scaled/%s/image%07d_%s%d_%d_%d.jpg', lbl, ver+fs(i), orientation, sectionId, j, w));
                end
              end
            end
          end
        end
      end
      disp(sprintf('%d-%d section strips', fs(i), n));
      if display
        print(sprintf('annotated/sectioned/image%07d_%s%d.jpg', fs(i)+ver, orientation, sectionId), '-djpeg', '-r80');
      end
      % pause(0.5);
      % keyboard();
    end
  end
end
