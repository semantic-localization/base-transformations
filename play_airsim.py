import os, shutil
import ipdb
import pprint

import numpy as np
from pyquaternion import Quaternion
import airsim


pp = pprint.PrettyPrinter(indent=4)

client = airsim.VehicleClient()
client.confirmConnection()
client.setCameraOrientation("0", airsim.to_quaternion(0.261799, 0, 0))

# start: -0.819394	-10.182267	0.390382	0.784631	-0.011836	-0.014987	-0.619669
start_pos = np.array([ -0.819394, -10.182267, 0.390382])
start_quat = Quaternion(0.784631, -0.011836, -0.014987, -0.619669)

# end: -0.080746	-13.836859	0.538766	0.510454	-0.016421	-0.009750	-0.859693
end_pos = np.array([ -0.080746, -13.836859, 0.538766 ])
end_quat = Quaternion(0.510454, -0.016421, -0.009750, -0.859693)

# number of intermediate points
N = 50

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
    x,y,z = pos[i,:]
    qw,qx,qy,qz = q.elements
    print(i,x,y,z,qw,qx,qy,qz)

    client.simSetVehiclePose(airsim.Pose(airsim.Vector3r(x,y,z), airsim.Quaternionr(qw,qx,qy,qz)), True)

    responses = client.simGetImages([
        airsim.ImageRequest("0", airsim.ImageType.Scene),
        airsim.ImageRequest("0", airsim.ImageType.DepthPerspective, True)
        ])

    for j, response in enumerate(responses):
        if response.pixels_as_float:
            # call pfm saver
        else:
            # call png saver
