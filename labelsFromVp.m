function labelsFromVp(image_nums, ver, K)
  imdir = 'undistorted/';
  vpdir = 'vp/';

  % Get image and pose for first couple of images
  i1 = image_nums(1); 
  i2 = image_nums(2);
  [I1,R1,C1,P1] = imgCamPose(ver, i1-ver);
  [I2,R2,C2,P2] = imgCamPose(ver, i2-ver);

  % Uses VP algorithm to display vanishing lines and choose 2 principal orthogonal directions - x & y axes
  vpfile = sprintf('%simage%07d_vp.mat', vpdir, i1);
  if exist(vpfile, 'file') ~= 2
    getVP(imdir, sprintf('image%07d.jpg', i1), 0, vpdir);
  end
  % f = openfig(sprintf('%simage%07d.fig', vpdir, i1));
  vp = displayVP(I1, vpfile);
  i = input('Right VP - R/G/B (enter 1/2/3): ');  
  rvp = vp(2*i-1:2*i);  x = unit(R1' * inv(K) * [ rvp 1 ]');
  i = input('Left VP - R/G/B (enter 1/2/3): ');  
  lvp = vp(2*i-1:2*i);  y = unit(R1' * inv(K) * [ lvp 1 ]');
  z = unit(cross(x,y)); % also z-axis
  close all;

  fig1 = figure;
  imshow(I1);
  fig2 = figure;
  imshow(I2);

  %% Point from where to start drawing box - obtained by triangulating
  %% Since only one click required, not saving file
  % cfile = sprintf('reconstruction%07d/vp_clicks_%d_%d.mat', ver, i2, i2);
  % if exist(cfile, 'file') == 2
  %   load(cfile);
  % else
  figure(fig1);
  [x1, y1] = ginput(1);
  u1 = [ x1'; y1'; ones(1,1) ];

  figure(fig2);
  [x2, y2] = ginput(1);
  u2 = [ x2'; y2'; ones(1,1) ];

  u1x = Vec2Skew(u1);
  u2x = Vec2Skew(u2);
  A = [ u1x * P1(:,1:3); u2x * P2(:,1:3) ];
  b = [ -u1x * P1(:,4); -u2x * P2(:,4) ];
  us = [ u1 u2 ];
  Ps(1,:,:) = P1; Ps(2,:,:) = P2;
  handles = [];
  % for i=3:numel(image_nums)
  %   [I,~,~,P] = imgCamPose(ver, image_nums(i) - ver);
  %   Ps(i,:,:) = P;
  %   handle = figure;
  %   handles = [ handles handle ];
  %   imshow(I);
  %   [x y] = ginput(1);
  %   u = [ x'; y'; ones(1,1) ];
  %   us = [ us u ];
  %   ux = Vec2Skew(u);
  %   A = [ A; ux * P(:,1:3) ];
  %   b = [ b; -ux * P(:,4) ];
  % end

  %   save(cfile, 'u1', 'u2');
  % end

  pt = A \ b;
  for i=1:numel(image_nums)
    P = squeeze(Ps(i,:,:));
    w = P * [pt; 1];  w = w / w(3);   fprintf('Reprojection error on image %d: %f\n', i, norm(w-us(:,i)));
  end
  close(handles);

  % point from where to start drawing box
  % p = (rvp+lvp)/2;
  % pt = R1' * inv(K) * [ p 1 ]' + C1;

  labelkey = getLabelKey();
  annotationsFile = sprintf('reconstruction%07d/vp_3dannotations.mat', ver);
  if exist(annotationsFile, 'file') == 2
    load(annotationsFile);
  else
    labels = [];  sections = [];
  end

  mul = 15;
  x1 = pt;  x2 = x1 + mul*x;  x3 = x2 + mul*y;  x4 = x1 + mul*y;
  x5 = x1 - mul*z;  x6 = x2 - mul*z;  x7 = x3 - mul*z;  x8 = x4 - mul*z;
  figure(fig1);
  drawLinesHelper(P1, x1, x2, x3, x4, x5, x6, x7, x8);
  mul = round(mul * input('Elongate axes by factor of: '));
  % ADJUSTMENT
  adjust = get_boolean_input('Adjust major axes?');  
  if adjust
    wtd_avg = get_boolean_input('Weighted avg?');  
    if wtd_avg
      alpha = input('alpha for weighted avg - ');  
    else
      alpha = 0.5;
    end
    disp(alpha);
    % search for new y-axis along existing y -> x
    low = y;
    high = x;
    while true
      mid = unit(alpha*low + (1-alpha)*high);
      ny = mid;
      nx = unit(cross(ny,z));

      x1 = pt;  x2 = x1 + mul*nx;  x3 = x2 + mul*ny;  x4 = x1 + mul*ny;
      x5 = x1 - mul*z;  x6 = x2 - mul*z;  x7 = x3 - mul*z;  x8 = x4 - mul*z;
      drawLinesHelper(P1, x1, x2, x3, x4, x5, x6, x7, x8);

      good = get_boolean_input('Looks good?');  
      if good
        x = nx;
        y = ny;
        break;
      else
        more = get_boolean_input('Shift more?');  
        if more
          low = mid;
        else
          high = mid;
        end
      end
    end
  end

  % Visualize 3d space, cam trajectory
  vis = figure();
  [fs,~,Cs] = readPoses(ver);
  inc = linspace(0,1,size(fs,1));
  cls = [ ones(size(fs))-inc' zeros(size(fs))+inc' zeros(230,1) ];
  linecls = [ 'r', 'g', 'b', 'k' ];
  [num_pt, pts, ~] = readPointCloud(ver);
  [~,I] = sort(fs);
  sCs = Cs(I,:);
  % Cam trajectory
  scatter3(sCs(:,1), sCs(:,2), sCs(:,3), 20, cls, '+');
  hold on;
  axis equal;
  axis normal;
  xlims = xlim();   xlim([min([prctile(pts(:,1), 5) xlims(1)]), max([prctile(pts(:,1), 95) xlims(2)])]);
  ylims = ylim();   ylim([min([prctile(pts(:,2), 5) ylims(1)]), max([prctile(pts(:,2), 95) ylims(2)])]);
  zlims = zlim();   zlim([min([prctile(pts(:,3), 5) zlims(1)]), max([prctile(pts(:,3), 95) zlims(2)])]);
  % Point cloud
  scatter3(pts(:,1), pts(:,2), pts(:,3), 2, 'k');

  % LABEL SECTIONS
  while true
    figure(fig1);
    x1 = pt;  x2 = x1 + x;  x3 = x2 + y;  x4 = x1 + y;
    x5 = x1 - z;  x6 = x2 - z;  x7 = x3 - z;  x8 = x4 - z;

    figure(fig1);
    drawLinesHelper(P1, x1, x2, x3, x4, x5, x6, x7, x8);
    % wireframe modif
    while true
      figure(fig1);
      waitforbuttonpress;
      k = get(gcf, 'CurrentCharacter');
      if k == 'z', break;  end
      [x1,x2,x3,x4,x5,x6,x7,x8] = modifyWireframe(k,x1,x2,x3,x4,x5,x6,x7,x8,x,y,z);
      if k == 'q'
        figure(fig2);
        drawLinesHelper(P2, x1, x2, x3, x4, x5, x6, x7, x8);
        figure(fig1);
      else
        drawLinesHelper(P1, x1, x2, x3, x4, x5, x6, x7, x8);
      end
    end

    % Correction orientation, so that x1, x2, x3, x4 form the top plane of the cuboid going INTO the image
    section = [ x1 x2 x3 x4 x5 x6 x7 x8 ];
    illustrateOrientation(P1, x1, x2, x3, x4, x5, x6, x7, x8);
    while true
      try
        idx = input('Enter indexing to correct orientation: ');
        sctn = section(:,idx);
        assert( (norm(size(sctn) - size(section)) == 0) && (norm(sctn) - norm(section) < 1e-8) );
      catch
        disp('Incorrect format');
        keyboard();
        continue;
      end
      illustrateOrientation(P1, sctn(:,1), sctn(:,2), sctn(:,3), sctn(:,4), sctn(:,5), sctn(:,6), sctn(:,7), sctn(:,8));
      ok = get_boolean_input('OK?');
      if ok
        section = sctn;
        break;
      end
    end

    % 3d visualization
    figure(vis);
    xlims = xlim();   xlim([min([section(1,:) xlims(1)]), max([section(1,:) xlims(2)])]);
    ylims = ylim();   ylim([min([section(2,:) ylims(1)]), max([section(2,:) ylims(2)])]);
    zlims = zlim();   zlim([min([section(3,:) zlims(1)]), max([section(3,:) zlims(2)])]);
    for i=1:4,  plot3(section(1,[i,1+mod(i,4)]), section(2,[i,1+mod(i,4)]), section(3,[i,1+mod(i,4)]), linecls(i)); end
    for i=5:8,  plot3(section(1,[i,5+mod(i,4)]), section(2,[i,5+mod(i,4)]), section(3,[i,5+mod(i,4)]), linecls(i-4)); end
    for i=1:4,  plot3(section(1,[i,i+4]), section(2,[i,i+4]), section(3,[i,i+4]), linecls(i)); end
    input('Ctrl-C and restart if scaled badly.','s');

    % label until user gets it right
    while true
      user_label = input('Enter label: ', 's');
      label = find(strcmp(labelkey, user_label));
      if label
        labels = [ labels; label ];
        break;
      end
    end
    sections = [ sections; reshape(section, [1,3,8]) ];
    save(annotationsFile, 'labels', 'sections');

    record_more = get_boolean_input('Record another section?');  
    if ~record_more
      break;  
    end
  end
  close(fig1,fig2,vis);
