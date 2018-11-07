function propagate3dLabels(start_ver, end_ver)
  K = getIntrinsicParams(); K = K(:,1:3);
  fig = gcf;
  colors = [ 'r' 'g' 'b' 'k' ];
  % for ver=0:200:4200
  for ver=start_ver:200:end_ver
    [fs, Rs, Cs] = readPoses(ver);
    afile = sprintf('reconstruction%07d/vp_3dannotations.mat', ver);
    if exist(afile) == 2
      load(afile);

      % idx = [];
      for j=1:size(fs,1)
        if mod(fs(j),5) ~= 0,
          continue;
        end
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
        
        imgname = sprintf('image%07d.jpg', ver+fs(j));
        orig_imgpath = sprintf('undistorted/%s', imgname);
        annotated_imgpath = sprintf('annotated/%s', imgname);
        I = imread(orig_imgpath);
        imshow(I);

        R = reshape(Rs(j,1:3,1:3), [3,3]);  C = reshape(Cs(j,:), [3,1]);
        P = K * R * [ eye(3) -C ];
        
        for i=1:numel(labels)
          lbl = labels(i);
          sctn = squeeze(sections(i,:,:));
          x1 = sctn(:,1); x2 = sctn(:,2); x3 = sctn(:,3); x4 = sctn(:,4); x5 = sctn(:,5); x6 = sctn(:,6); x7 = sctn(:,7); x8 = sctn(:,8);

          %% TEMP
          %x = unit(x2-x1);
          %y = unit(x4-x1);
          %z = unit(x1-x5);
          %Rn = [ y -z -x ]';
          %H = K * Rn * R' * inv(K);
          %I = ImageWarping(I, H);
          %imshow(I);
          %P = K * Rn * [ eye(3) -C ];

          b = (x4(2) - x1(2))/(x4(1) - x1(1));
          c = (x4(3) - x1(3))/(x4(1) - x1(1));
          p1 = [ 1 b c ]' * linspace(0, x4(1) - x1(1)) + x1;
          b = (x3(2) - x2(2))/(x3(1) - x2(1));
          c = (x3(3) - x2(3))/(x3(1) - x2(1));
          p2 = [ 1 b c ]' * linspace(0, x3(1) - x2(1)) + x2;
          b = (x8(2) - x5(2))/(x8(1) - x5(1));
          c = (x8(3) - x5(3))/(x8(1) - x5(1));
          p5 = [ 1 b c ]' * linspace(0, x8(1) - x5(1)) + x5;
          b = (x7(2) - x6(2))/(x7(1) - x6(1));
          c = (x7(3) - x6(3))/(x7(1) - x6(1));
          p6 = [ 1 b c ]' * linspace(0, x7(1) - x6(1)) + x6;

          % ax = gca;
          % outerpos = ax.OuterPosition;
          % % ti = ax.TightInset;
          % % left = outerpos(1);
          % % bottom = outerpos(2);
          % % ax_width = outerpos(3);
          % % ax_height = outerpos(4);
          % % ax.Position = [left bottom ax_width ax_height];
          % ax.Position = [0 0 1280 720];
          % fig.PaperPositionMode = 'auto';
          % fig_pos = fig.PaperPosition;
          % % fig.PaperSize = [fig_pos(3) fig_pos(4)];
          % fig.PaperSize = [1280 720];
          % % set(fig, 'visible', 'off');

          % for i=1:size(fs,1)

          z = P * [ p1; ones(1,100) ];   i1 = min(find(z(3,:) > 0));    x11 = p1(:,i1);
          z = P * [ p2; ones(1,100) ];   i2 = min(find(z(3,:) > 0));    x22 = p2(:,i2);
          z = P * [ p5; ones(1,100) ];   i5 = min(find(z(3,:) > 0));    x55 = p5(:,i5);
          z = P * [ p6; ones(1,100) ];   i6 = min(find(z(3,:) > 0));    x66 = p6(:,i6);
          % if i == 2,  idx = [ idx; [i1 i2 i5 i6] ];   end   % check progression
          z = P(3,:) * [ x3; 1 ];   if z > 0, x33 = x3;   else  x33 = zeros(1,0); end
          z = P(3,:) * [ x4; 1 ];   if z > 0, x44 = x4;   else  x44 = zeros(1,0); end
          z = P(3,:) * [ x7; 1 ];   if z > 0, x77 = x7;   else  x77 = zeros(1,0); end
          z = P(3,:) * [ x8; 1 ];   if z > 0, x88 = x8;   else  x88 = zeros(1,0); end

          try
            drawLinesHelper(P, x11, x22, x33, x44, x55, x66, x77, x88, colors(i));
            % drawLinesHelper(P, x1, x2, x3, x4, x5, x6, x7, x8);
          catch
            keyboard();
          end
        end
        print(annotated_imgpath, '-djpeg', '-r80');
      end
      % [~,I] = sort(fs);
      % disp(idx(I,:));
    end
  end
end

function drawLinesHelper(P, x1, x2, x3, x4, x5, x6, x7, x8, color)
  if ~isempty(x1) && ~isempty(x2),  p = [x1 x2];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); l1 = line(z1(1,:), z1(2,:), 'Color', color);   end
  if ~isempty(x2) && ~isempty(x3),  p = [x2 x3];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); l2 = line(z1(1,:), z1(2,:), 'Color', color);   end
  if ~isempty(x3) && ~isempty(x4),  p = [x3 x4];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); l3 = line(z1(1,:), z1(2,:), 'Color', color);   end
  if ~isempty(x4) && ~isempty(x1),  p = [x4 x1];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); l4 = line(z1(1,:), z1(2,:), 'Color', color);   end
  if ~isempty(x5) && ~isempty(x6),  p = [x5 x6];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); l5 = line(z1(1,:), z1(2,:), 'Color', color);   end
  if ~isempty(x6) && ~isempty(x7),  p = [x6 x7];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); l6 = line(z1(1,:), z1(2,:), 'Color', color);   end
  if ~isempty(x7) && ~isempty(x8),  p = [x7 x8];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); l7 = line(z1(1,:), z1(2,:), 'Color', color);   end
  if ~isempty(x8) && ~isempty(x5),  p = [x8 x5];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); l8 = line(z1(1,:), z1(2,:), 'Color', color);   end
  if ~isempty(x1) && ~isempty(x5),  p = [x1 x5];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); l9 = line(z1(1,:), z1(2,:), 'Color', color);   end
  if ~isempty(x2) && ~isempty(x6),  p = [x2 x6];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); l10 = line(z1(1,:), z1(2,:), 'Color', color);   end
  if ~isempty(x3) && ~isempty(x7),  p = [x3 x7];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); l11 = line(z1(1,:), z1(2,:), 'Color', color);   end
  if ~isempty(x4) && ~isempty(x8),  p = [x4 x8];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); l12 = line(z1(1,:), z1(2,:), 'Color', color);   end
end
