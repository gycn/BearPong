from twisted.internet.protocol import Protocol
from twisted.internet.protocol import Factory
from twisted.internet.endpoints import TCP4ServerEndpoint
from twisted.internet import reactor
from twisted.internet.task import LoopingCall
import struct

UPDATE_USER_SPATIAL_INFORMATION_OPCODE = 0x00
SELECT_OBJECT_OPCODE = 0x01

UPDATE_OBJECT_SPATIAL_INFORMATION_OPCODE = 0x10
SEND_USER_ID_OPCODE = 0x11
SELECT_OBJECT_RESPONSE_OPCODE = 0x12

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
          SELECT_OBJECT_OPCODE: self.handle_object_selection
        }

    def connectionMade(self):
        self.factory.numProtocols = self.factory.numProtocols + 1
        print('New Connection')
        
        ##Add new user to scene
        #self.user = self.scene.new_user(self)
        ##Send user id back
        #self.transport.send(bytearray([SEND_USER_ID_OPCODE, self.user.id]))

    def connectionLost(self, reason):
        self.factory.numProtocols = self.factory.numProtocols - 1
        #self.scene.remove_user(user)

    def dataReceived(self, data):
        opcode = get_opcode(data)
        if (opcode in self.OPCODE_FUNCTIONS):
          self.OPCODE_FUNCTIONS[opcode](data)
        else:
          print('invalid command')

    def handle_new_user_spatial_information(self, data):
        new_position = [convert_bytes_to_float(data[i:i + 4]) for i in range(1, 13, 4)] 
        new_direction = [convert_bytes_to_float(data[i:i + 4]) for i in range(13, 25, 4)] 
        print(new_position, new_direction)
        #self.user.on_new_user_spatial_information(new_position, new_direction)

    def handle_object_selection(self, data):
        object_id = convert_bytes_to_int(data[1:5])
        print(data[1:5])
        print(object_id)
    #    success = self.scene.get_object(object_id).on_object_select(user)
    #    self.transport.send(bytearray([SELECT_OBJECT_RESPONSE_OPCODE, success]))

class ARWebServerFactory(Factory):

    def __init__(self, scene):
        self.numProtocols = 0
        
        #Scene contains the user and object information
        self.scene = scene 

    def buildProtocol(self, addr):
        return ARWebServerProtocol(self, addr, self.scene)

if __name__ == '__main__':
    # 8007 is the port you want to run under. Choose something >1024
    endpoint = TCP4ServerEndpoint(reactor, 8007)
    endpoint.listen(ARWebServerFactory(None))
    reactor.run()
