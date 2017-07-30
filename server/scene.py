import user, ar_object
import numpy as np
from packet_codes import *
class Scene:
    def __init__(self):
        self.objects = {} 
        self.users = {}
        self.user_count = 0
        self.object_count = 0

    def generate_user_id(self, user):
        if user.id:
            return
        else:
            self.user_count+=1
            user.set_id(self.user_count)

    def generate_object_id(self, obj):
        if obj.id:
            return
        else:
            self.object_count+=1
            obj.set_id(self.object_count)

    def new_user(self, protocol):
        # instantiate with zeros for direction/position
        new = user.User(np.zeros((3)), np.zeros((3)), protocol)
        self.add_user(new)
        assert new.id, 'New User must have an ID'
        return new

    def add_user(self, user):
        if user.id in self.users:
            raise Exception('User already exists!')
        else:
            self.generate_user_id(user)
            print('ADDING USER ID: {}'.format(user.id))
            self.users[user.id] = user

    def get_user(self, idx):
        return self.users[idx]

    def get_obj(self, idx):
        return self.objects[idx]

    def remove_user(self, user):
        print('REMOVING USER ID: {}'.format(user.id))
        assert user.id in self.users, 'User does not exist'
        del self.users[user.id]

    def remove_obj(self, obj):
        assert obj.id in self.objects, 'Object does not exist'
        del self.objects[obj.id]
    
    def main_loop(self):
        raise NotImplemented('Implement this')

    def on_implementation_specific_message(self, msg):
        raise NotImplemented
    # def new_object(self, protocol):
    #     # instantiate with zeros for direction/position
    #     new = ar_object.AR_Object(np.zeros((1,3)), np.zeros((1,3)), protocol)
    #     self.add_object(new)
    #     assert new.id, 'New User must have an ID'
    #     return new
    #
    def add_object(self, obj):
        if obj.id in self.objects:
            raise Exception('Object already exists!')
        else:
            self.generate_object_id(obj)
            self.objects[obj.id] = obj
            
    def send_message_to_all_users(self, msg):
        for user in self.users:
            self.user.protocol.write(msg)

    def send_object_updates(self):
        for key, obj in self.objects:
            position_bytes = b''
            for i in range(3):
                position_bytes += bytearray(struct.pack("f", obj.position[i])) 

            direction_bytes = b''
            for i in range(3):
                direction_bytes += bytearray(struct.pack("f", obj.direction[i])) 

            velocity_bytes = b''
            for i in range(3):
                velocity_bytes += bytearray(struct.pack("f", obj.velocity[i])) 
            
            packet = UPDATE_OBJECT_SPATIAL_INFORMATION_OPCODE + bytes(key) + position_bytes + direction_bytes + velocity_bytes  
            self.send_message_to_all_users(packet)
