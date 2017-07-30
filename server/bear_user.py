from user import User

class BearUser(User):
    def __init__(self, position, direction, protocol):
        User.__init__(self, position, direction, protocol)
        self.game_start = False

