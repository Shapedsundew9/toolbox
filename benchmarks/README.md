# Disk IO
## Bandwidth
From https://www.cyberciti.biz/faq/howto-linux-unix-test-disk-performance-with-dd-command/
Large write
```bash
dd if=/dev/zero of=/tmp/test1.img bs=100M count=1 oflag=dsync
```
From Raspberry Pi 4
```
1+0 records in
1+0 records out
104857600 bytes (105 MB, 100 MiB) copied, 3.5814 s, 29.3 MB/s
```
Lots of small writes
```bash
dd if=/dev/zero of=/tmp/test2.img bs=512 count=1000 oflag=dsync
```
From Raspberry Pi 4
```
1000+0 records in
1000+0 records out
512000 bytes (512 kB, 500 KiB) copied, 6.05633 s, 84.5 kB/s
```


