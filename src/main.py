import os
import netifaces as ni


if __name__ == '__main__':   
    nic_list = os.listdir('/sys/class/net/')
    nics = []
    for nic in nic_list:
        if 'uesimtun' not in nic:
            continue
        details = ni.ifaddresses(nic)
        if ni.AF_INET in details:
            ip = details[ni.AF_INET][0]['addr']
            nics.append(ip)
    print(nics)