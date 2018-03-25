function [x y] = undistort(u,v)
  %% Refer calib_fisheye_zshade.txt
  fx = 562.89536;
  fy = 557.29656;
  px = 630.7712;
  py = 363.16152;
  omega = 1.03815;
  slant = 0;
  tan_omega_half_2 = 2 * tan(omega/2);
  K = [ fx slant px; 0 fy py; 0 0 1 ] * eye(3,4);  I = eye(4);

  % Undistort
  u_n = (u - px)/fx;
  v_n = (v - py)/fy;

  r_u = sqrt(u_n^2 + v_n^2);
  r_d = 1/omega * atan(r_u * tan_omega_half_2);

  u_dn = r_d/r_u * u_n;
  v_dn = r_d/r_u * v_n;

  u_d = fx*u_dn + px;
  v_d = fy*v_dn + py;

  x = u_d;
  y = v_d;
end
