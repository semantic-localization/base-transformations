% reproj error using symmetric I1 & I2
% visualize reproj before and after refinement using I1 to I2 and vice-versa
% large disparity maybe

function [n,u1,u2] = findPlaneNormal(I1, I2, R1, C1, R2, C2, K, ver)
  P1 = K * R1 * [eye(3)  -C1];
  P2 = K * R2 * [eye(3)  -C2];
  fig1 = figure;
  imshow(I1);
  fig2 = figure;
  imshow(I2);

  use_file = true;
  function [u1,u2] = getinput()
  cfile = sprintf('reconstruction%07d/clicks.mat', ver);
    if use_file && exist(cfile, 'file') == 2
      load(cfile);
    else
      figure(fig1);
      [x1, y1] = ginput(4);
      u1 = [ x1'; y1'; ones(1,4) ];

      % pause(1);
      figure(fig2);
      [x2, y2] = ginput(4);
      u2 = [ x2'; y2'; ones(1,4) ];
      save(cfile, 'u1', 'u2');
    end
  end

  while true
    figure(fig1); h = findobj('type', 'patch'); delete(h(:)); h = findobj('type', 'line'); delete(h(:));
    figure(fig2); h = findobj('type', 'patch'); delete(h(:)); h = findobj('type', 'line'); delete(h(:));

    [u1,u2] = getinput();
    use_file = false;
    % patch(u1(1,[1,2,6,5]), u1(2,[1,2,6,5]), 'r')
    % patch(u1(1,[3,4,8,7]), u1(2,[3,4,8,7]), 'r')
    figure(fig1);
    patch(u1(1,[1,2,3,4]), u1(2,[1,2,3,4]), 'r')
    % patch(u2(1,[1,2,6,5]), u2(2,[1,2,6,5]), 'r')
    % patch(u2(1,[3,4,8,7]), u2(2,[3,4,8,7]), 'r')
    figure(fig2);
    patch(u2(1,[1,2,3,4]), u2(2,[1,2,3,4]), 'r')
    % input('ENTER to proceed ');

    %% Linear LS
    X = zeros(3,4);
    for i=1:4
      u1x = Vec2Skew(u1(:,i));
      u2x = Vec2Skew(u2(:,i));
      A = [ u1x * P1(:,1:3); u2x * P2(:,1:3) ];
      b = [ -u1x * P1(:,4); -u2x * P2(:,4) ];
      X(:,i) = A \ b;
    end

    Y = [ X; ones(1,4) ];
    
    figure(fig1);
    z1 = P1 * Y;
    z1 = z1 ./ z1(3,:);
    % patch(z1(1,[1,2,6,5]), z1(2,[1,2,6,5]), 'b')
    % patch(z1(1,[3,4,8,7]), z1(2,[3,4,8,7]), 'b')
    patch(z1(1,[1,2,3,4]), z1(2,[1,2,3,4]), 'b')
    
    figure(fig2);
    z2 = P2 * Y;
    z2 = z2 ./ z2(3,:);
    % patch(z2(1,[1,2,6,5]), z2(2,[1,2,6,5]), 'b')
    % patch(z2(1,[3,4,8,7]), z2(2,[3,4,8,7]), 'b')
    patch(z2(1,[1,2,3,4]), z2(2,[1,2,3,4]), 'b')

    [~,~,V] = svd(Y);
    n = -V(1:3,4)/V(4,4);
    % x1 = X(:,1);  x2 = X(:,2);  x3 = X(:,3);  x4 = X(:,4);
    X1n = X + n;
    % x1n = X1n(:,1);  x2n = X1n(:,2);  x3n = X1n(:,3);  x4n = X1n(:,4);
    fig3 = figure;
    scatter3(X(1,:), X(2,:), X(3,:), 'r', 'filled');
    hold on;
    plotPlane(n);
    for i=1:4
      foo = [ X(:,i) X1n(:,i) ];  plot3(foo(1,:), foo(2,:), foo(3,:), 'Color', 'g', 'LineWidth', 2);
    end
    axis equal;
    disp(X' * n - 1);

    % Visualize plane normal in I1/I2
    mul = 5;
    z1 = P1 * [ X X+mul*n X-mul*n; ones(1,12) ];
    z1 = z1 ./ z1(3,:);
    figure(fig1); 
    for i=1:4   
      line(z1(1,[i,i+4]), z1(2,[i,i+4]), 'Color', 'b', 'LineWidth', 5);   
      line(z1(1,[i,i+8]), z1(2,[i,i+8]), 'Color', 'b', 'LineWidth', 5);   
    end
    z2 = P2 * [ X X+mul*n X-mul*n; ones(1,12) ];
    z2 = z2 ./ z2(3,:);
    figure(fig2); 
    for i=1:4   
      line(z2(1,[i,i+4]), z2(2,[i,i+4]), 'Color', 'b', 'LineWidth', 5);   
      line(z2(1,[i,i+8]), z2(2,[i,i+8]), 'Color', 'b', 'LineWidth', 5);   
    end
    % patch(z2(1,:), z2(2,:), 'b');
    % z2 = P2 * [ X(:,7) X(:,8) X(:,8)+n X(:,7)+n; ones(1,4) ];
    % z2 = z2 ./ z2(3,:);
    % patch(z2(1,:), z2(2,:), 'b');
    % input('ENTER to proceed ');
    figure(fig1); h = findobj('type', 'patch'); delete(h(1));
    figure(fig2); h = findobj('type', 'patch'); delete(h(1));

    % visualize quality of reprojection via n from I1 -> I2
    z2 = reproject(n, u1, R1, C1, P1, K);
    figure(fig1);
    patch(z2(1,:), z2(2,:), 'y');
    z2 = reproject(n, u1, R1, C1, P2, K);
    figure(fig2);
    patch(z2(1,:), z2(2,:), 'g');
    % input('ENTER to proceed ');
    figure(fig1); h = findobj('type', 'patch'); delete(h(1));
    figure(fig2); h = findobj('type', 'patch'); delete(h(1));

    % visualize quality of reprojection via n from I2 -> I1
    z2 = reproject(n, u2, R2, C2, P2, K);
    figure(fig2);
    patch(z2(1,:), z2(2,:), 'y');
    z2 = reproject(n, u2, R2, C2, P1, K);
    figure(fig1);
    patch(z2(1,:), z2(2,:), 'g');
    % input('ENTER to proceed ');
    figure(fig1); h = findobj('type', 'patch'); delete(h(1));
    figure(fig2); h = findobj('type', 'patch'); delete(h(1));

    %% Non-Linear
    fun = @(n) reprojectionError(n, u1, u2, R1, C1, P2, K) + reprojectionError(n, u2, u1, R2, C2, P1, K);
    options = optimoptions(@fminunc,'Display','iter','Algorithm','quasi-newton','OptimalityTolerance',1e-12,'MaxFunctionEvaluations',1000);
    [n,fval,exitflag,output] = fminunc(fun, n, options)

    % Patch 1, reproject onto I2 using n and I1
    % z2 = [];
    % for i=[1 2 6 5]
    %   X = calculate3D(n, u1(:,i), P1);
    %   v2 = projectOntoI2(P2, X);
    %   z2 = [ z2 v2 ];
    % end
    % patch(z2(1,:), z2(2,:), 'g');
    % Patch 2
    % z2 = [];
    % for i=[3 4 8 7]
    %   X = calculate3D(n, u1(:,i), P1);
    %   v2 = projectOntoI2(P2, X);
    %   z2 = [ z2 v2 ];
    % end
    % patch(z2(1,:), z2(2,:), 'g');

    % normal to X3,X4
    X = zeros(3,4);
    for i=1:4,  X(:,i) = calculate3D(n, u2(:,i), R2, C2, K);   end
    % X1n = X + n;
    % x1n = X1n(:,1);  x2n = X1n(:,2);  x3n = X1n(:,3);  x4n = X1n(:,4);
    % fig4 = figure;
    % scatter3(X(1,:), X(2,:), X(3,:), 'r', 'filled');
    % hold on;
    % plotPlane(n);
    % for i=1:4  
    %   foo = [ X(:,i) X1n(:,i) ];  plot3(foo(1,:), foo(2,:), foo(3,:), 'Color', 'g', 'LineWidth', 2);   
    % end
    % axis equal;
    % input('ENTER to proceed ');

    % Visualize plane normal in I1/I2
    mul = 15;
    z2 = P2 * [ X X+mul*n X-mul*n ; ones(1,12) ];
    % z2 = P2 * [ X(:,1) X(:,2) X(:,3) X(:,4) X(:,1)-10*unit(n) X(:,2)-10*unit(n) X(:,3)-10*unit(n) X(:,4)-10*unit(n); ones(1,8) ];
    z2 = z2 ./ z2(3,:);
    figure(fig2);
    for i=1:4   
      line(z2(1,[i,i+4]), z2(2,[i,i+4]), 'Color', 'g', 'LineWidth', 5);   
      line(z2(1,[i,i+8]), z2(2,[i,i+8]), 'Color', 'g', 'LineWidth', 5);   
    end
    for i=1:4,  X(:,i) = calculate3D(n, u1(:,i), R1, C1, K);   end
    z1 = P1 * [ X X+mul*n X-mul*n ; ones(1,12) ];
    % z1 = P2 * [ X(:,1) X(:,2) X(:,3) X(:,4) X(:,1)-10*unit(n) X(:,2)-10*unit(n) X(:,3)-10*unit(n) X(:,4)-10*unit(n); ones(1,8) ];
    z1 = z1 ./ z1(3,:);
    figure(fig1);
    for i=1:4   
      line(z1(1,[i,i+4]), z1(2,[i,i+4]), 'Color', 'g', 'LineWidth', 5);   
      line(z1(1,[i,i+8]), z1(2,[i,i+8]), 'Color', 'g', 'LineWidth', 5);   
    end
    % line(z2(1,[1,4]), z2(2,[1,4]), 'Color', 'g', 'LineWidth', 5);
    % line(z2(1,[2,3]), z2(2,[2,3]), 'Color', 'g', 'LineWidth', 5);
    % patch(z2(1,:), z2(2,:), 'g');

    % visualize quality of reprojection via n from I1 -> I2
    z2 = reproject(n, u1, R1, C1, P1, K);
    figure(fig1);
    patch(z2(1,:), z2(2,:), 'y');
    z2 = reproject(n, u1, R1, C1, P2, K);
    figure(fig2);
    patch(z2(1,:), z2(2,:), 'g');
    % input('ENTER to proceed ');
    s = input('Normal OK? ', 's');  if s(1) == 'y', break;  end
    figure(fig1); h = findobj('type', 'patch'); delete(h(1));
    figure(fig2); h = findobj('type', 'patch'); delete(h(1));

    % visualize quality of reprojection via n from I2 -> I1
    z2 = reproject(n, u2, R2, C2, P2, K);
    figure(fig2);
    patch(z2(1,:), z2(2,:), 'y');
    z2 = reproject(n, u2, R2, C2, P1, K);
    figure(fig1);
    patch(z2(1,:), z2(2,:), 'g');
    % input('ENTER to proceed ');
    figure(fig1); h = findobj('type', 'patch'); delete(h(1));
    figure(fig2); h = findobj('type', 'patch'); delete(h(1));
    close(fig3);
  end

  close(fig3);

  %% Normal OK. Proceed.
  figure(fig1); h = findobj('type', 'patch'); for i=1:size(h),  delete(h(i)); end
  figure(fig2); h = findobj('type', 'patch'); for i=1:size(h),  delete(h(i)); end
  z = unit(n);
  x1 = X(:,1);
  x2 = X(:,2);
  x3 = X(:,3);
  x4 = X(:,4);
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
    p = [x1 x2];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); l1 = line(z1(1,:), z1(2,:), 'Color', 'g');   
    p = [x2 x3];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); l2 = line(z1(1,:), z1(2,:), 'Color', 'g');   
    p = [x3 x4];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); l3 = line(z1(1,:), z1(2,:), 'Color', 'g');   
    p = [x4 x1];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); l4 = line(z1(1,:), z1(2,:), 'Color', 'g');   
    p = [x5 x6];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); l5 = line(z1(1,:), z1(2,:), 'Color', 'g');   
    p = [x6 x7];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); l6 = line(z1(1,:), z1(2,:), 'Color', 'g');   
    p = [x7 x8];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); l7 = line(z1(1,:), z1(2,:), 'Color', 'g');   
    p = [x8 x5];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); l8 = line(z1(1,:), z1(2,:), 'Color', 'g');   
    p = [x1 x5];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); l9 = line(z1(1,:), z1(2,:), 'Color', 'g');   
    p = [x2 x6];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); l10 = line(z1(1,:), z1(2,:), 'Color', 'g');   
    p = [x3 x7];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); l11 = line(z1(1,:), z1(2,:), 'Color', 'g');   
    p = [x4 x8];  z1 = P * [ p; ones(1,2) ]; z1 = z1 ./ z1(3,:); l12 = line(z1(1,:), z1(2,:), 'Color', 'g');   
  end
  function modifyWireframe(k)
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
    else
      ;
    end

    % Draw
    if k == 'q'
      drawLines(x1, x2, x3, x4, x5, x6, x7, x8, true);
    else
      drawLines(x1, x2, x3, x4, x5, x6, x7, x8, false);
    end
  end

  % labeling loop
  labelkey = {
    'beverages', 
    'bread', 
    'cereal', 
    'cheese', 
    'counter', 
    'dairy', 
    'entrance', 
    'flowers', 
    'frozenfood', 
    'health', 
    'meat', 
    'oils', 
    'pasta', 
    'snacks', 
    'vegetables', 
    'water', 
    'none'
    };
  labels = [];
  sections = [];
  while true
    s = input('Record section? - y/n ', 's');  
    if s(1) == 'n'
      break;  
    end

    s = input('Section aligned with left or right? ', 's');  
    if s(1) == 'l'
      y = unit(x4 - x3);
      x1 = x3;
    else
      y = unit(x2 - x1);
      x1 = x1;
    end
    x = unit(cross(y,z));
    % p = [x1 x2 x3 x4]; z1 = P1 * [ p; ones(1,4) ]; z1 = z1 ./ z1(3,:); patch(z1(1,:), z1(2,:), 'g')
    % p = [x1 x4 x8 x5]; z1 = P1 * [ p; ones(1,4) ]; z1 = z1 ./ z1(3,:); patch(z1(1,:), z1(2,:), 'g')

    x2=x1+x;  x3=x2+y; x4=x3-x;
    x5=x1-z;  x6=x2-z;  x7=x3-z;  x8=x4-z;
    drawLines(x1, x2, x3, x4, x5, x6, x7, x8, false);
    while true
      figure(fig1);
      waitforbuttonpress;
      k = get(gcf, 'CurrentCharacter');
      if k == 'z', break;  end
      modifyWireframe(k);
    end
    while true
      user_label = input('Enter label: ', 's');
      label = find(strcmp(labelkey, user_label));
      if label
        labels = [ labels label ];
        break;
      end
    end
    section = [ x1 x2 x3 x4 x5 x6 x7 x8 ];
    sections = [ sections reshape(section, [1,3,8]) ];
  end
  save(sprintf('reconstruction%07d/3dannotations.mat', ver), 'labels', 'sections');
  return;

  l = [ x1 x4 x5 x8 ];
  r = [ x2 x3 x6 x7 ];

  left_section = [];
  left = input('Identify section on left? ', 's');
  if left(1) == 'y'
    x2=l(:,1);  x3=l(:,2);  x1=x2-x;  x4=x3-x;
    x6=l(:,3);  x7=l(:,4);  x5=x6-x;  x8=x7-x;
    drawLines(x1, x2, x3, x4, x5, x6, x7, x8, false);
    while true
      figure(fig1);
      waitforbuttonpress;
      k = get(gcf, 'CurrentCharacter');
      if k == 'z', break;  end
      modifyWireframe(k);
    end
    left_section = [ left_section x1 x2 x3 x4 x5 x6 x7 x8 ];
  end

  right_section = [];
  right = input('Identify section on right? ', 's');
  if right(1) == 'y'
    x1=r(:,1);  x4=r(:,2);  x2=x1+x;  x3=x4+x;
    x5=r(:,3);  x8=r(:,4);  x6=x5+x;  x7=x8+x;
    drawLines(x1, x2, x3, x4, x5, x6, x7, x8, false);
    while true
      figure(fig1);
      waitforbuttonpress;
      k = get(gcf, 'CurrentCharacter');
      if k == 'z', break;  end
      modifyWireframe(k);
    end
    right_section = [ x1 x2 x3 x4 x5 x6 x7 x8 ];
  end

  close(fig1, fig2);
  save(sprintf('reconstruction%07d/points.mat', ver), 'aisle', 'left_section', 'right_section');
  return;

  [fs, Rs, Cs] = readPoses(0);
  fig = gcf;
  fig.PaperPositionMode = 'auto';
  % set(fig, 'visible', 'off');
  for i=1:size(fs,1)
    disp(fs(i));
    imgname = sprintf('image%07d.jpg', fs(i));
    dirname = 'undistorted';
    imgpath = sprintf('%s/%s', dirname, imgname);
    I = imread(imgpath);
    R = reshape(Rs(i,1:3,1:3), [3,3]);  C = reshape(Cs(i,:), [3,1]);
    P = K * R * [ eye(3) -C ];
    imshow(I);
    drawLinesHelper(P1, x1, x2, x3, x4, x5, x6, x7, x8);
    dirname = 'annotated';
    imgpath = sprintf('%s/%s', dirname, imgname);
    print(imgpath, '-djpeg', '-r0');
  end
