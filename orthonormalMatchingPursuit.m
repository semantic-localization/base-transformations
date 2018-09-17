function [code_vector] = orthonormalMatchingPursuit(img_num, m)
  %% Find an m-sparse representation of image corresponding to img_num from the dictionary of samples
  N = 10000;
  if img_num <= N, disp('Sorry, not possible right now'); return; end
  X = getFeatureVector(img_num);
  D = getDictionary();
  d = 52*15;

  code_vector = zeros(N,1);
  phi = [];
  I = eye(d,d);
  for j=1:m
    max_dp = D(1,:) * X;
    max_idx = 1;
    for k=2:N-1
      dp = abs(D(k,:) * X);
      if dp > max_dp
        max_dp = dp;
        max_idx = k;
      end
    end
    code_vector(max_idx) = max_dp;
    phi = [ phi, D(max_idx,:)' ];
    P = phi * pinv(phi);
    X = (I-P)*X;
  end

  for i=1:N
    if code_vector(i) > 0,  disp([i code_vector(i)]);  end
  end
end
