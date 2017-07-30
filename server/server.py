from twisted.internet.protocol import Protocol
from twisted.internet.protocol import Factory
from twisted.internet.endpoints import TCP4ServerEndpoint
from twisted.internet import reactor
from twisted.internet.task import LoopingCall

import numpy as np
import struct

import packet_codes


def get_opcode(bytes_in):
    return bytes_in[0]

def convert_bytes_to_int(byte_string):
    return int.from_bytes(byte_string, byteorder='big', signed=False)

def convert_bytes_to_float(byte_string):
    return struct.unpack('f', byte_string)[0]

class ARWebServerProtocol(Protocol):

    def __init__(self, factory, addr, scene):
        self.factory = factory
        self.addr = addr
        self.scene = scene
        self.user = None
        self.OPCODE_FUNCTIONS = {
          packet_codes.UPDATE_USER_SPATIAL_INFORMATION_OPCODE: self.handle_new_user_spatial_information,
          #packet_codes.SELECT_OBJECT_OPCODE: self.handle_object_selection,
          packet_codes.SEND_IMPLEMENTATION_SPECIFIC_MESSAGE: self.handle_implementation_specific_message
        }

    def connectionMade(self):
        self.factory.numProtocols = self.factory.numProtocols + 1
        print('New Connection')
        
        #Add new user to scene
        self.user = self.scene.new_user(self)
        #User creation was not successful
        if self.user.id == 0xFFFFFFFF:
            self.loseConnection()
        #User creation successful
        else:
          #Send user id back
          self.transport.write(bytearray([packet_codes.SEND_USER_ID_OPCODE, self.user.id]))

    def connectionLost(self, reason):
        #remove user from scene upon disconnect
        self.scene.remove_user(self.user)

    def dataReceived(self, data):
        while (len(data) > 0):
          opcode = get_opcode(data)
          if (opcode in self.OPCODE_FUNCTIONS):
            #Get next packet length
            if opcode in packet_codes.COMMAND_LENGTHS:
              packet_length = packet_codes.COMMAND_LENGTHS[opcode]
              self.OPCODE_FUNCTIONS[opcode](data[:packet_length + 1])
              data = data[packet_length + 1:]
            else:
              packet_length = data[1] 
              self.OPCODE_FUNCTIONS[opcode](data[2:packet_length + 2])
              data = data[packet_length + 2:]
          else:
            print('invalid command')

    def handle_new_user_spatial_information(self, data):
        new_position = np.array([convert_bytes_to_float(data[i:i + 4]) for i in range(1, 13, 4)]) 
        new_direction = np.array([convert_bytes_to_float(data[i:i + 4]) for i in range(13, 25, 4)]) 
        print('New User Spatial Information: {} {}'.format(new_position, new_direction))
        self.user.on_new_user_spatial_information(new_position, new_direction)

    def handle_object_selection(self, data):
        object_id = convert_bytes_to_int(data[1:5])
        print(data[1:5])
        print(object_id)
        success = self.scene.get_object(object_id).on_object_select(user)
        self.transport.write(bytearray([packet_codes.SELECT_OBJECT_RESPONSE_OPCODE, success]))
    
    def handle_implementation_specific_message(self, data):
        self.user.on_implementation_specific_message(data)

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
        self.scene = scene
        self.main_loop_interval = main_loop_interval
    
    def main_loop(self):
        #self.scene.main_loop()
        self.scene.send_object_updates()

    def start(self):
        loop = LoopingCall(self.main_loop)
        loop.start(self.main_loop_interval)
        reactor.run()


if __name__ == '__main__':
    scene = Scene()
    server = ARServer(scene, 8007)
    server.start()
