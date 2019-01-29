function [I,R,C,P] = imgCamPose(ver_id, id)
  if nargin == 1
    id = mod(ver_id, 200);
    ver = ver_id - id;
  else
    ver = ver_id;
  end

  I = imread(sprintf('undistorted/image%07d.jpg', ver+id));
  [fs,Rs,Cs] = readPoses(ver);
  for i=1:size(fs,1)
    if fs(i) == id
      R = reshape(Rs(i,1:3,1:3), [3,3]);  C = reshape(Cs(i,:), [3,1]);
      break;
    end
  end

  K = getIntrinsicParams(); K = K(1:3,1:3);
  P = K * R * [ eye(3) -C ];
end
