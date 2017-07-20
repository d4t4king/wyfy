# wyfy
Just some scripts I cobbled together for various things related to wifi analysis.

Most of these are wrappers for harnessing and manipulating the data collected and output by the aircrack-ng and kismet\* quite of tools.  So, you'll want to make sure that you have them installed.

### Getting Started
Most "modern" linux distributions should have these tools available in whatever package manager repo they use: apt for Debian/Ubuntu based derivatives, rpm/yum for RedHat/CentOS, etc.

However, most guides you find will recommend installing from source.  I'll try to cover the basics for each style, but if you find that I haven't covered your favorite distro OR you discover a problem, feel free to file an issue.

\*Kismet is somewhat outdated, and I don't think has continuing development.  However, it is still very handy for watching wireless networks in the monitoring area.

### Debian/Ubuntu
#### Install prerequisites:
Depending on your implementation, many or all of these tools will already be installed.
```
apt-get update
apt-get install libssl-dev pkg-config build-essential ethtool rfkill libnl-3-dev libnl-genl-3-dev
# if SSID filtering with regular expressions support is desired
apt-get install libpcre3 libpcre3-dev
# if airolib-ng support is desired
apt-get install sqlite3 libsqlite3-dev
```
To install the "bleeding edge" source you will also need subversion:
``` apt-get install subversion -y ```
Then download and compile the source:
```
svn checkout http://svn.aircrack-ng.org/trunk/ aircrack-ng

