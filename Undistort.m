function im_undistorted = Undistort(im, R, C)
%% Prep
im = double(im);

% Intrinsic params
fx = 562.89536;
fy = 557.29656;
px = 630.7712;
py = 363.16152;
omega = 1.03815;
slant = 0;
tan_omega_half_2 = 2 * tan(omega/2);
K = [ fx slant px; 0 fy py; 0 0 1 ];


[u_x, u_y] = meshgrid(1:(size(im,2)), 1:(size(im,1)));
h = size(u_x, 1); w = size(u_x,2);


%% Step: distort meshgrid
u_n = (u_x - px) / fx;
v_n = (u_y - py) / fy;

r_u = sqrt(u_n.^2 + v_n.^2);
r_d = 1/omega * atan(r_u * tan_omega_half_2);

u_dn = r_d./r_u .* u_n;
v_dn = r_d./r_u .* v_n;

u_d = fx*u_dn + px;
v_d = fy*v_dn + py;

im_mod(:,:,1) = reshape(interp2(im(:,:,1), u_d(:), v_d(:)), [h, w]);
im_mod(:,:,2) = reshape(interp2(im(:,:,2), u_d(:), v_d(:)), [h, w]);
im_mod(:,:,3) = reshape(interp2(im(:,:,3), u_d(:), v_d(:)), [h, w]);

im_undistorted = uint8(im_mod);
