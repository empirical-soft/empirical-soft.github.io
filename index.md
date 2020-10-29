<center>
<h2>Empirical is a language for time-series analysis</h2>
</center>


### Builtin Dataframes and integrated queries

Empirical is a normal language with variables, types, functions, etc. Dataframes are just values.

```
>>> let trades = load("trades.csv"), quotes = load("quotes.csv"), events = load("events.csv")

>>> trades
 symbol                  timestamp    price size
   AAPL 2019-05-01 09:30:00.578802 210.5200  780
   AAPL 2019-05-01 09:30:00.580485 210.8100  390
    BAC 2019-05-01 09:30:00.629205  30.2500  510
    CVX 2019-05-01 09:30:00.944122 117.8000 5860
   AAPL 2019-05-01 09:30:01.002405 211.1300  320
   AAPL 2019-05-01 09:30:01.066917 211.1186  310
   AAPL 2019-05-01 09:30:01.118968 211.0000  730
    BAC 2019-05-01 09:30:01.186416  30.2450  380
    CVX 2019-05-01 09:30:01.639577 118.2550 2880
    ...                        ...      ...  ...
```

Table syntax is part of of the language.

```
>>> from trades select where symbol == "AAPL" and size > 1000
 symbol                  timestamp    price size
   AAPL 2019-05-01 09:37:45.647850 205.0600 1010
   AAPL 2019-05-01 09:38:24.754932 204.9200 2010
   AAPL 2019-05-01 09:42:57.450065 203.7332 1130
```

### Time-series aggregations

Aggregations allow any expression, including user-defined functions. This computes the weighted average (`wavg`) given a set of weights (`ws`) and values (`vs`):

```
>>> func wavg(ws, vs) = sum(ws * vs) / sum(ws)
```

We can compute the volume-weighted average price (VWAP) and total volume for every five minutes:

```
>>> from trades select vwap = wavg(size, price), volume = sum(size) by symbol, bar(timestamp, 5m)
 symbol           timestamp       vwap volume
   AAPL 2019-05-01 09:30:00 210.305724  70070
    BAC 2019-05-01 09:30:00  30.483875  66510
    CVX 2019-05-01 09:30:00 119.427733 129250
   AAPL 2019-05-01 09:35:00 202.972440  39680
    BAC 2019-05-01 09:35:00  30.848397  88260
    CVX 2019-05-01 09:35:00 119.431601 203600
   AAPL 2019-05-01 09:40:00 204.671388  18370
    BAC 2019-05-01 09:40:00  30.217362  46700
    CVX 2019-05-01 09:40:00 117.224763 147460
    ...                 ...        ...    ...
```

### Time-series joins

Empirical can line-up timestamps automatically. Here is the latest quote for each trade:

```
>>> join trades, quotes on symbol asof timestamp
 symbol                  timestamp    price size    bid    ask
   AAPL 2019-05-01 09:30:00.578802 210.5200  780 210.80 211.15
   AAPL 2019-05-01 09:30:00.580485 210.8100  390 210.80 211.15
    BAC 2019-05-01 09:30:00.629205  30.2500  510  30.24  30.27
    CVX 2019-05-01 09:30:00.944122 117.8000 5860 117.76 118.34
   AAPL 2019-05-01 09:30:01.002405 211.1300  320 210.80 211.15
   AAPL 2019-05-01 09:30:01.066917 211.1186  310 210.80 211.15
   AAPL 2019-05-01 09:30:01.118968 211.0000  730 210.80 211.15
    BAC 2019-05-01 09:30:01.186416  30.2450  380  30.24  30.27
    CVX 2019-05-01 09:30:01.639577 118.2550 2880 118.26 118.37
    ...                        ...      ...  ...    ...    ...
```

Joins can change direction and set boundaries on searches. This is the closest event for each trade within three seconds:

```
>>> join trades, events on symbol asof timestamp nearest within 3s
 symbol                  timestamp    price size code
   AAPL 2019-05-01 09:30:00.578802 210.5200  780     
   AAPL 2019-05-01 09:30:00.580485 210.8100  390     
    BAC 2019-05-01 09:30:00.629205  30.2500  510     
    CVX 2019-05-01 09:30:00.944122 117.8000 5860   a1
   AAPL 2019-05-01 09:30:01.002405 211.1300  320     
   AAPL 2019-05-01 09:30:01.066917 211.1186  310     
   AAPL 2019-05-01 09:30:01.118968 211.0000  730     
    BAC 2019-05-01 09:30:01.186416  30.2450  380   e3
    CVX 2019-05-01 09:30:01.639577 118.2550 2880   a1
    ...                        ...      ...  ...  ...
```

### Static typing

What makes Empirical unique is that it is *statically typed*. The compiler knows before running user code whether it is allowed.

```
>>> sort quotes by (asks - bid) / bid
Error: symbol asks was not found
```

Such error checking is beneficial with long-running scripts. Correcting the above typo, we can sort the quotes by the bid-ask spread.

```
>>> sort quotes by (ask - bid) / bid
 symbol                  timestamp      bid      ask
    BAC 2019-05-01 09:32:46.313487  30.5650  30.5650
    BAC 2019-05-01 09:32:53.738446  30.6124  30.6124
    BAC 2019-05-01 09:39:24.459415  31.0600  31.0600
   AAPL 2019-05-01 09:45:51.931597 206.9400 206.9500
   AAPL 2019-05-01 09:43:59.903292 206.3200 206.3300
    BAC 2019-05-01 09:32:50.369746  30.6400  30.6417
    CVX 2019-05-01 09:32:57.242072 119.7732 119.7800
   AAPL 2019-05-01 09:38:18.980026 205.1100 205.1222
   AAPL 2019-05-01 09:38:19.978890 205.1100 205.1251
    ...                        ...      ...      ...
```

Types can be inferred automatically if the file path is known ahead of time. To run a script with an external parameter (like `argv`), just specify the type in a templated function:

```
data Trade:
  symbol: String,
  timestamp: Timestamp,
  price: Float64,
  size: Int64
end

let trades = csv_load{Trade}(argv[1])
```

----

## FAQ

### How is this different from Julia or q/kdb+?

Empirical is *statically typed*, which prevents many common programming errors.

### Why is this a new language instead of a library in an existing language?

Embedding Dataframes into an existing language would not be possible. Empirical's Dataframes are statically typed and can be inferred from an external source.

----

## Blog

<ul>
  {% for post in site.posts %}
    <li>
      <a href="{{ post.url }}">{{ post.title }}</a>
      {{ post.excerpt }}
    </li>
  {% endfor %}
</ul>
