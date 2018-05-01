function im_rectified = ImageWarping(im, H)
%% Prep
im = double(im);
% Refer calib_fisheye_zshade.txt
fx = 562.89536;
fy = 557.29656;
px = 630.7712;
py = 363.16152;
omega = 1.03815;
tan_omega_half_2 = 2 * tan(omega/2);


%% PLAN : Original -> Undistort -> Homography -> Distort -> Final
%% Since Ops are inverse => Ops : Distort -> inv(H) -> Undistort


%% Step 1: Undist (distort meshgrid)

[u_x, u_y] = meshgrid(1:(size(im,2)), 1:(size(im,1)));
h = size(u_x, 1); w = size(u_x,2);

u_n = (u_x - px) / fx;
v_n = (u_y - py) / fy;

r_u = sqrt(u_n.^2 + v_n.^2);
r_d = 1/omega * atan(r_u * tan_omega_half_2);

u_dn = r_d./r_u .* u_n;
v_dn = r_d./r_u .* v_n;

u_d = fx*u_dn + px;
v_d = fy*v_dn + py;

im_undistort(:,:,1) = reshape(interp2(im(:,:,1), u_d(:), v_d(:)), [h, w]);
im_undistort(:,:,2) = reshape(interp2(im(:,:,2), u_d(:), v_d(:)), [h, w]);
im_undistort(:,:,3) = reshape(interp2(im(:,:,3), u_d(:), v_d(:)), [h, w]);


%% Step 2 : Homography (inverse Homo meshgrid)
H = inv(H);

[u_x, u_y] = meshgrid(1:(size(im,2)), 1:(size(im,1)));
h = size(u_x, 1); w = size(u_x,2);

v_x = H(1,1)*u_x + H(1,2)*u_y + H(1,3);
v_y = H(2,1)*u_x + H(2,2)*u_y + H(2,3);
v_z = H(3,1)*u_x + H(3,2)*u_y + H(3,3);

v_x = v_x./v_z;
v_y = v_y./v_z;

im_warped(:,:,1) = reshape(interp2(im_undistort(:,:,1), v_x(:), v_y(:)), [h, w]);
im_warped(:,:,2) = reshape(interp2(im_undistort(:,:,2), v_x(:), v_y(:)), [h, w]);
im_warped(:,:,3) = reshape(interp2(im_undistort(:,:,3), v_x(:), v_y(:)), [h, w]);

% im_warped = uint8(im_warped);


%% Step 3 : Distort (undistort meshgrid)
[u_x, u_y] = meshgrid(1:(size(im,2)), 1:(size(im,1)));
h = size(u_x, 1); w = size(u_x,2);

u_dn = (u_x - px) / fx;
v_dn = (u_y - py) / fy;

r_d = sqrt(u_dn .^ 2 + v_dn .^ 2);
r_u = tan(omega * r_d) / tan_omega_half_2;

u_n = (r_u ./ r_d) .* u_dn;
v_n = (r_u ./ r_d) .* v_dn;

v_x = u_n * fx + px;
v_y = v_n * fy + py;

im_final(:,:,1) = reshape(interp2(im_warped(:,:,1), v_x(:), v_y(:)), [h, w]);
im_final(:,:,2) = reshape(interp2(im_warped(:,:,2), v_x(:), v_y(:)), [h, w]);
im_final(:,:,3) = reshape(interp2(im_warped(:,:,3), v_x(:), v_y(:)), [h, w]);

im_rectified = uint8(im_final);
