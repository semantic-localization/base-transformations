function labelWindows(img_file)
  img = imread(img_file);
  fname = split(img_file, '/');
  fname = fname(size(fname,1));
  img_num = split(fname, '.'); img_num = img_num(1);
  load(sprintf('window_labels_%s.mat', img_num));
  [height, width, ~] = size(img);
  step = int32(100);
  windows_per_height_level = idivide(width, step) + 1;
  for h=1:100:height
    for w=1:100:width
      ew = min(w+100,width); eh = min(h+100,height);
      wspan = ew-w; hspan = eh-h;
      idx = windows_per_height_level * idivide(h,step) + idivide(w,step) + 1;
      window_label = window_labels(idx,:);
      window_label = strip(window_label);
      loc = [w-31 + wspan/2, h-11 + hspan/2, 0, 0];
      img = insertObjectAnnotation(img, 'rectangle', loc, window_label, 'Color', 'Green');
    end
  end
  imwrite(img, sprintf('labelled_%s', fname));
end
