<center>
<h2>Empirical is a language for time-series analysis</h2>
</center>

### Statically Typed Dataframes

Empirical can infer a Dataframe's type if the source is known at compile time, such as in a REPL.

```
>>> let trades = load("trades.csv"), quotes = load("quotes.csv")
```

New types are easy to define since column-oriented Dataframes can be created on-the-fly.

```
>>> data Event: timestamp: Timestamp, code: String end

>>> let events = !Event([Timestamp("09:33:01"), Timestamp("09:41:58")], ["e1", "e2"])
```

### Integrated Queries and Aggregations

Empirical is a normal programming language, but can perform queries directly on a Dataframe.

```
>>> from quotes select where symbol == "AAPL" and (ask/bid) > 1.001
```

Any expression can be used in an aggregation, including user-defined functions.

```
>>> from trades select vwap = wavg(size, price) by symbol, bar(timestamp, 1m)
```

### Time-Series Joins

Empirical can join Dataframes by the most recent timestamp.

```
>>> join trades, quotes on symbol asof timestamp
```

The closest timestamp within a tolerance is also possible.

```
>>> join trades, events asof timestamp nearest within 3s
```
