function findPlaneNormals(ver)
  path = '/home/jayant/work/masters/research/vision/resources/SpatialLayout/spatiallayoutcode/ComputeVP';
  addpath(path);
  addpath('/home/jayant/software/matlab_2016/misc');

  K = getIntrinsicParams(); K = K(:,1:3);
  while true
    if exist(sprintf('reconstruction%07d/camera.txt', ver), 'file') == 2
      [fs,Rs,Cs] = readPoses(ver);
      ffile = sprintf('reconstruction%07d/vp_frames.mat', ver);
      if exist(ffile, 'file') == 2
        load(ffile);
      else
        frames = [];
      end
      while true
        i1 = input(sprintf('First image in batch %d-%d to read: ', ver+1, ver+230));
        i2 = input(sprintf('Second image in batch %d-%d to read: ', ver+1, ver+230));
        I1 = imread(sprintf('undistorted/image%07d.jpg', i1));
        I2 = imread(sprintf('undistorted/image%07d.jpg', i2));
        frames = [ frames [ i1; i2 ] ];

        for i=1:size(fs,1)
          if fs(i) == i1-ver
            R1 = reshape(Rs(i,1:3,1:3), [3,3]);  C1 = reshape(Cs(i,:), [3,1]);
          elseif fs(i) == i2-ver
            R2 = reshape(Rs(i,1:3,1:3), [3,3]);  C2 = reshape(Cs(i,:), [3,1]);
          end
        end
        % findPlaneNormal(I1, I2, R1, C1, R2, C2, K, ver);
        labelsFromVp(i1, i2, I1, I2, R1, C1, R2, C2, K, ver);
        s = input('Record another plane and associated sections? - y/n ', 's');  
        if s(1) == 'n'
          break;
        end
      end
      save(ffile, 'frames');
    end
    ver = ver + 200;
end
