import time
import zmq
from threading import Lock


class UE:
    def __init__(self, ueid, addr, port, peer_addr, peer_port, monitor_addr,
                 init_num, msg_size, pro_time) -> None:
        self.ueid = ueid
        self.addr = addr
        self.port = port
        self.peer_addr = peer_addr
        self.peer_port = peer_port
        self.monitor_addr = monitor_addr

        self.mtx1 = Lock()
        self.mtx2 = Lock()    
        self.num = init_num
        self.msg_size = msg_size
        self.pro_time = pro_time

        self.done = False
        
    def sender(self):
        context = zmq.Context()
        socket = context.socket(zmq.REQ)
        socket.connect("tcp://%s:%d" % (self.peer_addr, self.peer_port))
        while True:
            with self.mtx1.acquire():
                if self.done:
                    break
            with self.mtx2.acquire():
                msg = {
                    'send_time': time.time(),
                    'number': self.num,
                    'payload': [0]*(self.msg_size/4)
                }
                socket.send_json(msg)
                socket.recv()

        
    def receiver(self):
        context = zmq.Context()
        socket1 = context.socket(zmq.REP)
        socket1.bind("tcp://%s:%d" % (self.addr, self.port))
        
        socket2 = context.socket(zmq.REQ)
        socket2.connect("tcp://%s:5555" % (self.monitor_addr))
        while True:
            msg = socket1.recv_json()
            with self.mtx2.acquire():
                self.num = (self.num + msg['number'])/2
                socket1.send(b"ack")
                # simulate internal processing
                time.sleep(self.pro_time)
                socket2.send_json({
                    'ue': self.ueid,
                    'num': self.num,
                    'time': time.time()
                })
                ack = socket2.recv_json()
                if ack['done']:
                    with self.mtx1.acquire():
                        self.done = ack['done']
                        break