end


function drawLines(x1, x2, x3, x4, x5, x6, x7, x8, drawI2)
  h = findobj('type', 'line'); for i=1:size(h),  delete(h(i)); end
  drawLinesHelper(P1, x1, x2, x3, x4, x5, x6, x7, x8);
  if drawI2
    figure(fig2);
    drawLinesHelper(P2, x1, x2, x3, x4, x5, x6, x7, x8);
    figure(fig1)
  end
end
function drawLinesHelper(P, x1, x2, x3, x4, x5, x6, x7, x8)
  h = findobj('type', 'line'); for i=1:size(h),  delete(h(i)); end
  p = [x1 x2];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); vectarrow(z1(1:2,1), z1(1:2,2), 'r');   % l1 = line(z1(1,:), z1(2,:), 'Color', 'g');   
  p = [x2 x3];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); l2 = line(z1(1,:), z1(2,:), 'Color', 'g');   
  p = [x3 x4];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); l3 = line(z1(1,:), z1(2,:), 'Color', 'g');   
  p = [x4 x1];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); vectarrow(z1(1:2,2), z1(1:2,1), 'b');   % l4 = line(z1(1,:), z1(2,:), 'Color', 'g');   
  p = [x5 x6];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); l5 = line(z1(1,:), z1(2,:), 'Color', 'g');   
  p = [x6 x7];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); l6 = line(z1(1,:), z1(2,:), 'Color', 'g');   
  p = [x7 x8];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); l7 = line(z1(1,:), z1(2,:), 'Color', 'g');   
  p = [x8 x5];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); l8 = line(z1(1,:), z1(2,:), 'Color', 'g');   
  p = [x1 x5];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); l9 = line(z1(1,:), z1(2,:), 'Color', 'g');   
  p = [x1 2*x1-x5];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); vectarrow(z1(1:2,1), z1(1:2,2), 'k');
  p = [x2 x6];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); l10 = line(z1(1,:), z1(2,:), 'Color', 'g');   
  p = [x3 x7];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); l11 = line(z1(1,:), z1(2,:), 'Color', 'g');   
  p = [x4 x8];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); l12 = line(z1(1,:), z1(2,:), 'Color', 'g');   
