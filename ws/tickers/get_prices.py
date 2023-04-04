import requests

def get_all_prices():
    url = "https://api.binance.com/api/v3/ticker/price"
    response = requests.get(url)

    if response.status_code == 200:
        prices = response.json()
        return prices
    else:
        print(f"Error: {response.status_code}")
        return None

if __name__ == "__main__":
    all_prices = get_all_prices()
    if all_prices:
        for price_info in all_prices:
            print(f"{price_info['symbol']}: {price_info['price']}")
