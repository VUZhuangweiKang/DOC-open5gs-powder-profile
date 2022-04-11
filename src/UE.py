import os,sys
import time
import zmq
from threading import Thread, Lock


class UE:
    def __init__(self, ueid, addr, port, peer_addr, peer_port, monitor_addr,
                 init_num, msg_size, pro_time) -> None:
        self.ueid = int(ueid)
        self.addr = addr
        self.port = int(port)
        self.peer_addr = peer_addr
        self.peer_port = int(peer_port)
        self.monitor_addr = monitor_addr

        self.mtx1 = Lock()
        self.mtx2 = Lock()    
        self.num = float(init_num)
        self.msg_size = int(msg_size)
        self.pro_time = float(int(pro_time))/1000

        self.done = False
        
    def sender(self):
        context = zmq.Context()
        socket = context.socket(zmq.REQ)
        socket.connect("tcp://%s:%d" % (self.peer_addr, self.peer_port))
        while True:
            with self.mtx2:
                msg = {
                    'send_time': time.time(),
                    'number': self.num,
                    'payload': [0]*(self.msg_size//4)
                }
                socket.send_json(msg)
                print('send: ', msg)
            socket.recv()
            with self.mtx1:
                if self.done:
                    break
        socket.close()
        
    def receiver(self):
        context = zmq.Context()
        socket = context.socket(zmq.REP)
        socket.bind("tcp://%s:%d" % (self.addr, self.port))
        while True:
            msg = socket.recv_json()
            print('rcv: ', msg)
            with self.mtx2:
                self.num = (self.num + msg['number'])/2
                socket.send(b"ack")
            # simulate internal processing
            time.sleep(self.pro_time)
            with self.mtx1:
                if self.done:
                    break
        socket.close()
                
    def reporter(self):
        context = zmq.Context()
        socket = context.socket(zmq.REQ)
        socket.connect("tcp://%s:5555" % (self.monitor_addr))
        while True:
            with self.mtx2:
                socket.send_json({
                    'ue': self.ueid,
                    'num': self.num,
                    'time': time.time()
                })
            ack = socket.recv_json()
            print('reporter ack: ', ack)
            if ack['done']:
                with self.mtx1:
                    self.done = True
                    break
        print('reporter exit')
        socket.close()


if __name__ == '__main__':
    args = sys.argv[1:]
    ue = UE(*args)
    recv_thr = Thread(target=ue.receiver)
    sender_thr = Thread(target=ue.sender)
    recv_thr.start()
    sender_thr.start()
    ue.reporter()
    os._exit(1)
    