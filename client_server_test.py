import socket
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

s.bind((socket.gethostname(), 8007))

serversocket.listen(5)

(clientsocket, address) = serversocket.accept()

clientsocket.recv(40)

clientsocket.send('hi'.encode())

