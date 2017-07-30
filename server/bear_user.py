from user import User

class BearUser:
    def __init__(self, position, direction, protocol):
        User.__init__(position, direction, protocol)
        self.game_start = False

    
