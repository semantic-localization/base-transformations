function insertMarkers()
  % Read labels
  % Var1 will have timestamps, and Var2 the left:right labels
  load('projections.mat');
  ks = keys(projections);
  for k=ks
    frame = k{1};
    path = projections(frame);
    img_f = sprintf('image/image00%05d.jpg', str2num(frame));
  f_name = sprintf('reconstruction00%05d/camera.txt', f_i);
    img = imread(img_f);
    for i=1:size(path,2)
      pt = path{1};
      img = insertMarker(img, pt');
    end
    img_f = sprintf('marked/image00%05d.jpg', str2num(frame));
    imwrite(img, img_f);
  end
end
