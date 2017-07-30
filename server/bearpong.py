import numpy as np
from scene import Scene
from user import User
from ar_object import AR_Object

GAME_START = b'\x11'
GAME_END = b'\xFF'
FIRST_PLAYER = b'\x00'

class PongBall(AR_Object):
    def __init__(self, position, direction):
        AR_Object.__init__(position, direction)
    

class BearPongScene(Scene):
    def __init__(self, radius = 1, dt = 0.017):
        Scene.__init__()
        self.add_object(PongBall())
        self.scores = [0,0]
        self.started = False
        self.turn = 0 if np.rand() > 0.5 else 1
        self.radius = radius
        self.dt = dt
        self.sent_turn_start = False
        self.velocity = None

    def new_user(self, protocol):
        if self.user_count == 2:
            temp = User(0, 0, 0)
            temp.id = 0xFFFFFFFF
            return temp
        return super(Scene, self).new_user(protocol)
    
    def on_implementation_specific_message(self, msg):
        if (msg == GAME_START):
            self.started = True
            self.objects[0].velocity = self.users[1 - turn].position - self.users[turn].position
    
    def ball_out_of_bounds(epsilon=0.01):
        return np.linalg.norm(self.objects[0].position[:2]) >= epsilon + self.radius

    def game_end(self):
        self.started = False
        self.send_message_to_all_users(GAME_END + bytes(1 - self.turn))

    def user_dist_to_ball(self):
        dist = self.users[self.turn].position - self.objects[0].position
        return np.linalg.norm(dist)

    def update_ball_position(self, ceiling = 2, floor = 0):
        ball = self.objects[0]
        newPos = ball.velocity * dt + ball.position
        ball.position = newPos
        if (ball.position[2] >= ceiling):
            ball.position[2] = ceiling
            ball.velocity[2] = - ball.velocity
        elif (ball.position[2] <= floor):
            ball.position[2] = floor
            ball.velocity[2] = - ball.velocity

    def update_ball_bounce(self)::
        ball = self.objects[0]
        ball_vel = ball.velocity
        ball.velocity = ball_vel - 2 * np.dot(ball_vel, self.users[turn].direction) * self.users[turn].direction

    def main_loop(self):
        if (self.started):
            # check ball position, if user near -> ball bounce, if ball outside bounds -> point
            if(ball_out_of_bounds()):
                game_end()
            # check user positions
            if(user_dist_to_ball() > 0.01):
                update_ball_position()
            else:
                update_ball_bounce()
        else:
            if(!self.sent_turn_start && self.user_count == 2):
                self.sent_turn_start = True
                self.send_message_to_all_users(FIRST_PLAYER + bytes(self.turn))

