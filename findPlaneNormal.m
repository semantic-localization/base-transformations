% reproj error using symmetric I1 & I2
% visualize reproj before and after refinement using I1 to I2 and vice-versa
% large disparity maybe

function [n,u1,u2] = findPlaneNormal(I1, I2, P1, P2)
  load('clicks.mat');
  fig1 = figure;
  imshow(I1);
  % [x1, y1] = ginput(4);
  % u1 = [ x1'; y1'; ones(1,4) ];
  % patch(u1(1,[1,2,6,5]), u1(2,[1,2,6,5]), 'r')
  % patch(u1(1,[3,4,8,7]), u1(2,[3,4,8,7]), 'r')
  patch(u1(1,[1,2,3,4]), u1(2,[1,2,3,4]), 'r')

  fig2 = figure;
  imshow(I2);
  pause(1);
  % [x2, y2] = ginput(4);
  % u2 = [ x2'; y2'; ones(1,4) ];
  % patch(u2(1,[1,2,6,5]), u2(2,[1,2,6,5]), 'r')
  % patch(u2(1,[3,4,8,7]), u2(2,[3,4,8,7]), 'r')
  patch(u2(1,[1,2,3,4]), u2(2,[1,2,3,4]), 'r')
  % save('clicks.mat', 'u1', 'u2');
  input('ENTER to proceed ');

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
  n = unit(V(1:3,end));
  z2 = P2 * [ X(:,1) X(:,2) X(:,3) X(:,4) X(:,1)-10*n X(:,2)-10*n X(:,3)-10*n X(:,4)-10*n; ones(1,8) ];
  z2 = z2 ./ z2(3,:);
  figure(fig2); 
  for i=1:4   line(z2(1,[i,i+4]), z2(2,[i,i+4]), 'Color', 'b', 'LineWidth', 5);   end
  % patch(z2(1,:), z2(2,:), 'b');
  % z2 = P2 * [ X(:,7) X(:,8) X(:,8)+n X(:,7)+n; ones(1,4) ];
  % z2 = z2 ./ z2(3,:);
  % patch(z2(1,:), z2(2,:), 'b');
  input('ENTER to proceed ');
  figure(fig1); h = findobj('type', 'patch'); delete(h(1));
  figure(fig2); h = findobj('type', 'patch'); delete(h(1));

  % visualize quality of reprojection via n from I1 -> I2
  z2 = reproject(n, u1, P1, P1);
  figure(fig1);
  patch(z2(1,:), z2(2,:), 'g');
  z2 = reproject(n, u1, P1, P2);
  figure(fig2);
  patch(z2(1,:), z2(2,:), 'g');
  input('ENTER to proceed ');
  figure(fig1); h = findobj('type', 'patch'); delete(h(1));
  figure(fig2); h = findobj('type', 'patch'); delete(h(1));

  % visualize quality of reprojection via n from I2 -> I1
  z2 = reproject(n, u2, P2, P2);
  figure(fig2);
  patch(z2(1,:), z2(2,:), 'g');
  z2 = reproject(n, u2, P2, P1);
  figure(fig1);
  patch(z2(1,:), z2(2,:), 'g');
  input('ENTER to proceed ');
  figure(fig1); h = findobj('type', 'patch'); delete(h(1));
  figure(fig2); h = findobj('type', 'patch'); delete(h(1));

  %% Non-Linear
  fun = @(n) reprojectionError(n, u1, u2, P1, P2) + reprojectionError(n, u2, u1, P2, P1);
  options = optimoptions(@fminunc,'Display','iter','Algorithm','quasi-newton');
  [n,fval] = fminunc(fun, n, options);

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
  figure(fig2);
  X = zeros(3,4);
  for i=1:4,  X(:,i) = calculate3D(n, u2(:,i), P2);   end
  z2 = P2 * [ X(:,1) X(:,2) X(:,3) X(:,4) X(:,1)-10*unit(n) X(:,2)-10*unit(n) X(:,3)-10*unit(n) X(:,4)-10*unit(n); ones(1,8) ];
  z2 = z2 ./ z2(3,:);
  for i=1:4   line(z2(1,[i,i+4]), z2(2,[i,i+4]), 'Color', 'g', 'LineWidth', 5);   end
  % line(z2(1,[1,4]), z2(2,[1,4]), 'Color', 'g', 'LineWidth', 5);
  % line(z2(1,[2,3]), z2(2,[2,3]), 'Color', 'g', 'LineWidth', 5);
  % patch(z2(1,:), z2(2,:), 'g');

  % visualize quality of reprojection via n from I1 -> I2
  z2 = reproject(n, u1, P1, P1);
  figure(fig1);
  patch(z2(1,:), z2(2,:), 'g');
  z2 = reproject(n, u1, P1, P2);
  figure(fig2);
  patch(z2(1,:), z2(2,:), 'g');
  input('ENTER to proceed ');
  figure(fig1); h = findobj('type', 'patch'); delete(h(1));
  figure(fig2); h = findobj('type', 'patch'); delete(h(1));

  % visualize quality of reprojection via n from I2 -> I1
  z2 = reproject(n, u2, P2, P2);
  figure(fig2);
  patch(z2(1,:), z2(2,:), 'g');
  z2 = reproject(n, u2, P2, P1);
  figure(fig1);
  patch(z2(1,:), z2(2,:), 'g');
  input('ENTER to proceed ');
  figure(fig1); h = findobj('type', 'patch'); delete(h(1));
  figure(fig2); h = findobj('type', 'patch'); delete(h(1));

  close(fig1, fig2);
end

function [err] = reprojectionError(n, u1, u2, P1, P2)
  err = 0;
  for i=1:size(u1,2)
    X = calculate3D(n, u1(:,i), P1);
    v2 = projectOntoI2(P2, X);
    err = err + norm(v2 - u2(:,i))^2;
  end
  err = err/size(u1,2);
end

function [v2] = reproject(n, u1, P1, P2)
  v2 = [];
  for i=1:size(u1,2)
    X = calculate3D(n, u1(:,i), P1);
    v2 = [ v2 projectOntoI2(P2, X) ];
  end
end

function [X] = calculate3D(n, u, P1)
  p1 = P1(1,:); p2 = P1(2,:); p3 = P1(3,:);
  A = [ p1(1:3) - u(1)*p3(1:3); p2(1:3) - u(2)*p3(1:3); n' ];
  b = [ -p1(4) + u(1)*p3(4); -p2(4) + u(2)*p3(4); 1 ];
  X = A \ b;
end

function [v] = projectOntoI2(P2, X)
  v = P2 * [ X; 1 ];
  v = v ./ v(3);
end
