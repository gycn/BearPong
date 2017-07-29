from twisted.internet.protocol import Protocol
from twisted.internet.protocol import Factory
from twisted.internet.endpoints import TCP4ServerEndpoint
from twisted.internet import reactor

class Echo(Protocol):

    def __init__(self, factory):
        self.factory = factory
        self.opcodes = {
            '0x00': self.update_user
            '0x01': self.select_object
            '0x02': self.man_object
            '0x10': self.update_object
        }
        self.objects

    def read_opcode(self, data):
        return data[0]

    def update_user(self):

    def man_object(self):

    def update_object(self):



    def connectionMade(self):
        self.factory.numProtocols = self.factory.numProtocols + 1
        self.transport.write("New connection".encode())

    def connectionLost(self, reason):
        self.factory.numProtocols = self.factory.numProtocols - 1

    def dataReceived(self, data):
        self.transport.write(data)
        print(data)


class EchoFactory(Factory):
    def __init__(self):
        self.numProtocols = 0

    def buildProtocol(self, addr):
        return Echo(self)

# 8007 is the port you want to run under. Choose something >1024
endpoint = TCP4ServerEndpoint(reactor, 8007)
endpoint.listen(EchoFactory())
reactor.run()
