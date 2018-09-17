function annotateFrames(store)
  % Read labels
  % Var1 will have timestamps, and Var2 the left:right labels
  labels_filename = sprintf('labels_%s.txt', store);
  T = readtable(labels_filename, 'Delimiter', ' ', 'ReadVariableNames', false);
  nl = size(T,1);

  function save_img(img, seq_num)
    filename = sprintf('%s_labeled_frames/img%0.5d.jpg', store, seq_num);
    imwrite(img, filename);
  end

  function label_img(seq_num, labels)
    img_name = sprintf('%s_frames/img%0.5d.jpg', store, seq_num);
    img = imread(img_name);

    labeled_img = insertObjectAnnotation(img, 'rectangle', [320, 500, 0, 0; 960, 500, 0, 0], labels, 'Color', 'Green');
    save_img(labeled_img, seq_num);
  end

  for i=1:nl-1
    st = strsplit(T.Var1{i}, ':'); st = 60 * str2num(st{1}) + str2num(st{2});
    et = strsplit(T.Var1{i+1}, '-'); et = strsplit(et{1}, ':'); et = 60 * str2num(et{1}) + str2num(et{2}) - 1;
    labels = strsplit(T.Var2{i}, ':');

    for d=st:et
      label_img(d, labels);
    end
  end

  ts = strsplit(T.Var1{nl}, '-');
  st = strsplit(ts{1}, ':'); st = 60 * str2num(st{1}) + str2num(st{2});
  et = strsplit(ts{2}, ':'); et = 60 * str2num(et{1}) + str2num(et{2});
  labels = strsplit(T.Var2{nl}, ':');
  for d=st:et
    label_img(d, labels);
  end
end
