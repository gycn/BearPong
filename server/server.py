from twisted.internet.protocol import Protocol
from twisted.internet.protocol import Factory
from twisted.internet.endpoints import TCP4ServerEndpoint
from twisted.internet import reactor
from twisted.internet.task import LoopingCall

import struct
from scene import Scene

UPDATE_USER_SPATIAL_INFORMATION_OPCODE = 0x00
SELECT_OBJECT_OPCODE = 0x01

UPDATE_OBJECT_SPATIAL_INFORMATION_OPCODE = 0x10
SEND_USER_ID_OPCODE = 0x11
SELECT_OBJECT_RESPONSE_OPCODE = 0x12

SEND_IMPLEMENTATION_SPECIFIC_MESSAGE = 0xFF 
def get_opcode(bytes_in):
    return bytes_in[0]

def convert_bytes_to_int(byte_string):
    return int.from_bytes(b, byteorder='big', signed=False)

def convert_bytes_to_float(byte_string):
    return struct.unpack('f', byte_string)[0]

class ARWebServerProtocol(Protocol):

    def __init__(self, factory, addr, scene):
        self.factory = factory
        self.addr = addr
        self.scene = scene
        self.user = None
        self.OPCODE_FUNCTIONS = {
          UPDATE_USER_SPATIAL_INFORMATION_OPCODE: self.handle_new_user_spatial_information,
          SELECT_OBJECT_OPCODE: self.handle_object_selection,
          SEND_IMPLEMENTATION_SPECIFIC_MESSAGE: self.handle_implementation_specific_message
        }

    def connectionMade(self):
        self.factory.numProtocols = self.factory.numProtocols + 1
        print('New Connection')
        
        #Add new user to scene
        self.user = self.scene.new_user(self)
        #User creation was not successful
        if user.id == 0xFFFFFFFF:
            self.loseConnection()
        #User creation successful
        else:
          #Send user id back
          self.transport.write(bytearray([SEND_USER_ID_OPCODE, self.user.id]))

    def connectionLost(self, reason):
        self.factory.numProtocols = self.factory.numProtocols - 1
        self.scene.remove_user(self.user)

    def dataReceived(self, data):
        opcode = get_opcode(data)
        if (opcode in self.OPCODE_FUNCTIONS):
          self.OPCODE_FUNCTIONS[opcode](data)
        else:
          print('invalid command')

    def handle_new_user_spatial_information(self, data):
        new_position = np.array([convert_bytes_to_float(data[i:i + 4]) for i in range(1, 13, 4)]) 
        new_direction = np.array([convert_bytes_to_float(data[i:i + 4]) for i in range(13, 25, 4)]) 
        print(new_position, new_direction)
        self.user.on_new_user_spatial_information(new_position, new_direction)

    def handle_object_selection(self, data):
        object_id = convert_bytes_to_int(data[1:5])
        print(data[1:5])
        print(object_id)
        success = self.scene.get_object(object_id).on_object_select(user)
        self.transport.write(bytearray([SELECT_OBJECT_RESPONSE_OPCODE, success]))
    
    def handle_implementation_specific_message(self, data):
        self.scene.on_implementation_specific_message(data[1:])

class ARWebServerFactory(Factory):

    def __init__(self, scene):
        self.numProtocols = 0
        
        #Scene contains the user and object information
        self.scene = scene 

    def buildProtocol(self, addr):
        return ARWebServerProtocol(self, addr, self.scene)

class ARServer:
    def __init__(self, scene, port, main_loop_interval = 0.017):
        self.endpoint = TCP4ServerEndpoint(reactor, port)
        self.endpoint.listen(ARWebServerFactory(scene))
        self.main_loop = LoopingCall(scene.main_loop)
        self.main_loop_interval = main_loop_interval

    def start(self):
        #self.main_loop.start(self.main_loop_interval)
        reactor.run()


if __name__ == '__main__':
    scene = Scene()
    server = ARServer(scene, 8007)
    server.start()
