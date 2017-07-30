class User:
    def __init__(self, position, direction, protocol):
        self.direction = direction
        self.position = position
        self.id = None
        self.protocol = protocol 

    def on_user_update(self):
        raise NotImplementedError()

    def set_id(self, i):
        if self.id:
            raise Exception('This object already has an ID')
        self.id = i

    def __eq__(self, other):
        if not isinstance(other, User):
            return False
        else:
            return self.id == other.id or self.protocol.addr == other.protocol.addr

    def on_new_user_spatial_information(self, newPos, newDir):
        self.position = newPos
        self.direction = newDir

    def on_implementation_specific_message(self, msg):
        raise NotImplemented()
