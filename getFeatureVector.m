function [feature_vector] = getFeatureVector(img_num)
  load(sprintf('labels/labels_%07d.mat', img_num));
  feature_vector = zeros(52*15,1);
  label_offset = 3 * 13;
  for i=1:52
    lbl = labels(label_offset + i);
    idx_offset = 15 * (i-1);
    lbl_idx = lbl+1;    % Because python is 0-index based
    feature_vector(idx_offset + lbl_idx) = 1;
  end
  feature_vector = feature_vector ./ norm(feature_vector);
end
