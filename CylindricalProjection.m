function im_rectified = CylindricalProjection(im, H)
%% Prep
im = double(im);
% Refer calib_fisheye_zshade.txt
fx = 562.89536;
fy = 557.29656;
px = 630.7712;
py = 363.16152;
omega = 1.03815;
slant = 0;
tan_omega_half_2 = 2 * tan(omega/2);
K = [ fx slant px; 0 fy py; 0 0 1 ];


%% PLAN : Original -> Undistort -> Homography -> Distort -> Final
%% Since Ops are inverse => Ops : Distort -> inv(H) -> Undistort
%% One go : meshgrid -> inv(H) -> distort -> interpolate


[u_x, u_y] = meshgrid(1:(size(im,2)), 1:(size(im,1)));
h = size(u_x, 1); w = size(u_x,2);


%% Step 1 : inverse cylinder
% u' = cot(phi)
phi = fliplr(((u_x)/1280) * pi);
u_x = cot(phi);

% v' = (h-H/2) / fx * sin(phi)
u_y = (u_y - 360)./(fx * sin(phi));

% for a panoramic projection, you need R; not ow
% H = K * R;

c_x = K(1,1)*u_x + K(1,2)*u_y + K(1,3);
c_y = K(2,1)*u_x + K(2,2)*u_y + K(2,3);
c_z = K(3,1)*u_x + K(3,2)*u_y + K(3,3);

c_x = c_x./c_z;
c_y = c_y./c_z;


%% Step 2 : inverse Homo
H = inv(H);

h_x = H(1,1)*c_x + H(1,2)*c_y + H(1,3);
h_y = H(2,1)*c_x + H(2,2)*c_y + H(2,3);
h_z = H(3,1)*c_x + H(3,2)*c_y + H(3,3);

h_x = h_x./h_z;
h_y = h_y./h_z;


%% Step 3: distort meshgrid
u_n = (h_x - px) / fx;
v_n = (h_y - py) / fy;

r_u = sqrt(u_n.^2 + v_n.^2);
r_d = 1/omega * atan(r_u * tan_omega_half_2);

u_dn = r_d./r_u .* u_n;
v_dn = r_d./r_u .* v_n;

u_d = fx*u_dn + px;
v_d = fy*v_dn + py;

im_warped(:,:,1) = reshape(interp2(im(:,:,1), u_d(:), v_d(:)), [h, w]);
im_warped(:,:,2) = reshape(interp2(im(:,:,2), u_d(:), v_d(:)), [h, w]);
im_warped(:,:,3) = reshape(interp2(im(:,:,3), u_d(:), v_d(:)), [h, w]);

im_rectified = uint8(im_warped);
