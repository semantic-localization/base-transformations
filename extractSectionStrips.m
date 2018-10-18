function extractSectionStrips(ver, alignment)
  K = getIntrinsicParams(); K = K(:,1:3);
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
    lft = [ x1(1) min(x1(2), x4(2)) x1(3) ];
    rgt = [ x2(1) max(x2(2), x3(2)) x2(3) ];
    num_steps = 30;
    steps = linspace(0,rgt(2)-lft(2),30);
    % H = K * Rn * R' * inv(K);
    % I = ImageWarping(I, H);
    % imshow(I);
    for i=1:size(fs,1)
      % single img exp
      if fs(i) ~= 42, continue; end

      P = K * R * [ eye(3) -C ];
      Pn = K * Rn * [ eye(3) -C ];

      
    end
  end
end
