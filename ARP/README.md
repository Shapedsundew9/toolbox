### Background
As to 'why' can be found in [this Ask Ubuntu question](https://askubuntu.com/questions/1433616/no-ping-between-two-22-04-laptops-but-can-ping-both-ways-from-3rd-windows-devi).

### Details
To make things 'permanent' I:
* Fixed the IP addresses of the laptops be perpetually extending the DHCP lease on the router
* Created a systemd start up service to set the ARP tables as needed - on both laptops

#### Creating the service
```bash
chmod u+x static_arp_mapping.sh
sudo mv static_arp_mapping.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo mv static_arp_mapping.sh /usr/local/bin/
sudo systemctl enable static_arp_mapping.service
sudo journalctl -u static_arp_mapping.service
```
