function findPlaneNormals(ver)
  path = '/home/jayant/SpatialLayout/spatiallayoutcode/ComputeVP';
  addpath(path);

  K = getIntrinsicParams(); K = K(:,1:3);
  while true
    if exist(sprintf('reconstruction%07d/camera.txt', ver), 'file') == 2
      [fs,Rs,Cs] = readPoses(ver);
      ffile = sprintf('reconstruction%07d/vp_frames.mat', ver);
      if exist(ffile, 'file') == 2
        load(ffile);
      else
        frames = {};
      end
      while true
        i1 = input(sprintf('Image in batch %d-%d to be 3D labeled: ', ver+1, ver+230));
        image_nums = [i1];
        % num_tri = input('Number of additional images to triangulate origin (minimum 1): ');
        num_tri = 1;
        for i=1:num_tri
          i2 = input(sprintf('Another image in range %d-%d: ', ver+1, ver+230));
          image_nums = [ image_nums i2 ];
        end
        frames{end+1} = image_nums;

        % findPlaneNormal(I1, I2, R1, C1, R2, C2, K, ver);
        labelsFromVp(image_nums, ver, K);
        another_plane = get_boolean_input('Record another plane and associated sections?');  
        if ~another_plane
          break;
        end
      end
      save(ffile, 'frames');
    end
    ver = ver + 200;
  end
end
