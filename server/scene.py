import user, ar_object
import numpy as np

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
            self.user_count++
            user.set_id(self.user_count)

    def generate_object_id(self, obj):
        if obj.id:
            return
        else:
            self.object_count++
            obj.set_id(self.object_count)

    def new_user(self, protocol):
        # instantiate with zeros for direction/position
        new = user.User(np.zeros((1,3)), np.zeros((1,3)), protocol)
        self.add_user(new)
        assert new.id, 'New User must have an ID'
        return new

    def add_user(self, user):
        if user in self.users:
            raise Exception('User already exists!')
        else:
            self.generate_user_id(user)
            self.users[user.id] = user

    def get_user(self, idx):
        return self.users[idx]

    def get_obj(self, idx):
        return self.objects[idx]

    def remove_user(self, user):
        assert user.id in self.users, 'User does not exist'
        del self.users[user.id]

    def remove_obj(self, obj):
        assert obj.id in self.objects, 'Object does not exist'
        del self.objects[obj.id]

    # def new_object(self, protocol):
    #     # instantiate with zeros for direction/position
    #     new = ar_object.AR_Object(np.zeros((1,3)), np.zeros((1,3)), protocol)
    #     self.add_object(new)
    #     assert new.id, 'New User must have an ID'
    #     return new
    #
    # def add_object(self, obj):
    #     if obj in self.obj:
    #         raise Exception('Object already exists!')
    #     else:
    #         self.generate_user_id(user)
    #         self.users[user.id] = user
