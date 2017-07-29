class AR_Object:
    def __init__(self, direction, position, protocol):
        self.direction = direction
        self.position = position
        self.protocol = protocol
        self.id = None
        self.lock = False

    def set_id(self, i):
        if self.id:
            raise Exception('This object already has an ID')
        self.id = i

    def __eq__(self, other):
        if not isinstance(other, AR_Object):
            return False
        else:
            return self.id == other.id

    def on_object_selection_received(self):
        raise NotImplementedError()

    def on_select(self,user):
        raise NotImplementedError()

    # def on_object_manipulation_received(self):
    #     raise NotImplementedError()
