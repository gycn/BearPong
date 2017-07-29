import numpy as np
from scene import Scene
from user import User
from ar_object import AR_Object

class PongBall(AR_Object):
  def __init__(self, position, direction):
    AR_Object.__init__(self, position, direction)
    

class BearPongScene(Scene):
  def __init__(self):
    Scene.__init__(self)
    self.objects
