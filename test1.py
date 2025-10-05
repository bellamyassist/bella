import socket
try:
    print(socket.getaddrinfo('api.fyers.in', 443))
    print(socket.getaddrinfo('rtsocket-api.fyers.in', 443))
except socket.gaierror as e:
    print(f"Resolution failed: {e}")