end
function illustrateOrientation(P, x1, x2, x3, x4, x5, x6, x7, x8)
  h = findobj('type', 'line'); for i=1:size(h),  delete(h(i)); end
  p = [x1 x2];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); line(z1(1,:), z1(2,:), 'Color', 'r', 'LineWidth', 5);   
  p = [x2 x3];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); line(z1(1,:), z1(2,:), 'Color', 'g', 'LineWidth', 5);   
  p = [x3 x4];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); line(z1(1,:), z1(2,:), 'Color', 'b', 'LineWidth', 5);   
  p = [x4 x1];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); line(z1(1,:), z1(2,:), 'Color', 'k', 'LineWidth', 5);   
  p = [x5 x6];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); line(z1(1,:), z1(2,:), 'Color', 'g');   
  p = [x6 x7];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); line(z1(1,:), z1(2,:), 'Color', 'g');   
  p = [x7 x8];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); line(z1(1,:), z1(2,:), 'Color', 'g');   
  p = [x8 x5];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); line(z1(1,:), z1(2,:), 'Color', 'g');   
  p = [x1 x5];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); line(z1(1,:), z1(2,:), 'Color', 'g');   
  p = [x2 x6];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); line(z1(1,:), z1(2,:), 'Color', 'g');   
  p = [x3 x7];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); line(z1(1,:), z1(2,:), 'Color', 'g');   
  p = [x4 x8];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); line(z1(1,:), z1(2,:), 'Color', 'g');   
