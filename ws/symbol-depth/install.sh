echo $USER
hd="$(dirname "$(realpath "$0")")"
rm /etc/systemd/system/symbol-depth.service
cd /etc/systemd/system
ln -s $hd/symbol-depth.service
d=/opt/binance
mkdir -p $d
cd $d
rm *
ln -s $hd/symbol-depth.py
systemctl daemon-reload
systemctl enable symbol-depth.service
systemctl start symbol-depth.service
systemctl status symbol-depth.service
#journalctl -u symbol-depth -b|tail
