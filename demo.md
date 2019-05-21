---
title: Demo
---

<center>
<p>
<iframe width="560" height="315" src="https://www.youtube.com/embed/hoY5IKQliBY" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</p>
</center>

*Download the sample data ([trades.csv](trades.csv), [quotes.csv](quotes.csv), [events.csv](events.csv)) to follow along. Longer [tutorial](tutorial.html) is also available.*

Start Empirical from a terminal:

```
$ path/to/empirical
Empirical version 0.1.0
Copyright (C) 2019 Empirical Software Solutions, LLC

>>> 
```

Read a CSV file into memory as a Dataframe:

```
>>> let trades = load$("trades.csv")
```

Dataframes are just values, so they can be displayed from the REPL:

```
>>> trades
```

Filter through a query:

```
>>> from trades select where symbol == "AAPL" and size > 1000
```

Perform aggregations directly in a query:

```
>>> from trades select volume = sum(size) by symbol
```

Aggregations can be across multiple columns:

```
>>> from trades select volume = sum(size) by symbol, bar(timestamp, 1m)
```

Aggregations allow any number of arbitrary expressions. First we'll define a function:

```
>>> func wavg(ws: [Float64], vs: [Float64]): return sum(ws*vs)/sum(ws) end
```

Then we'll use that function:

```
>>> from trades select volume = sum(size), vwap = wavg(Float64(size), price) by symbol, bar(timestamp, 1m)
```

Make a new type:

```
>>> data Listing: symbol: String, exch: Char end
```

Instantiate the type:

```
>>> Listing("AAPL", 'Q')
```

Create a Dataframe by preceding a type with an exclamation point.

```
>>> let listings = !Listing(["AAPL", "BAC", "CVX"], ['Q', 'N', 'N'])
```

Join two Dataframes:

```
>>> join trades, listings on symbol
```

Bring in another Dataframe:

```
>>> let quotes = load$("quotes.csv")
```

Timeseries join:

```
>>> join trades, quotes on symbol asof timestamp
```

Yet another Dataframe:

```
>>> let events = load$("events.csv")
```

Join for the closest timestamp, bounded by three seconds:

```
>>> join trades, events on symbol asof timestamp nearest within 3s
```

*See the [tutorial](tutorial.html) for more examples.*
