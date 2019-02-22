function visualize3dSpaceAndTrajectory(ver)
  vis = figure();

  % Cam trajectory
  [fs1,Rs1,Cs1] = readPoses(ver);
  inc = linspace(0,1,size(fs1,1));
  cls = [ ones(size(fs1))-inc' zeros(size(fs1))+inc' zeros(size(fs1)) ];
  [~,I] = sort(fs1);
  sRs1 = Rs1(I,1:3,1:3);
  sCs1 = Cs1(I,:);
  scatter3(sCs1(:,1), sCs1(:,2), sCs1(:,3), 20, cls, '+');

  hold on;
  axis equal;

  % Point cloud
  [num_pt, pts, ~, rgb] = readPointCloud(ver);
  cutoff = 2;
  xlims = xlim();   xlim([min([prctile(pts(:,1), cutoff) xlims(1)]), max([prctile(pts(:,1), 100-cutoff) xlims(2)])]);
  ylims = ylim();   ylim([min([prctile(pts(:,2), cutoff) ylims(1)]), max([prctile(pts(:,2), 100-cutoff) ylims(2)])]);
  zlims = zlim();   zlim([min([prctile(pts(:,3), cutoff) zlims(1)]), max([prctile(pts(:,3), 100-cutoff) zlims(2)])]);
  scatter3(pts(:,1), pts(:,2), pts(:,3), 2, rgb/255);

  % axis manual;
  % axis normal;

  %% STITCHING
  [fs2,Rs2,Cs2] = readPoses(ver+200);
  [~,I] = sort(fs2);
  sRs2 = Rs2(I,1:3,1:3);
  sCs2 = Cs2(I,:);

  R_215 = squeeze(sRs1(201,:,:));
  R_230 = squeeze(sRs1(230,:,:));
  R_15 = squeeze(sRs2(1,:,:));
  R_30 = squeeze(sRs2(30,:,:));

  C_215 = sCs1(201,:)';
  C_230 = sCs1(230,:)';
  C_15 = sCs2(1,:)';
  C_30 = sCs2(30,:)';
  
  R_rel = inv(R_15) * R_215;
  s = norm(C_30 - C_15) / norm(C_230 - C_215);
  C_rel = C_215 - inv(R_rel) * C_15 / s;
  % keyboard();

  sCs2 = (inv(R_rel) * sCs2' / s + C_rel)';
  inc = linspace(0,1,size(fs2,1));
  cls = [ ones(size(fs2))-inc' zeros(size(fs2))+inc' zeros(size(fs2)) ];
  scatter3(sCs2(:,1), sCs2(:,2), sCs2(:,3), 20, cls, '+');

  for i=1:30
    disp( norm(sCs2(i,:) - sCs1(200+i,:)) / norm(sCs1(200+i,:) - sCs1(1,:)) );
  end
end
