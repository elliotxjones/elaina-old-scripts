import serial
import time

class SerialSession:
    def __init__(self, com_port, com_speed):
        self.com_port = com_port
        self.com_speed = com_speed
        self.session = serial.Serial(self.com_port, self.com_speed, timeout=1)
    def readline(self):
        line = self.session.readline()

        return line
    def readlines(self):
        lines = self.session.readlines()

        return lines
    def write(self, payload):
        self.session.write(payload)

        return None
    def close(self):
        self.session.close()
        self.session = None

        return None
    def try_login(self, user, password):
        if not password:
            password = ""
    
        print("Refreshing serial prompt")
        self.session.write(b"\n")
        time.sleep(0.5)
        prompt = self.session.readlines()

        if not prompt:
            return False

        # for l in prompt:
        #     print(l.decode()[:-1])

        # if "login:" in prompt[-1].decode().lower():
        if b"login:" in prompt[-1]:
            print("Caught login prompt")
            print(f"Attempting credentials for {user}")

            self.session.write(f"{user}\n".encode())
            time.sleep(0.5)
            self.session.write(f"{password}\n".encode())
        # elif "password:" in prompt[-1].decode().lower():
        elif b"password:" in prompt[-1]:
            print("Missed login prompt")
            print("Retrying login")
            # Not likely to occur.
            self.session.write(b"\03c\n")
            time.sleep(5)
            print(f"Attempting credentials for {user}")
            self.session.write(f"{user}\n".encode())
            time.sleep(0.5)
            self.session.write(f"{password}\n".encode())
        else:
            # Assume logged in.
            print("No login prompt. Already logged in")
            print("Verifying login credentials")

            self.session.write(b"logout\n")
            time.sleep(2)
            self.session.write(f"{user}\n".encode())
            time.sleep(0.5)
            self.session.write(f"{password}\n".encode())

        # time.sleep(5)

        hang_time = 0
        line = self.session.readline()

        while not any([
            hang_time < 60,
            f"{user}@".encode() in line,
        ]):
            line = self.session.readline()
            hang_time += 1
            # if "login incorrect" in line.decode().lower():
            if b"login incorrect" in line:
                # print(line.decode()[:-1])
                print(f"Invalid credentials for {user}")
                return False
            elif line:
                hang_time = 0
                # print(line.decode()[:-1])

        if any([
            not line,
            line == b'',
        ]):
            print(f"An unknown error occured")
            return False
        
        print(f"Sanity checking user is {user}")
        self.session.write(b"whoami\n")
        time.sleep(0.5)
        prompt = self.session.readlines()
        # for l in prompt:
        #     print(l.decode()[:-1])
        # if user in prompt[-2].decode().lower():
        if user.encode() in prompt[-2]:
            # TODO: debug
            print(f"Successful login for {user}")
            return True
        
        print(f"Unexpected response from OS")

        return False
    

    def try_reboot(self):
        self.session.write(b"reboot\n")
        print("System rebooting...\n")
        
        hang_time = 0
        line = self.session.readline()

        while hang_time < 60:
            if line:
                hang_time = 0
                # Escape byte order marks
                #if b"\xfe" in line:
                #    line = line.replace(b"\xfe",b"\\xfe")
                #if b"\xe8" in line:
                #    line = line.replace(b"\xe8",b"\\xe8")
                #try:
                #    print(line.decode()[:-1])


                #if "login:" in line.decode().lower():
                if b"login:" in line:
                    self.session.write(b"\n")
                    time.sleep(0.5)
                    line = self.session.readlines()[-1]
                    if any([
                        b"login:" in line,
                        b"password:" in line,
                    ]):
                        print("Caught login prompt")
                        return True
                line = self.session.readline()
            else:
                hang_time += 1
                if hang_time == 5:
                    print("Recieving platform boot output...")
                elif hang_time == 30:
                    print(f"No response after {hang_time} seconds ({hang_time}/60)")
                elif all([
                    hang_time > 30,
                    hang_time % 5 == 0,
                ]):
                    print(f"No response after {hang_time} seconds ({hang_time}/60)")
                    
                line = self.session.readline()

        print("\nTimeout response from system")
        print("Final system state check")
        self.session.write(b"\n")
        time.sleep(0.5)
        lines = self.session.readlines()
    
        for l in lines:
            if any([
                b"login:" in l,
                b"password" in l,
            ]):
                print("Caught login prompt (prompt missed)")
                return True

        return False

