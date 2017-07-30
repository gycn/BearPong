import numpy as np
from scene import Scene
from bear_user import BearUser
from ar_object import AR_Object

GAME_START = b'\x11'
GAME_END = b'\xFF'
FIRST_PLAYER = b'\x00'

class PongBall(AR_Object):
    def __init__(self, position, direction, velocity):
        AR_Object.__init__(self, position, direction, velocity)


class BearPongScene(Scene):
    def __init__(self, radius = 1, dt = 0.017):
        Scene.__init__(self)
        self.ball = PongBall(np.zeros(3), np.zeros(3), np.zeros(3))
        self.add_object(self.ball)
        self.scores = [0,0]
        self.started = False
        self.turn = 0 if np.random.rand() > 0.5 else 1
        self.radius = radius
        self.dt = dt
        self.sent_turn_start = False
        self.velocity = None

    def new_user(self, protocol):
        if self.user_count == 2:
            # If 2 users already exist, disconnect all further users
            temp = BearUser(0, 0, 0)
            temp.id = 0xFFFFFFFF
            return temp
        # Overwrite to accomadate Bear Users
        new = BearUser(np.zeros((3)), np.zeros((3)), protocol)
        self.add_user(new)
        assert new.id, 'New User must have an ID'
        return new

    def ball_out_of_bounds(self, epsilon=0.01):
        # check if ball is out of lateral bounds; ignores z-direction
        return np.linalg.norm(self.objects[0].position[:2]) >= epsilon + self.radius

    def game_end(self):
        self.started = False
        self.send_message_to_all_users(GAME_END + bytes(1 - self.turn))

    def user_dist_to_ball(self):
        # distance from user to ball
        dist = self.users[self.turn].position - self.objects[0].position
        return np.linalg.norm(dist)

    def update_ball_position(self, ceiling = 2, floor = 0):
        # handle case where ball continues in straight trajectory
        ball = self.objects[0]
        newPos = ball.velocity * self.dt + ball.position
        ball.position = newPos
        if ball.position[2] >= ceiling:
            ball.position[2] = ceiling
            ball.velocity[2] = - ball.velocity
        elif ball.position[2] <= floor:
            ball.position[2] = floor
            ball.velocity[2] = - ball.velocity

    def update_ball_bounce(self):
        # handle case where user hits the ball
        ball = self.objects[0]
        ball_vel = ball.velocity
        ball.velocity = ball_vel - 2 * np.dot(ball_vel, self.users[self.turn].direction) * self.users[self.turn].direction

    def main_loop(self):
        if self.started:
            # check ball position, if user near -> ball bounce, if ball outside bounds -> point
            if self.ball_out_of_bounds():
                self.game_end()
            # check user positions
            if self.user_dist_to_ball() > 0.01:
                self.update_ball_position()
            else:
                self.update_ball_bounce()
        else:
            if not self.sent_turn_start and self.user_count == 2:
                self.sent_turn_start = True
                self.send_message_to_all_users(FIRST_PLAYER + bytes(self.turn))
            if all([u.game_start for u in self.users]):
                self.started = True
                v = np.linalg.norm(self.users[1 - self.turn].position - self.users[self.turn].position) / 2
                self.objects[0].velocity = v
