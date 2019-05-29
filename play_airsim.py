import os, shutil
import ipdb
import pprint

import numpy as np
from math import cos, sin
from pyquaternion import Quaternion
import airsim


def get_image_and_depth(client, pos, q):
    x,y,z = pos
    qw,qx,qy,qz = q.elements
    client.simSetVehiclePose(airsim.Pose(airsim.Vector3r(x,y,z), airsim.Quaternionr(qx,qy,qz,qw)), True)

    responses = client.simGetImages([
        airsim.ImageRequest("0", airsim.ImageType.Scene),
        airsim.ImageRequest("0", airsim.ImageType.DepthPerspective, True)
        ])
    return responses


def get_image(client, pos, q):
    x,y,z = pos
    qw,qx,qy,qz = q.elements
    client.simSetVehiclePose(airsim.Pose(airsim.Vector3r(x,y,z), airsim.Quaternionr(qx,qy,qz,qw)), True)

    responses = client.simGetImages([
        airsim.ImageRequest("0", airsim.ImageType.Scene),
        ])
    return responses[0]


def record(client, start_pos, end_pos, start_quat, end_quat, N):
    # generate positions
    pos_diff = end_pos - start_pos
    pos_diff = np.repeat(np.reshape(pos_diff, [1,3]), N, 0)
    inc = np.reshape(np.linspace(0, 1, num=N), [N,1])
    pos_diff *= inc
    start_pos = np.repeat(np.reshape(start_pos, [1,3]), N, 0)
    pos = start_pos + pos_diff

    # generate orientations
    qs = Quaternion.intermediates(start_quat, end_quat, N, include_endpoints=False)

    # combine
    for i, q in enumerate(qs):
        print(pos[i,:], q.rotation_matrix)
        responses = get_image_and_depth(client, pos[i,:], q)
        for j, response in enumerate(responses):
            if response.pixels_as_float:
                airsim.write_pfm(os.path.normpath('depth{:07d}.pfm'.format(i+1)), airsim.get_pfm_array(response))
            else:
                airsim.write_file(os.path.normpath('image{:07d}.png'.format(i+1)), response.image_data_uint8)

        R = q.rotation_matrix
        rx = R[1,:]
        ry = -R[2,:]
        rz = -R[0,:]
        def rotm(rx,ry,rz):
            return np.array([-rz, rx, -ry])
        thetas = [10, 20, 30]
        for theta in thetas:
            th = np.radians(theta)
            R = rotm( rx*cos(th) + ry*sin(th),
                     -rx*sin(th) + ry*cos(th),
                      rz )
            response = get_image(client, pos[i,:], Quaternion(matrix=R))
            airsim.write_file(os.path.normpath('image{:07d}_rotz{}.png'.format(i+1, theta)), response.image_data_uint8)

            R = rotm( -rz*sin(th) + rx*cos(th),
                       ry,
                       rz*cos(th) + rx*sin(th) )
            response = get_image(client, pos[i,:], Quaternion(matrix=R))
            airsim.write_file(os.path.normpath('image{:07d}_roty{}.png'.format(i+1, theta)), response.image_data_uint8)

            R = rotm( rx,
                      ry*cos(th) + rz*sin(th),
                     -ry*sin(th) + rz*cos(th) )
            response = get_image(client, pos[i,:], Quaternion(matrix=R))
            airsim.write_file(os.path.normpath('image{:07d}_rotx{}.png'.format(i+1, theta)), response.image_data_uint8)


def record_sequence():
    client = airsim.VehicleClient()
    client.confirmConnection()
    client.setCameraOrientation("0", airsim.to_quaternion(0, 0, 0))

    # start: -0.819394	-10.182267	0.390382	0.784631	-0.011836	-0.014987	-0.619669
    start_pos = np.array([ -0.819394, -10.182267, 0.390382])
    start_quat = Quaternion(0.784631, -0.011836, -0.014987, -0.619669)

    # end: -0.080746	-13.836859	0.538766	0.510454	-0.016421	-0.009750	-0.859693
    end_pos = np.array([ -0.080746, -13.836859, 0.538766 ])
    end_quat = Quaternion(0.510454, -0.016421, -0.009750, -0.859693)

    # number of intermediate points
    N = 100
    record(client, start_pos, end_pos, start_quat, end_quat, N)
