from user import User

GAME_START = b'\x11'

class BearUser(User):
    def __init__(self, position, direction, protocol):
        User.__init__(self, position, direction, protocol)
        self.game_start = False

    def on_implementation_specific_message(self, msg):
        if msg == GAME_START:
            self.game_start = True
