import sys, os
import time
import zmq
from threading import Thread, Lock
import argparse


class UE:
    def __init__(self, **kwargs) -> None:
        self.ueid = kwargs['id']
        self.monitor_addr = kwargs['monitor_addr']
        self.addr = kwargs['addr']
        self.port = kwargs['port']
        self.peer_addr = kwargs['peer_addr']
        self.peer_port = kwargs['peer_port']
        self.msg_size = kwargs['msg_size']
        self.pro_time = float(kwargs['pro_time']/1000)
        
        self.mtx = Lock()
        self.num = float(self.ueid)
        
    def sender(self):
        context = zmq.Context()
        socket = context.socket(zmq.REQ)
        # print("tcp://%s:%d" % (self.peer_addr, self.peer_port))
        socket.connect("tcp://%s:%d" % (self.peer_addr, self.peer_port))
        while True:
            with self.mtx:
                msg = {
                    'send_time': time.time(),
                    'number': self.num,
                    'payload': [0]*(self.msg_size//4)
                }
                socket.send_json(msg)
            # print('send: ', msg)
            socket.recv()
            # simulate internal processing
            time.sleep(self.pro_time)
        
    def receiver(self):
        # print("tcp://%s:%d" % (self.addr, self.port))
        context = zmq.Context()
        socket = context.socket(zmq.REP)
        socket.bind("tcp://%s:%d" % (self.addr, self.port))
        while True:
            msg = socket.recv_json()
            # print('rcv: ', msg)
            with self.mtx:
                self.num = (self.num + msg['number'])/2
            socket.send(b"ack")
                
    def reporter(self):
        context = zmq.Context()
        socket = context.socket(zmq.REQ)
        socket.connect("tcp://%s:5555" % (self.monitor_addr))
        while True:
            with self.mtx:
                socket.send_json({
                    'ue': self.ueid,
                    'num': self.num,
                    'time': time.time()
                })
            ack = socket.recv_json()
            if ack['done']:
                break
        # print('reporter exit')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--id', type=int)
    parser.add_argument('--monitor_addr', type=str)
    parser.add_argument('-a', '--addr', type=str)
    parser.add_argument('-p', '--port', type=int)
    parser.add_argument('--peer_addr', type=str)
    parser.add_argument('--peer_port', type=int)
    parser.add_argument('--msg_size', default=64, type=int)
    parser.add_argument('--pro_time', default=500, type=float, help='default internal processing time in ms')
    args = parser.parse_args()
    
    kwargs = {}
    for item in args._get_kwargs():
        kwargs.update({item[0]: item[1]})
    ue = UE(**kwargs)
    recv_thr = Thread(target=ue.receiver, daemon=True)
    send_thr = Thread(target=ue.sender, daemon=True)
    recv_thr.start()
    send_thr.start()
    ue.reporter()
    sys.exit()