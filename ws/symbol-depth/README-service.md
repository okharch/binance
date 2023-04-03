# Symbol Depth Service
This service is used to subscribe to the order book for trading pairs on Binance and update a PostgreSQL database with the latest data.

## Installation
Clone this repository to your local machine:
````
git clone https://github.com/<username>/<repository-name>.git
````
Navigate to the cloned repository:
````
cd <repository-name>
````
Make the install.sh script executable:
````
sudo chmod +x install.sh
````
Run the install.sh script:
````
sudo ./install.sh
````
Check the status of the symbol-depth.service:
````
sudo systemctl status symbol-depth.service
````
## Usage
By default, the service is subscribed to btcusdt and solusdt trading pairs. To add or remove pairs, modify the ExecStart line in the symbol-depth.service file.

To start the service:

````
sudo systemctl start symbol-depth.service
````
To stop the service:

````
sudo systemctl stop symbol-depth.service
````
To check the logs:

````
sudo journalctl -u symbol-depth.service -f
````
