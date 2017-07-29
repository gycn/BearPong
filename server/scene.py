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
        self.add_user(user.User(np.zeros((1,3)), np.zeros((1,3)), protocol))

    def add_user(self, user):
        if user in self.users:
            raise Exception('User already exists!')
        else:
            self.generate_user_id(user)
            self.users[user.id] = user

    def new_object(self, protocol):
        self.add_object(ar_object.AR_Object(np.zeros((1,3)), np.zeros((1,3)), protocol))

    def add_object(self, obj):
        if obj in self.obj:
            raise Exception('Object already exists!')
        else:
            self.generate_user_id(user)
            self.users[user.id] = user
