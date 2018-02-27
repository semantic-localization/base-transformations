function ensureDir(dir_name)
  if ~exist(dir_name, 'dir')
    mkdir(dir_name);
  end
end
