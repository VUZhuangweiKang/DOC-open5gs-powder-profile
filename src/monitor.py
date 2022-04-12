import zmq
import sys
import time


def main(num_ue):
    context = zmq.Context()
    socket = context.socket(zmq.REP)
    socket.bind("tcp://*:5555")
    
    ue_dict = {}
    start = time.time()
    while True:
        msg = socket.recv_json()
        if msg['ue'] not in ue_dict:
            ue_dict.update({'ue%d' % msg['ue']: msg})
        else:
            ue_dict['ue%d' % msg['ue']] = msg
        if len(ue_dict) == num_ue:
            nums = [ue_dict[x]['num'] for x in ue_dict]
            flag = True
            for i in range(1, len(nums)):
                flag = flag and (abs(nums[0]-nums[i]) < 1e-6)
            if flag:
                socket.send_json({'done': True})
                with open('/local/repository/src/results.csv', 'a') as f:
                    f.write('%d,%f\n' % (num_ue, time.time()-start))
                return
        socket.send_json({'done': False})


if __name__ == '__main__':
    num_ue = int(sys.argv[1])
    main(num_ue)