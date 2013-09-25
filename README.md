# Network Scanner

A network scanner application written in Ruby. It allows you to scan a list of
ips. This can be passed as a range, a file to read ip's from (newline
separated or a json array), or you can specify an interface and it will scan
all ip's on your subnet.

With the IP's, you can scan for machines that are up (With a simple ping
test). You can also scan all of them for a given port, or check the hostnames
of all the machines that are up.

All of the scans can be output as JSON or text (newline separated), and you
can pass an argument to have it write directly to a file.

## Installation

    $ gem install network_scanner

## Usage

```
# Output help text
network_scanner -h

# Scans your subnet for machines that respond to pings with a pool size of 300
network_scanner --interface wlan0 --poolsize 300 --ping
network_scanner -i wlan0 -s 300 -P

# Checks the hostname on a range of ip's, outputting json to a file
network_scanner --range 129.22.0.0-129.22.255.255 --nslookup --format json --output out.json
network_scanner -r 129.22.0.0-129.22.255.255 -n -f json -o out.json

# Scans a given list of ips for port 80
network_scanner --cache ips.txt --portscan 80
network_scanner -c ips.txt -p 80

# Scans a list of ips in json format for their hostname and outputs to file in json
network_scanner --cache ips.json --format json --nslookup --output out.json
network_scanner -c ips.json -f json -n -o out.json
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