end

function [err] = reprojectionError(n, u1, u2, R1, C1, P2, K)
  err = 0;
  for i=1:size(u1,2)
    X = calculate3D(n, u1(:,i), R1, C1, K);
    v2 = projectOntoI2(P2, X);
    err = err + norm(v2 - u2(:,i))^2;
  end
  err = err/size(u1,2);
end

function [v2] = reproject(n, u1, R1, C1, P2, K)
  v2 = [];
  for i=1:size(u1,2)
    X = calculate3D(n, u1(:,i), R1, C1, K);
    v2 = [ v2 projectOntoI2(P2, X) ];
  end
end

function [X] = calculate3D(n, u, R, C, K)
  % p1 = P1(1,:); p2 = P1(2,:); p3 = P1(3,:);
  % A = [ p1(1:3) - u(1)*p3(1:3); p2(1:3) - u(2)*p3(1:3); n' ];
  % b = [ -p1(4) + u(1)*p3(4); -p2(4) + u(2)*p3(4); 1 ];
  % X = A \ b;
  B = R' * inv(K) * u;
  lambda = (1 - n'*C) / (n'*B);
  X = lambda*B + C;
end

function [v] = projectOntoI2(P2, X)
  v = P2 * [ X; 1 ];
  v = v ./ v(3);
end

function plotPlane(n)
a = 5;
pts = [ -a -a a a; -a a a -a ];
p = (1 - pts' * [ n(1) n(2) ]') / n(3);
% disp(n);
% disp(p);
pts = [ pts; p' ];
C = [0.5000 1.0000 1.0000 0.5000];
% for i=1:3,  foo = pts(:,[i,i+1]);  plot3(foo(1,:), foo(2,:), foo(3,:), 'Color', 'r', 'LineWidth', 2);   end
% foo = pts(:,[4,1]);  plot3(foo(1,:), foo(2,:), foo(3,:), 'Color', 'r', 'LineWidth', 2);
fill3(pts(1,:), pts(2,:), pts(3,:), C);
% view(3);
for i=1:4 p = [ pts(:,i) pts(:,i)+n ]; plot3(p(1,:), p(2,:), p(3,:), 'Color', 'g', 'LineWidth', 2); end
pts = pts + n;
end
