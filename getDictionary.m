function [D] = getDictionary
  dfname = 'dictionary.mat'; 
  if exist(dfname, 'file') == 2
    load(dfname);
    return;
  end

  % Else, compute D
  N = 10000;
  d = 52*15;
  D = zeros(N,d);
  for i=1:N
    D(i,:) = getFeatureVector(i);
  end
  save(dfname, 'D');
end
