class User:
    def __init__(self, direction, position, protocol):
        self.direction = direction
        self.position = position
        self.id = None
        self.address = address

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
            return self.id == other.id
