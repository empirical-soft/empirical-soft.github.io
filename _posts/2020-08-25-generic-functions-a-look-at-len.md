---
title: "Generic functions: a look at len()"
include_title: true
---

The [previous post](https://www.empirical-soft.com/2020/08/19/inferring-static-types-from-an-external-source.html) discussed how metaprogramming allows Empirical to maintain static typing while inferring a Dataframe's type from an external source. This post will cover generics in more detail.

Here is the source for the Dataframe version of `len()`:

```
func len[T](df: !T) => len(compile("df." + members_of(df)[0]))
```

There are other versions of `len()` as well, provided by the Vector Virtual Machine. We will see how these versions interact to provide a single function interface.

### Overloading

At startup, VVM tells the Empirical compiler what symbols are available. For example, VVM's

```
add_i64s_i64v
```

is visible as

```
(+): (Int64,[Int64])->[Int64]
```

This VVM opcode is available in Empirical as the plus operator; it takes a scalar integer and a vector integer to produce a vector integer.

There are a lot of plus operators in Empirical, such as for floating points, strings, time deltas, etc. Empirical is able to handle the name reuse through *overloading*. Functions are allowed the same name if their type signatures are unique.

The types of the caller's parameters determine which specific function to use. We can see which opcode is selected by looking at the generated assembly code (`--dump-vvm`). Empirical's

```
13 + 17
```

becomes VVM's

```
add_i64s_i64s 13 17 %0
```

And Empirical's

```
13.0 + 17.0
```

becomes VVM's

```
@1 = 13.0
@2 = 17.0

add_f64s_f64s @1 @2 %0
```

Similarly, the `len()` function is overloaded for vectors of every VVM type. There is a `len_i64v` for integers, `len_f64v` for floating point, etc. These work well for standalone vectors, but a Dataframe is harder because it can have any type.

The user can get around this by requesting the length of the first column of a Dataframe. Imagine a `trades` table whose first column is `symbol`:

```
len(trades.symbol)
```

This works, but it's kind of annoying. Fortunately, generic functions offer a solution.

### Generalization and specialization

Imagine a function that adds two integers together:

```
func foo(a: Int64, b: Int64) = a + b
```

This is compiled to:

```
@1 = def foo("a": i64s, "b": i64s) i64s:
  add_i64s_i64s %0 %1 %2
  ret %2
end
```

We can *generalize* this function with a generic of the same name:

```
func foo(a, b) = a * b
```

We use multiplication here to know that something different has happened. Calling this on a pair of floating points generates this instance:

```
@2 = def foo(Float64, Float64)("a": f64s, "b": f64s) f64s:
  mul_f64s_f64s %0 %1 %2
  ret %2
end
```

The generic function has overloaded the type-specific one. The compiler tries to match a function call against the first (type-specific) version; failing that, it moves to the second (generic) version. Both functions now exist.

We can go in the other direction and *specialize* a generic.

```
func foo(a: Timestamp, b: Timestamp) = a - b
```

This version subtracts two timestamps and returns a time delta.

```
@3 = def foo(Timestamp, Timestamp)("a": Ts, "b": Ts) Ds:
  sub_Ts_Ts %0 %1 %2
  ret %2
end
```

All three versions of `foo()` exist at the same time! And calling `foo()` on yet another type will trigger the generic (second) version to generate yet another instance.

By generalizing `len()`, we can create a function that takes any input that isn't already covered by the type-specific versions. Ie., anything that isn't a vector of a builtin type will go through our generic.

### Reflection

We now have to decide what to do in our generic `len()`. Recall that we can simply take the length of our first column. But how do we know what the first column name is?

Empirical has some routines that allow us to get information on values. For example, we can always ask for the type of something:

```
>>> type_of(17)
<type: Int64>

>>> type_of(["Hello", "World"])
<type: [String]>

>>> type_of(Float64)
<type: Kind(Float64)>
```

Similarly, we can request the members of a Dataframe:

```
>>> members_of(trades)
["symbol", "timestamp", "price", "size"]
```

With *reflection*, we can see the name of the first column:

```
>>> "trades." + members_of(trades)[0]
"trades.symbol"
```

Now we use the `compile()` function to access it:

```
>>> compile("trades." + members_of(trades)[0])
["AAPL", "AAPL", "BAC", "CVX", "AAPL", "AAPL", "AAPL", "BAC", "CVX", "BAC", ...]
```

So a potential version of our overloaded function is:

```
func len(df) = len(compile("df." + members_of(df)[0]))
```

This invokes the type-specific version of `len()` on the first column. Calling it is simply:

```
>>> len(trades)
5817
```

### Placeholders

There is one problem with our current generic `len()`: it lacks type safety.

```
>>> len(17)
Error: Index out of bounds
```

Calling on a scalar integer gives a cryptic error message. That's because `17` has no members!

```
>>> members_of(17)
[]
```

Accessing the first element of it results in an out-of-bounds error. While this stops the compilation, the message is nonsensical. What we want is some type information passed to the generic. That's what a *placeholder* is for.

Consider a function that adds two values that must be the same type:

```
func add[T](a: T, b: T) = a + b
```

Generic types are anonymous by default, but here we have named it `T` by giving the function a placeholder. This gives us type safety.

```
>>> add(3, 4)
7

>>> add(3.0, 4.0)
7.0

>>> add(3.0, 4)
Error: argument type at position 1 does not match: Int64 vs T aka Float64
```

The placeholder can take some degree of structure. Here we require a vector in the first parameter and a scalar of the same underlying type in the second parameter:

```
func mult[T](a: [T], b: T) = a * b
```

Only types matching the specific pattern are allowed:

```
>>> mult([1, 2, 3], 4)
[4, 8, 12]

>>> mult([1.0, 2.0, 3.0], 4.0)
[4.0, 8.0, 12.0]
```

Anything else is an error:

```
>>> mult([1, 2, 3], [4, 5, 6])
Error: argument type at position 1 does not match: [Int64] vs T aka Int64

>>> mult(1, 4)
Error: argument type at position 0 does not match: Int64 vs [T]
```

The `store()` function from the [previous blog post](https://www.empirical-soft.com/2020/08/19/inferring-static-types-from-an-external-source.html) has been augmented to require a Dataframe:

```
func store[T](df: !T, filename: String) => _csv_store(!T, df, filename)
```

Anything that isn't a Dataframe will give an error:

```
>>> store(17, "seventeen.csv")
Error: argument type at position 0 does not match: Int64 vs !T
```

### Putting it all together

By combining overloading, generalization, reflection, and placeholders, we can define the Dataframe version of `len()` shown at the top:

```
func len[T](df: !T) => len(compile("df." + members_of(df)[0]))
```

This inlines the function. From a fresh Empirical instance:

```
>>> let trades = load("trades.csv")

>>> len(trades)
5817
```

The function call results in this assembly:

```
member @1 0 %2
len_Sv %2 %3
```

It takes the first `member` of `trades` (global register `@1`), saving the result in temporary/local register `%2`. Then it invokes VVM's `len_Sv` and saves the result in `%3`. This register's value is displayed on the console.

Alternatively, calling the function with a nonsensical value gives a much more satisfying error message:

```
>>> len(17)
Error: unable to match overloaded function len
  candidate: ([Int64]) -> Int64
    argument type at position 0 does not match: Int64 vs [Int64]
  candidate: ([Float64]) -> Int64
    argument type at position 0 does not match: Int64 vs [Float64]
  candidate: ([Bool]) -> Int64
    argument type at position 0 does not match: Int64 vs [Bool]
  ...
  <7 others>
```
