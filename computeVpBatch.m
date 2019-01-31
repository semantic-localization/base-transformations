function computeVpBatch(img_nums)
imdir = 'undistorted/';
vpdir = 'vp/';
for img_num=img_nums
  disp(img_num);
  getVP(imdir, sprintf('image%07d.jpg', img_num), 0, vpdir);
end
end
