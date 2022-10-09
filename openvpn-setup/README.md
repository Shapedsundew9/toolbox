### Background
Setting up openvpn to create a secure communication mesh.
Step one is creating a server with a single client.
### Sever Setup
Generally following https://openvpn.net/community-resources/how-to/
- I decidied to go with [easy-rsa 3](https://github.com/OpenVPN/easy-rsa) as it is the latest but at the time the very helpful [readthedocs.io](https://easy-rsa.readthedocs.io/en/latest/) information was not linked - at least not obviously so I raised a [ticket](https://github.com/OpenVPN/easy-rsa/issues/721).
- Default *server.conf* file has `group nobody` but it needs to be `group nogroup`. Useful commands:
- Default *client.conf* file has `group nobody` but it needs to be `group nogroup`. Useful commands:
```bash
compgen -u | sort     # List of users
compgen -g | sort     # List of groups
```

#### Creating a Certificate Authority
- This is a home playground so I ignored the advice to create the CA on an offline secure system.
- I put easy-rsa scripts in /usr/share/easy-rsa
```bash
su -
./easyrsa init-pki
./easyrsa build-ca # Passphrase stored in password vault
./easyrsa gen-dh
```
#### Commands to create key pairs
```bash
cd /usr/share/easy-rsa
su -
./easyrsa build-server-full <server-common-name> nopass
./easyrsa build-client-full <client-common-name> nopass
```
Copy *pki/issued/common-name.crt* and *pki/private/common-name.key* to the approriate location on the client or server.
#### Useful Other Stuff
```
sudo lsof -i -P -n | grep LISTEN     # List all listening ports
```