end
function [x1,x2,x3,x4,x5,x6,x7,x8] = modifyWireframe(k,x1,x2,x3,x4,x5,x6,x7,x8,x,y,z)
  mul = 0.1;
  if k == ';'
    x2=x2+mul*x;  x3=x3+mul*x;  x6=x6+mul*x;  x7=x7+mul*x;
  elseif k == 'l'
    x2=x2-mul*x;  x3=x3-mul*x;  x6=x6-mul*x;  x7=x7-mul*x;
  elseif k == 'a'
    x1=x1-mul*x;  x4=x4-mul*x;  x5=x5-mul*x;  x8=x8-mul*x;
  elseif k == 's'
    x1=x1+mul*x;  x4=x4+mul*x;  x5=x5+mul*x;  x8=x8+mul*x;
  elseif k == 'd'
    x3=x3+mul*y;  x4=x4+mul*y;  x7=x7+mul*y;  x8=x8+mul*y;
  elseif k == 'f'
    x3=x3-mul*y;  x4=x4-mul*y;  x7=x7-mul*y;  x8=x8-mul*y;
  elseif k == 'j'
    x1=x1-mul*y;  x2=x2-mul*y;  x5=x5-mul*y;  x6=x6-mul*y;
  elseif k == 'k'
    x1=x1+mul*y;  x2=x2+mul*y;  x5=x5+mul*y;  x6=x6+mul*y;
  elseif k == 'g'
    x5=x5-mul*z;  x6=x6-mul*z;  x7=x7-mul*z;  x8=x8-mul*z;
  elseif k == 'h'
    x5=x5+mul*z;  x6=x6+mul*z;  x7=x7+mul*z;  x8=x8+mul*z;
  elseif k == 't'
    x1=x1+mul*z;  x2=x2+mul*z;  x3=x3+mul*z;  x4=x4+mul*z;
  elseif k == 'u'
    x1=x1-mul*z;  x2=x2-mul*z;  x3=x3-mul*z;  x4=x4-mul*z;
  elseif k == 'i'
    keyboard();
  else
    ;
  end

  % Draw
  % if k == 'q'
  %   drawLines(x1, x2, x3, x4, x5, x6, x7, x8, true);
  % else
  %   drawLines(x1, x2, x3, x4, x5, x6, x7, x8, false);
  % end
end
