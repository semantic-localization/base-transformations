function warpUsing3dAnnotation(ver)
  K = getIntrinsicParams();  K = K(:,1:3);
  [fs,Rs,Cs] = readPoses(ver);
  load(sprintf('reconstruction%07d/vp_3dannotations.mat', ver));
  x1 = sections(1,:,1);
  x2 = sections(1,:,2);
  x4 = sections(1,:,4);
  x5 = sections(1,:,5);
  x = unit(x2-x1);
  y = unit(x4-x1);
  z = unit(x1-x5);
  Rn = [ x; -z; y ];
  for i=1:size(fs,1)
    R = reshape(Rs(i,1:3,1:3), [3,3]);
    H = K * Rn * R' * inv(K);
    I = imread(sprintf('annotated/image%07d.jpg', fs(i)+ver));
    In = ImageWarping(I, H);
    imwrite(In, sprintf('annotated/rectified/image%07d.jpg', fs(i)+ver));
    if mod(i,10) == 0,  disp(i);  end
  end
end
