function trackPatch(j, frameIds, Rs, Cs, R1, C1, K, x1, y1, lambdas)
I = imread(sprintf('rectification/undistort/image%07dRectified.jpg', j));
for i=1:230
  if frameIds(i) == j
    R = reshape(Rs(i,1:3,1:3), [3,3]);
    C = reshape(Cs(i,:), [3,1]);
    break;
  end
end

B = K * R * (C1 - C);
x = zeros(4,1); y = zeros(4,1);
for i=1:4
  A = K * R * inv(R1) * inv(K) * [x1(i) y1(i) 1]';
  u = lambdas(i) * A + B;
  u = u(1:2)/u(3);
  x(i) = u(1);  y(i) = u(2);
end

% display
figure;
imshow(I);
hold on;
patch(x,y,'r');
end


function main(store)
  labels = {'beverages', 'bread', 'cereal', 'cheese', 'counter', 'dairy', 'entrance', 'flowers', 'frozenfood', 'health', 'meat', 'oils', 'pasta', 'snacks', 'vegetables', 'water', 'none'};
  secs = 682;
  fps = 25;
  fpshalf = 12;
  [K, ~, ~] = intrinsiceParams();
  Kinv = inv(K);

  fname = sprintf('labels.txt');
  fid = fopen(fname);
  frame_labels = zeros(secs+1,2);
  line = textscan(fid, '%d:%d %s', 1);
  line_lbls = split(line{3}, ':');
  st = line{1} * 60 + line{2}; pllabel = find(strcmp(labels, line_lbls(1))); prlabel = find(strcmp(labels, line_lbls(2)));
  while true
    line = textscan(fid, '%d:%d %s', 1);
    if ~isempty(line{1})
      line_lbls = split(line{3}, ':');
      et = line{1} * 60 + line{2}; llabel = find(strcmp(labels, line_lbls(1))); rlabel = find(strcmp(labels, line_lbls(2)));
      for i = st:et-1
        frame_labels(i+1,1) = pllabel;
        frame_labels(i+1,2) = prlabel;
      end
      st = et; pllabel = llabel; prlabel = rlabel;
    else
      break
    end
  end
  et = secs;
  for i = st:et
    frame_labels(i+1,1) = pllabel;
    frame_labels(i+1,2) = prlabel;
  end
  fclose(fid);

  sframe = 1;
  label = frame_labels(1,1);
  for j=2:secs+1
    if frame_labels(j,1) != label
      eframe = (j-2)*fps + fpshalf;

      msg = sprintf('Tracking section: %s across frames %d-%d', label, sframe, eframe);
      disp(msg);
      sb = ceil(sframe/200); eb = ceil(eframe/200);
      msg = sprintf('Batches: %d-%d', sb, eb);
      disp(msg);

      % First image with clear view of section
      imgnum1 = input('Enter frame to label section');
      I1 = imread(sprintf('rectification/undistort/image/image%07d.jpg', imgnum1));
      b = ceil(imgnum1/200);
      offset = (b-1)*200;
      [frameIds, Rs, Cs] = readPoses(offset);
      figure;
      imshow(I1);
      [x1,y1] = ginput(4);
      hold on; patch(x1,y1,'r');

      % Second image to compute lambdas
      imgnum2 = input('Enter second frame to get scale');
      I2 = imread(sprintf('rectification/undistort/image/image%07d.jpg', imgnum2));
      figure;
      imshow(I2);
      [x2,y2] = ginput(4);
      hold on; patch(x2,y2,'r');

      % get R, C for both
      for i=1:size(frameIds,1)
        if i==imgnum1-offset
          R1 = reshape(Rs(i,1:3,1:3), [3,3]); C1 = reshape(Cs(i,:), [3,1]);
        elseif i==imgnum2-offset
          R2 = reshape(Rs(i,1:3,1:3), [3,3]); C2 = reshape(Cs(i,:), [3,1]);
        end
      end

      % solve for lambdas
      lambdas = zeros(4,1);
      B = K * R2 * (C1-C2);
      for i=1:4
        A = K * R2 * inv(R1) * Kinv * [ x1(i) y1(i) 1 ]';
        lambdas(i) = (B(1) - B(3)*x2(i)) / (x2(i)*A(3) - A(1));
      end

      pts = [ x1'; y1'; ones(4,1)' ];
      pts = lambdas' .* pts;
      pts = inv(R1) * Kinv * pts + C1;

      ptsw = zeros(eb-sb+1,3,4);
      ptsw(b-sb+1,:,:) = pts;
      % populate down
      for i=1:size(frameIds,1)
        if frameIds(i) <= 30
          n = i;
          Rtrans_prev = reshape(Rs(i,1:3,1:3), [3,3]);  Ctrans_prev = reshape(Cs(i,1:3), [3,1]);
          break;
        end
      end
      for i=b-1:-1:sb
        [f,R,C] = readPoses((i-1)*200);
        for j=1:size(f,1)
          if f(j) == 200+n
            Rtrans_next = reshape(R(j,1:3,1:3), [3,3]);  Ctrans_next = reshape(C(j,1:3), [3,1]);
            ptsw(i-sb+1,:,:) = inv(Rtrans_next) * Rtrans_prev * (reshape(ptsw(i-sb+2,:,:), [3,4]) - Ctrans_prev) + Ctrans_next;
            break;
          end
        end
        for j=1:size(f,1)
          if f(j) <= 30
            n = j;
            Rtrans_prev = reshape(R(j,1:3,1:3), [3,3]);  Ctrans_next = reshape(C(j,1:3), [3,1]);
            break;
          end
        end
      end
      % populate up
      for i=1:size(frameIds,1)
        if frameIds(i) > 200
          n = i-200;
          Rtrans_prev = reshape(Rs(i,1:3,1:3), [3,3]);  Ctrans_prev = reshape(Cs(i,1:3), [3,1]);
          break;
        end
      end
      for i=b+1:eb
        [f,R,C] = readPoses((i-1)*200);
        for j=1:size(f,1)
          if f(j) == n
            Rtrans_next = reshape(R(j,1:3,1:3), [3,3]);  Ctrans_next = reshape(C(j,1:3), [3,1]);
            ptsw(i-sb+1,:,:) = inv(Rtrans_next) * Rtrans_prev * (reshape(ptsw(i-sb,:,:), [3,4]) - Ctrans_prev) + Ctrans_next;
            break;
          end
        end
        for j=1:size(f,1)
          if f(j) > 200
            n = j-200;
            Rtrans_prev = reshape(R(j,1:3,1:3), [3,3]);  Ctrans_next = reshape(C(j,1:3), [3,1]);
            break;
          end
        end
      end

      % finally in shape to track patch
      for frm=sframe:eframe
        if batch != ceil(frm/200)
          batch = ceil(frm/200);
          [fs,Rs,Cs] = readPoses((batch-1)*200);
        end
        for i=1:size(fs,1)
          if fs(i) == sframe
            R = reshape(Rs(i,1:3,1:3), [3,3]);  C = reshape(Cs(i,:), [3,1]);
            u = K * R * reshape(ptsw(batch-sb+1,:,:), [3,4]) - C;
            u = u ./ u(3,:);
            break;
          end
        end
      end

      sframe = eframe+1;
      label = frame_labels(j,1);
    end
  end
  eframe = secs*fps;
end
