There are many technical indicators available to traders and investors, each with its own set of parameters. However, here are some common parameters for a few popular technical indicators:

Moving averages: Moving averages are used to identify trends in price data. The most common parameters are the length of the moving average and the type of moving average used (simple, exponential, etc.). Common lengths include 20, 50, and 200 days.

Relative Strength Index (RSI): The RSI is used to measure the strength of a security's price action. The most common parameter is the length of the lookback period, which is typically 14 periods.

Moving Average Convergence Divergence (MACD): The MACD is used to identify changes in trend and momentum. The most common parameters are the length of the fast and slow moving averages (usually 12 and 26 periods, respectively) and the length of the signal line (usually 9 periods).

Bollinger Bands: Bollinger Bands are used to identify overbought and oversold conditions in a security's price action. The most common parameters are the length of the moving average (usually 20 periods) and the number of standard deviations used to calculate the upper and lower bands (usually 2).

Stochastic Oscillator: The Stochastic Oscillator is used to measure momentum and overbought/oversold conditions. The most common parameters are the length of the lookback period (usually 14 periods) and the level at which the oscillator is considered overbought or oversold (usually 80 and 20, respectively).

It's important to note that the optimal parameters for a technical indicator may vary depending on the security being analyzed and the time frame being used. Traders and investors often experiment with different parameters to find the settings that work best for their specific trading strategy.




Oleksandr Kharchenko
so I am going to create ticker package which implements ticker object which has channel property returning ticks starting where the data begins plus number of periods required to calculate all Created tech indicators (maximum period of thos). Channel returns current kline. After that we can calculate all necessary indicators based on current position. first lets create ticker.CreateMovingAverageIndicator(periodsCount, period) method which returns function calculatingmoving average over period. when ticker moves it will recalculate the value accordingly. But keep in mind that ticker ticks by 1m while we can request to create moving average over 10 days, etc.
It sounds like you are planning to create a ticker package that implements a ticker object with various technical indicators. Here is an example implementation for the CreateMovingAverageIndicator method you described:

kotlin
Copy code
// Ticker object constructor
function Ticker(data) {
this.data = data;
this.position = 0;
this.indicators = [];
}

// Method for creating moving average indicator
Ticker.prototype.CreateMovingAverageIndicator = function(periodsCount, period) {
var indicator = {
name: 'Moving Average (' + periodsCount + ')',
periodsCount: periodsCount,
period: period,
values: []
};

// Calculate moving average
indicator.calculate = function(position) {
var sum = 0;
var start = Math.max(0, position - this.periodsCount + 1);
for (var i = start; i <= position; i++) {
sum += this.data[i].close;
}
var value = sum / this.periodsCount;
return value;
}

this.indicators.push(indicator);

// Return function to calculate moving average at current position
return function() {
var value = indicator.calculate(this.position);
indicator.values.push(value);
return value;
}.bind(this);
}
This implementation creates a Ticker object with a data property that contains the price data, a position property that tracks the current position of the ticker, and an indicators



